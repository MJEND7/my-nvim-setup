vim.opt.guicursor = "a:hor20"

vim.opt.nu = true
vim.opt.relativenumber = true

vim.opt.tabstop = 8
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

vim.opt.smartindent = true

vim.opt.wrap = false

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.writebackup = false  -- prevents .cs~ files that confuse dotnet watch
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true

vim.opt.hlsearch = false
vim.opt.incsearch = true

vim.opt.termguicolors = true

vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"
vim.opt.isfname:append("@-@")

vim.opt.updatetime = 50

-- vim.opt.colorcolumn = "150"

-- Ensure treesitter highlighting is enabled
vim.api.nvim_create_autocmd("FileType", {
  callback = function()
    pcall(vim.treesitter.start)
  end,
})

-- dart format / flutter format use 2-space indentation; without this,
-- indent guides (ibl) are drawn at the wrong columns since they follow shiftwidth
vim.api.nvim_create_autocmd("FileType", {
  pattern = "dart",
  callback = function()
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
  end,
})
