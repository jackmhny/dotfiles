vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = { "*waybar/config" },  -- More general pattern
  command = "set ft=jsonc",        -- Using command instead of callback
})
