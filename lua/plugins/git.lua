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
        lazy = true;
    },
    {
        'tpope/vim-fugitive',
        lazy = false;
    }
}
