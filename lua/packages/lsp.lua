require('mason').setup({})
require('mason-lspconfig').setup({
  automatic_enable = true,
  ensure_installed = {'ts_ls', 'rust_analyzer'},
})
