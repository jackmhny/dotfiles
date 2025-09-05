return {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
        require('lualine').setup({
            options = {
                theme = '16color',
                section_separators = '',
                component_separators = ''
            }
        })
    end
}

