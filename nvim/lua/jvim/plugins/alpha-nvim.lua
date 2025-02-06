return {
    'goolord/alpha-nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    event = "VimEnter",
    config = function()
        local alpha = require("alpha")
        local dashboard = require("alpha.themes.dashboard")

-- Header
local header = {
    [[       ░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░▒▓██████████████▓▒░  ]],
    [[       ░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░ ]],
    [[       ░▒▓█▓▒░░▒▓█▓▒▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░ ]],
    [[       ░▒▓█▓▒░░▒▓█▓▒▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░ ]],
    [[░▒▓█▓▒░░▒▓█▓▒░ ░▒▓█▓▓█▓▒░ ░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░ ]],
    [[░▒▓█▓▒░░▒▓█▓▒░ ░▒▓█▓▓█▓▒░ ░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░ ]],
    [[ ░▒▓██████▓▒░   ░▒▓██▓▒░  ░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░ ]],
}
dashboard.section.header.val = header

-- Menu Buttons
local buttons = {
    dashboard.button("SPC f n", "  New File", ":ene <BAR> startinsert <CR>"),
    dashboard.button("SPC f f", "  Find File", ":Telescope find_files<CR>"),
    dashboard.button("SPC f r", "  Recent Files", ":Telescope oldfiles<CR>"),
    dashboard.button("SPC f g", "  Find Text", ":Telescope live_grep<CR>"),
    dashboard.button("SPC f l", "󰐙 Restore Last Session", ":lua require('persistence').load({ last = true })<cr>"),
    dashboard.button("SPC f o", "󰏖  Open Oil", ":Oil<CR>"),
    dashboard.button("SPC c c", "  Configuration", ":e $HOME/.config/nvim<CR>"),
    dashboard.button("SPC c l", "  Lazy", ":Lazy<CR>"),
    dashboard.button("q", "  Quit", ":qa<CR>"),
}
dashboard.section.buttons.val = buttons

-- Footer
local function footer()
    local plugins = #vim.tbl_keys(require("lazy").plugins())
    local v = vim.version()
    return string.format(
        " %s   %d plugins   v%d.%d.%d",
        os.date("%d-%m-%Y %H:%M:%S"),
        plugins,
        v.major, v.minor, v.patch
    )
        end
dashboard.section.footer.val = footer()

-- Layout
dashboard.config.layout = {
    { type = "padding", val = 1 },
    dashboard.section.header,
    { type = "padding", val = 2 },
    dashboard.section.buttons,
    { type = "padding", val = 1 },
    dashboard.section.footer,
}

-- Setup
alpha.setup(dashboard.config)

-- Hide folding on alpha buffer
vim.api.nvim_create_autocmd("FileType", {
    pattern = "alpha",
    command = "setlocal nofoldenable"
})
    end
}
