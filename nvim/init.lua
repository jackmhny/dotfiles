require("jvim")

vim.opt.title = true
vim.opt.titlestring = "%{expand('%:p:~')} - nvim"


-- set tab to 2 spaces in lua files
vim.api.nvim_create_autocmd("FileType", {
  pattern = "lua",
  callback = function()
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.expandtab = true
  end,
})

