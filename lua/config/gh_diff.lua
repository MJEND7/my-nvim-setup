-- Extensions for the snacks.nvim `gh_diff` picker.
--
-- 1. Fallback: `gh pr diff` fails with HTTP 406 when a PR touches more than
--    300 files. The finder tries `gh pr diff` first and, if it fails, offers to
--    fetch the changed files through the paginated REST API instead and
--    rebuild a unified diff from each file's `patch`.
-- 2. Viewed state: each file shows GitHub's "viewed" checkbox state, and a key
--    toggles it (same as ticking "Viewed" in the PR files tab).
-- 3. Side-by-side: a key opens the file in a new tab as a vimdiff split of the
--    PR head against the merge-base, using fugitive.

local M = {}

M.icons = {
    viewed = "󰄬 ",
    unviewed = "  ",
}

---@class config.gh_diff.File
---@field filename string
---@field previous_filename? string
---@field status "added"|"removed"|"modified"|"renamed"|"copied"|"changed"|"unchanged"
---@field patch? string

--- Build a unified diff from the files returned by `GET /repos/{repo}/pulls/{n}/files`.
---@param files config.gh_diff.File[]
---@return string
function M.build_diff(files)
    local out = {} ---@type string[]
    for _, f in ipairs(files) do
        local from = f.previous_filename or f.filename
        local to = f.filename
        out[#out + 1] = ("diff --git a/%s b/%s"):format(from, to)
        if f.status == "added" then
            out[#out + 1] = "new file mode 100644"
            from = nil
        elseif f.status == "removed" then
            out[#out + 1] = "deleted file mode 100644"
            to = nil
        elseif f.status == "renamed" then
            out[#out + 1] = "rename from " .. from
            out[#out + 1] = "rename to " .. to
        end
        if f.patch and f.patch ~= "" then
            out[#out + 1] = "--- " .. (from and ("a/" .. from) or "/dev/null")
            out[#out + 1] = "+++ " .. (to and ("b/" .. to) or "/dev/null")
            out[#out + 1] = f.patch
        end
    end
    return table.concat(out, "\n")
end

--- Fetch all pages of the PR files endpoint.
---@async
---@param repo string owner/name
---@param pr number
---@return config.gh_diff.File[]?
local function fetch_files(repo, pr)
    local Api = require("snacks.gh.api")
    local pages = Api.request_sync({
        endpoint = ("repos/%s/pulls/%d/files"):format(repo, pr),
        method = "GET", -- `--field` would otherwise switch gh api to POST
        paginate = true,
        slurp = true,
        params = { per_page = 100 },
    })
    if type(pages) ~= "table" then
        return
    end
    local files = {} ---@type config.gh_diff.File[]
    for _, page in ipairs(pages) do
        vim.list_extend(files, page)
    end
    return files
end

local VIEWED_QUERY = [[
query($owner:String!, $name:String!, $number:Int!, $after:String) {
  repository(owner:$owner, name:$name) {
    pullRequest(number:$number) {
      id
      files(first:100, after:$after) {
        pageInfo { hasNextPage endCursor }
        nodes { path viewerViewedState }
      }
    }
  }
}]]

--- Fetch the "viewed" state of every file in the PR.
---@async
---@param repo string owner/name
---@param pr number
---@return table<string, boolean> viewed path -> viewed?
---@return string? pr_id GraphQL node id of the PR (needed for mutations)
function M.fetch_viewed(repo, pr)
    local Api = require("snacks.gh.api")
    local owner, name = repo:match("^([^/]+)/(.+)$")
    local viewed, pr_id = {}, nil ---@type table<string, boolean>, string?
    local after ---@type string?
    for _ = 1, 100 do -- hard cap: 10k files
        local data = Api.graphql_sync({
            query = VIEWED_QUERY,
            fields = { owner = owner, name = name, after = after },
            params = { number = pr },
        })
        local prd = data and data.repository and data.repository.pullRequest
        if not prd then
            break
        end
        pr_id = prd.id
        local files = prd.files or {}
        for _, f in ipairs(files.nodes or files) do
            viewed[f.path] = f.viewerViewedState == "VIEWED"
        end
        local info = files.pageInfo
        if not (info and info.hasNextPage) then
            break
        end
        after = info.endCursor
    end
    return viewed, pr_id
end

--- Resolve "owner/name" for the current directory when no repo was given.
---@async
---@return string?
local function current_repo()
    local Api = require("snacks.gh.api")
    local data = Api.fetch_sync({ args = { "repo", "view" }, fields = { "nameWithOwner" } })
    return type(data) == "table" and data.nameWithOwner or nil
end

---@param opts snacks.picker.gh.diff.Config
---@type snacks.picker.finder
function M.finder(opts, ctx)
    opts = opts or {}
    if not opts.pr then
        Snacks.notify.error("gh_diff: `opts.pr` is required")
        return {}
    end

    local Api = require("snacks.gh.api")
    local Render = require("snacks.gh.render")
    local Diff = require("snacks.picker.source.diff")

    opts.previewers.diff.style = "fancy"

    ---@async
    return function(cb)
        local item = Api.get({ type = "pr", repo = opts.repo, number = opts.pr })
        local repo = opts.repo or item.repo or current_repo()
        local annotations = ctx.async:schedule(function()
            return Render.annotations(item)
        end)

        -- 1. Try the normal `gh pr diff` route.
        local err ---@type string?
        local diff = Api.cmd_sync({
            args = { "pr", "diff", tostring(opts.pr) },
            repo = opts.repo,
            notify = false,
            on_error = function(_, e)
                err = e
            end,
        })
        -- flush the scheduled on_error callback so `err` is populated
        ctx.async:schedule(function() end)

        -- 2. On failure, offer the paginated fallback.
        if not diff then
            local choice = ctx.async:schedule(function()
                local msg = ("`gh pr diff %d` failed:\n%s\nFetch the diff through the paginated files API instead?")
                    :format(opts.pr, vim.trim(err or "unknown error"))
                return vim.fn.confirm(msg, "&Yes\n&No", 1, "Question")
            end)
            if choice ~= 1 then
                return
            end
            if not repo then
                Snacks.notify.error("gh_diff: could not determine repository")
                return
            end
            local files = fetch_files(repo, opts.pr)
            if not files then
                Snacks.notify.error("gh_diff: failed to fetch PR files")
                return
            end
            diff = M.build_diff(files)
            local missing = vim.tbl_filter(function(f) return not f.patch end, files)
            if #missing > 0 then
                Snacks.notify.warn(("gh_diff: %d of %d files have no patch (binary or too large)")
                    :format(#missing, #files))
            end
        end

        -- 3. Viewed state (non-fatal if it fails).
        local viewed, pr_id = {}, nil ---@type table<string, boolean>, string?
        if repo then
            viewed, pr_id = M.fetch_viewed(repo, opts.pr)
        end

        -- 4. Feed the diff text to the generic diff picker.
        Diff.diff(ctx:opts({ diff = diff, annotations = annotations }), ctx)(function(it)
            it.gh_item = item
            it.viewed = viewed[it.file] or false
            it.pr_id = pr_id
            cb(it)
        end)
    end
end

--- `git_status` format with a leading viewed marker.
---@param item snacks.picker.Item
---@param picker snacks.Picker
function M.format(item, picker)
    local ret = require("snacks.picker.format").git_status(item, picker)
    table.insert(ret, 1, {
        item.viewed and M.icons.viewed or M.icons.unviewed,
        item.viewed and "SnacksPickerGitStatusAdded" or "SnacksPickerDimmed",
    })
    return ret
end

--- Toggle GitHub's "viewed" state for the file under the cursor.
---@param picker snacks.Picker
---@param item snacks.picker.Item
function M.toggle_viewed(picker, item)
    if not item or not item.pr_id or not item.file then
        return Snacks.notify.warn("gh_diff: no PR id for this item; cannot toggle viewed state")
    end
    local Api = require("snacks.gh.api")
    local mutation = item.viewed and "unmarkFileAsViewed" or "markFileAsViewed"
    local path, new_state = item.file, not item.viewed
    Api.graphql(function()
        vim.schedule(function()
            if picker.closed then
                return
            end
            for _, it in ipairs(picker:items()) do
                if it.file == path then
                    it.viewed = new_state
                end
            end
            picker.list:update({ force = true })
        end)
    end, {
        query = ("mutation($id:ID!, $path:String!) { %s(input:{pullRequestId:$id, path:$path}) { clientMutationId } }")
            :format(mutation),
        fields = { id = item.pr_id, path = path },
    })
    -- optimistic update + move on, like ticking the box on GitHub
    item.viewed = new_state
    picker.list:update({ force = true })
    picker.list:move(1)
end

---@param root string
---@param args string[]
local function git(root, args)
    return vim.system(vim.list_extend({ "git", "-C", root }, args), { text = true }):wait()
end

--- Open the file in a new tab as a side-by-side diff (merge-base vs PR head).
---@param picker snacks.Picker
---@param item snacks.picker.Item
function M.diff_tab(picker, item)
    local gh = item and item.gh_item ---@type snacks.picker.gh.Item?
    local block = item and item.block ---@type snacks.picker.diff.Block?
    if not gh or not block then
        return
    end
    if vim.fn.exists(":Gvdiffsplit") ~= 2 then
        return Snacks.notify.error("gh_diff: vim-fugitive is required for side-by-side diffs")
    end
    local root = item.cwd or picker:cwd()
    local head = gh.headRefOid
    local base = "origin/" .. gh.baseRefName
    if not head or not gh.baseRefName then
        return Snacks.notify.error("gh_diff: PR has no head/base ref information")
    end

    -- make sure both sides exist locally
    if git(root, { "cat-file", "-e", head .. "^{commit}" }).code ~= 0 then
        git(root, { "fetch", "origin", ("pull/%d/head"):format(gh.number) })
    end
    if git(root, { "rev-parse", "--verify", "-q", base }).code ~= 0 then
        git(root, { "fetch", "origin", gh.baseRefName })
    end
    local mb = git(root, { "merge-base", head, base })
    local merge_base = vim.trim(mb.stdout or "")
    if mb.code ~= 0 or merge_base == "" then
        return Snacks.notify.error("gh_diff: could not find merge-base of " .. head:sub(1, 8) .. " and " .. base)
    end

    local left = block.left and (merge_base .. ":" .. block.left) or nil
    local right = block.right and (head .. ":" .. block.right) or nil
    local line = item.pos and item.pos[1] or 1

    picker:close()
    vim.cmd("tabnew")
    vim.cmd("tcd " .. vim.fn.fnameescape(root))
    if right then
        vim.cmd("Gedit " .. vim.fn.fnameescape(right))
        if left then
            vim.cmd("Gvdiffsplit! " .. vim.fn.fnameescape(left))
        end
        -- fugitive loads the buffers lazily, so the diff for the new window
        -- is stale until it is recomputed; do it now and again after the
        -- picker has finished closing, then land on the hunk.
        local win = vim.api.nvim_get_current_win()
        local function settle()
            if not vim.api.nvim_win_is_valid(win) then
                return
            end
            vim.api.nvim_win_call(win, function()
                vim.cmd("diffupdate")
                pcall(vim.api.nvim_win_set_cursor, win, { line, 0 })
                vim.cmd("normal! zvzz")
                if left then
                    vim.cmd("syncbind")
                end
            end)
        end
        settle()
        vim.schedule(settle)
    elseif left then
        vim.cmd("Gedit " .. vim.fn.fnameescape(left))
        Snacks.notify.info("gh_diff: file was deleted in this PR; showing the base version")
    end
end

--- Source config for `Snacks.picker.gh_diff`.
---@return snacks.picker.Config
function M.source()
    -- Ctrl keys work everywhere; the Alt variants need the terminal to send
    -- Option as Alt (Ghostty: `macos-option-as-alt = true`).
    local keys = {
        ["<c-x>"] = { "gh_toggle_viewed", mode = { "n", "i" }, desc = "Toggle viewed" },
        ["<c-e>"] = { "gh_diff_tab", mode = { "n", "i" }, desc = "Side-by-side diff in new tab" },
        ["<a-v>"] = { "gh_toggle_viewed", mode = { "n", "i" }, desc = "Toggle viewed" },
        ["<a-s>"] = { "gh_diff_tab", mode = { "n", "i" }, desc = "Side-by-side diff in new tab" },
    }
    return {
        finder = M.finder,
        format = M.format,
        actions = {
            gh_toggle_viewed = M.toggle_viewed,
            gh_diff_tab = M.diff_tab,
        },
        win = {
            input = { keys = keys },
            list = { keys = keys },
        },
    }
end

return M
