
-- Tab settings
vim.opt.tabstop = 4        -- Number of spaces a tab counts for
vim.opt.shiftwidth = 4     -- Number of spaces for auto-indent
vim.opt.expandtab = true   -- Convert tabs to spaces
vim.opt.softtabstop = 4    -- Number of spaces a tab counts for during editing

-- Show invisible characters
vim.opt.list = true
vim.opt.listchars = {
    tab = '→ ',
    lead = '·',
    trail = '·',
    extends = '▸',
    precedes = '◂',
    nbsp = '␣',
}

vim.opt.relativenumber = true
vim.opt.number = true
vim.opt.cursorline = true

local group = vim.api.nvim_create_augroup('JvimHighlights', { clear = true })
vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "*",
  group = group,
  callback = function()
    vim.api.nvim_set_hl(0, "CursorLineNr", { fg = "#ff7777" })
  end,
})
