return {
  "folke/tokyonight.nvim",
  lazy = false,
  priority = 1000,
  opts = {
    style = "moon",
    transparent = true,
    terminal_colors = true,
    styles = {
      sidebars = "transparent",
      floats = "transparent",
    },
    on_highlights = function(hl, c)
      -- Make line numbers brighter
      hl.LineNr = {
        fg = c.blue2 -- or another color like c.blue1, c.purple, etc.
      }
      -- Make list characters brighter
      hl.Whitespace = {
        fg = c.blue -- or another color of your choice
      }
    end,
  },
  config = function(_, opts)
    require("tokyonight").setup(opts)
    vim.cmd[[colorscheme tokyonight]]
  end,
}
