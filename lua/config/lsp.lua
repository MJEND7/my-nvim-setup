require('mason').setup({
  ui = {
    border = "rounded",
  },
})
require('mason-lspconfig').setup({
  automatic_enable = true,
})

vim.lsp.config("roslyn", {})

-- Configure borders for all floating windows
local border = "rounded"

-- Global LSP floating window config (Neovim 0.11+)
local orig_util_open_floating_preview = vim.lsp.util.open_floating_preview
function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
  opts = opts or {}
  opts.border = opts.border or border
  return orig_util_open_floating_preview(contents, syntax, opts, ...)
end

-- Diagnostic popup borders
vim.diagnostic.config({
  float = {
    border = border,
  },
})

-- Completion menu (nvim-cmp) highlight groups
vim.api.nvim_set_hl(0, "CmpItemMenu", { link = "Comment" })

-- Disable LSP semantic tokens (they wash out treesitter colors)
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client then
      client.server_capabilities.semanticTokensProvider = nil
    end
  end,
})
