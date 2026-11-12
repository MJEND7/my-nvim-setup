return {
    {
        'lewis6991/gitsigns.nvim',
        name = 'gitsigns',
        config = function()
            require('gitsigns').setup()
        end
    },
    {
        'f-person/git-blame.nvim',
        event = 'VeryLazy',
        config = function()
            require('gitblame').setup({
                enabled = false,
            })
        end,
    },
    {
        'tpope/vim-fugitive',
        lazy = false;
    },
    {
        'pwntester/octo.nvim',
        cmd = 'Octo',
        dependencies = {
            'nvim-lua/plenary.nvim',
            'nvim-telescope/telescope.nvim',
            'nvim-tree/nvim-web-devicons',
        },
        config = function()
            require('octo').setup()
        end,
    },
    {
        'folke/snacks.nvim',
        priority = 1000,
        lazy = false,
        ---@type snacks.Config
        opts = {
            gh = {},
            picker = {
                sources = {
                    gh_issue = {},
                    gh_pr = {},
                    -- see lua/config/gh_diff.lua: paginated fallback for huge PRs,
                    -- GitHub "viewed" markers (<c-x>) and side-by-side diff tabs (<c-e>)
                    gh_diff = require('config.gh_diff').source(),
                },
            },
        },
        keys = {
            { '<leader>gi', function() Snacks.picker.gh_issue() end,                 desc = 'GitHub Issues (open)' },
            { '<leader>gI', function() Snacks.picker.gh_issue({ state = 'all' }) end, desc = 'GitHub Issues (all)' },
            { '<leader>gp', function() Snacks.picker.gh_pr() end,                    desc = 'GitHub Pull Requests (open)' },
            { '<leader>gP', function() Snacks.picker.gh_pr({ state = 'all' }) end,    desc = 'GitHub Pull Requests (all)' },
        },
    },
    {
        'ThePrimeagen/git-worktree.nvim',
        dependencies = {
            'nvim-lua/plenary.nvim',
            'nvim-telescope/telescope.nvim',
        },
        config = function()
            require('git-worktree').setup()
            require('telescope').load_extension('git_worktree')

            vim.keymap.set('n', '<leader>gw', function()
                require('telescope').extensions.git_worktree.git_worktrees()
            end, { desc = 'Switch git worktree' })

            vim.keymap.set('n', '<leader>gW', function()
                require('telescope').extensions.git_worktree.create_git_worktree()
            end, { desc = 'Create git worktree' })
        end,
    },
}
