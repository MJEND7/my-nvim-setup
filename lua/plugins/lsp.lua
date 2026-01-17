return {
    {
        'nvim-treesitter/nvim-treesitter',
        build = ':TSUpdate',
        config = function()
            require('nvim-treesitter.install').compilers = { "clang" }
            require('nvim-treesitter').setup({
                ensure_installed = {
                    "go", "gomod",
                    "python", "rust",
                    "c_sharp", "lua", "vim", "vimdoc", "query", "markdown", "markdown_inline"
                },
                sync_install = false,
                highlight = { enable = true },
                indent = { enable = false },
                -- Enable vim-matchup plugin integration with treesitter
                matchup = {
                    enable = true,
                    include_match_words = true,
                },
            })
        end,
    },
    {
        "williamboman/mason.nvim",
        opts = {
            registries = {
                "github:mason-org/mason-registry",
                "github:Crashdummyy/mason-registry",
            },
            ensure_installed = {
                "lua-language-server",

                "xmlformatter",
                "netcoredbg", -- For debugger UI
                "csharpier",
                "prettier",

                "stylua",
                "bicep-lsp",
                "html-lsp",
                "css-lsp",
                "eslint-lsp",
                "typescript-language-server",
                "json-lsp",
                "rust-analyzer",
                "angular",
                "gopls",


                -- !
                "roslyn",
                -- "csharp-language-server",
                -- "omnisharp",
            },
        },
    },
    {
        "seblyng/roslyn.nvim",
        ---@module 'roslyn.config'
        ---@type RoslynNvimConfig
        ft = { "cs", "razor" },
        opts = {
            -- your configuration comes here; leave empty for default settings
        },
    },
    {
        "williamboman/mason-lspconfig.nvim",
        dependencies = {
            -- LSP Support
            { "neovim/nvim-lspconfig" },

            -- Autocompletion
            { "hrsh7th/nvim-cmp" },
            { "hrsh7th/cmp-buffer" },
            { "hrsh7th/cmp-path" },
            { "saadparwaiz1/cmp_luasnip" },
            { "hrsh7th/cmp-nvim-lsp" },
            { "hrsh7th/cmp-nvim-lua" },

            -- Snippets
            { "L3MON4D3/LuaSnip" },
            { "rafamadriz/friendly-snippets" },
        },
    },
}
