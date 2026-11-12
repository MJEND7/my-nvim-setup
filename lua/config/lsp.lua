require('mason').setup({
    ui = {
        border = "rounded",
    },
})
require('mason-lspconfig').setup({
    automatic_enable = true,
})

vim.lsp.config("roslyn", {})

-- Configure Dart LSP. Prefer the SDK selected by FVM for each project instead
-- of relying on a machine-wide Dart executable.
vim.lsp.config("dartls", {
    cmd = function(dispatchers, config)
        local project_dart = config.root_dir
            and vim.fs.joinpath(config.root_dir, ".fvm", "flutter_sdk", "bin", "dart")
        local dart = project_dart and vim.fn.executable(project_dart) == 1
            and project_dart
            or vim.fn.exepath("dart")

        if dart == "" then
            error("dartls: no Dart SDK found (checked the project's FVM SDK and PATH)")
        end

        return vim.lsp.rpc.start(
            { dart, "language-server", "--protocol=lsp" },
            dispatchers,
            { cwd = config.root_dir }
        )
    end,
    filetypes = { "dart" },
    root_markers = { "pubspec.yaml" },
})

-- Auto-start dartls for Dart files
vim.api.nvim_create_autocmd("FileType", {
    pattern = "dart",
    callback = function()
        vim.lsp.enable("dartls")
    end,
})

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
