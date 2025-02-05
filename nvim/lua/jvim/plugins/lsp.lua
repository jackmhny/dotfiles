local M = { "neovim/nvim-lspconfig", }

M.dependencies = {
  { "williamboman/mason.nvim", config = true, }, 
  "williamboman/mason-lspconfig.nvim",          
  { "folke/lazydev.nvim",                       
    ft = "lua",
    opts = {},
  },
}

M.config = function () end

return M
