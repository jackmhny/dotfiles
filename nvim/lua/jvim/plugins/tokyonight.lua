return {
  "folke/tokyonight.nvim",
  lazy = false,
  priority = 1000,
  config = function()
    require("tokyonight").setup({
      style = "moon",
      terminal_colors = true,
    })
    vim.cmd[[colorscheme tokyonight]]
  end,
}
