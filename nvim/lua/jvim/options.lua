-- Enable line numbers
vim.opt.number = true

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
