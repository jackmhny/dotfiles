return {
  "stevearc/aerial.nvim",
  config = function()
    require('aerial').setup({
      -- Priority list of preferred backends for aerial
      backends = { "treesitter", "lsp", "markdown", "man" },
      
      layout = {
        -- These control the width of the aerial window
        max_width = 40,
        min_width = 10,
        
        -- Key to toggle aerial
        default_direction = "right",
      },
      
      -- Keymaps in aerial window
      keymaps = {
        ["<CR>"] = "actions.jump",
        ["<C-v>"] = "actions.jump_vsplit",
        ["<C-s>"] = "actions.jump_split",
      },
    })

    vim.keymap.set("n", "<leader>e", "<cmd>AerialToggle<CR>")
  end,
}
