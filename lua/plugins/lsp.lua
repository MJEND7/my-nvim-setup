return {
 {
    "mason-org/mason.nvim",
     lazy = false,
 },
    {
    'nvim-treesitter/nvim-treesitter', 
    lazy = false,
    build = ':TSUpdate',
   },
   {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' }
   }
}
