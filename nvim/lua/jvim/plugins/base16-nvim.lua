return {
  "RRethy/nvim-base16",
  lazy = false,
  priority = 1000,
  config = function()
    -- Enable terminal colorsync
    vim.g.base16colorspace = 256  -- Important for 256-color terminals

    -- Try to auto-detect the shell theme, fallback to a default
    local current_shell_theme = os.getenv("BASE16_THEME")
    if current_shell_theme then
      -- Convert shell theme name to Neovim format (e.g., "tomorrow-night" → "base16-tomorrow-night")
      local nvim_theme = "base16-" .. current_shell_theme:gsub("^base16_", "")
      local ok, _ = pcall(vim.cmd.colorscheme, nvim_theme)
      if not ok then
        vim.notify("Theme " .. nvim_theme .. " not found. Falling back to default.")
        vim.cmd.colorscheme("base16-default-dark")
      end
    else
      -- Fallback if shell theme isn't set
      vim.cmd.colorscheme("base16-default-dark")
    end

    -- Force transparency (optional)
    vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
    vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
  end
}
