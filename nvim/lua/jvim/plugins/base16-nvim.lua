return {
  "RRethy/nvim-base16",
  lazy = false,
  priority = 1000,
  config = function()
    vim.g.base16colorspace = 256
    vim.cmd.colorscheme("base16-default-dark")
  end
}
