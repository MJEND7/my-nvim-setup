-- Send a visual selection + a typed prompt to a running Claude Code
-- instance in a Ghostty window, via macOS Accessibility (System Events).
--
-- One-time setup required: grant Accessibility permission to whatever
-- process actually runs `osascript` (usually Ghostty itself, since nvim
-- runs inside it) in System Settings > Privacy & Security > Accessibility.
-- Without it, System Events keystroke/AXRaise calls silently fail with
-- "not allowed assistive access".

local M = {}

local function get_visual_selection()
  local s = vim.fn.getpos("'<")
  local e = vim.fn.getpos("'>")
  local lines = vim.fn.getline(s[2], e[2])
  if #lines == 0 then
    return ""
  end

  local mode = vim.fn.visualmode()
  if mode == "v" then
    lines[#lines] = string.sub(lines[#lines], 1, e[3])
    lines[1] = string.sub(lines[1], s[3])
  end
  -- linewise (V) needs no trimming; blockwise (CTRL-V) is treated linewise here

  return table.concat(lines, "\n")
end

local function open_prompt(callback)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].filetype = "markdown"
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"

  local width = math.floor(vim.o.columns * 0.6)
  local height = 10
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = " Prompt for Claude (<C-s> send, q/<Esc> cancel) ",
    title_pos = "center",
  })
  vim.wo[win].wrap = true
  vim.cmd.startinsert()

  local done = false
  local function finish(submit)
    if done then
      return
    end
    done = true
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    if submit then
      callback(table.concat(lines, "\n"))
    end
  end

  local opts = { buffer = buf, nowait = true, silent = true }
  vim.keymap.set({ "n", "i" }, "<C-s>", function()
    finish(true)
  end, opts)
  vim.keymap.set("n", "<CR>", function()
    finish(true)
  end, opts)
  vim.keymap.set("n", "q", function()
    finish(false)
  end, opts)
  vim.keymap.set("n", "<Esc>", function()
    finish(false)
  end, opts)
end

-- percent-encode a string for use in a URL query parameter (RFC 3986 unreserved
-- chars are left alone; everything else, including newlines, is escaped)
local function url_encode(str)
  return (str:gsub("[^%w%-%.%_%~]", function(c)
    if c == "\n" then
      return "%0A"
    end
    return string.format("%%%02X", string.byte(c))
  end))
end

-- walk up from the current file (or cwd) to find a git repo root; falls back
-- to cwd so the deep link always has a folder to open
local function get_project_root()
  local file_dir = vim.fn.expand("%:p:h")
  local dir = file_dir ~= "" and file_dir or vim.fn.getcwd()
  local root = vim.fn.systemlist({ "git", "-C", dir, "rev-parse", "--show-toplevel" })[1]
  if vim.v.shell_error == 0 and root and root ~= "" then
    return root
  end
  return vim.fn.getcwd()
end

local function open_new_code_chat(message)
  local folder = get_project_root()
  local url = "claude://code/new?folder=" .. url_encode(folder) .. "&q=" .. url_encode(message)

  if #message > 5000 then
    vim.notify("claude_send: prompt is " .. #message .. " chars, may be truncated by the q param limit", vim.log.levels.WARN)
  end

  local result = vim.fn.system({ "open", url })
  if vim.v.shell_error ~= 0 then
    vim.notify("claude_send: failed to open deep link: " .. vim.trim(result), vim.log.levels.ERROR)
  end
end

local function run_osascript(script)
  local tmpfile = vim.fn.tempname() .. ".applescript"
  vim.fn.writefile(vim.split(script, "\n"), tmpfile)
  local result = vim.fn.system({ "osascript", tmpfile })
  vim.fn.delete(tmpfile)
  if vim.v.shell_error ~= 0 then
    return nil, vim.trim(result)
  end
  return vim.trim(result), nil
end

local function get_ghostty_windows()
  local script = [[
tell application "System Events"
  tell process "Ghostty"
    set winNames to name of every window
  end tell
end tell
set AppleScript's text item delimiters to linefeed
return winNames as text
]]
  local out, err = run_osascript(script)
  if err then
    vim.notify("claude_send: failed to list Ghostty windows: " .. err, vim.log.levels.ERROR)
    return {}
  end
  if out == "" then
    return {}
  end
  return vim.split(out, "\n", { trimempty = true })
end

local function send_to_ghostty_window(index, message)
  vim.fn.system({ "pbcopy" }, message)
  if vim.v.shell_error ~= 0 then
    vim.notify("claude_send: pbcopy failed", vim.log.levels.ERROR)
    return
  end

  local script = string.format(
    [[
tell application "Ghostty" to activate
tell application "System Events"
  tell process "Ghostty"
    perform action "AXRaise" of window %d
  end tell
end tell
delay 0.15
tell application "System Events"
  keystroke "v" using command down
  delay 0.1
  key code 36
end tell
]],
    index
  )
  local _, err = run_osascript(script)
  if err then
    vim.notify(
      "claude_send: failed to send to Ghostty window (check Accessibility permissions): " .. err,
      vim.log.levels.ERROR
    )
  end
end

local function pick_window_and_send(prompt, code, filetype, filepath)
  local windows = get_ghostty_windows()

  local message = prompt
  if code ~= "" then
    message = message .. "\n\n"
    if filepath ~= "" then
      message = message .. "File: " .. filepath .. "\n"
    end
    message = message .. "```" .. (filetype or "") .. "\n" .. code .. "\n```"
  end

  local items = { "+ New Claude Code chat (opens in project folder)" }
  for i, name in ipairs(windows) do
    items[#items + 1] = string.format("%d: %s", i, name)
  end

  vim.ui.select(items, { prompt = "Send to:" }, function(_, idx)
    if not idx then
      return
    end

    if idx == 1 then
      open_new_code_chat(message)
      return
    end

    send_to_ghostty_window(idx - 1, message)
  end)
end

function M.send_selection()
  local code = get_visual_selection()
  local filetype = vim.bo.filetype
  local filepath = vim.fn.expand("%")

  open_prompt(function(prompt)
    if prompt == "" and code == "" then
      return
    end
    pick_window_and_send(prompt, code, filetype, filepath)
  end)
end

return M
