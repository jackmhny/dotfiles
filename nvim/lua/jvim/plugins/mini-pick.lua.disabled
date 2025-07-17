return {
    'echasnovski/mini.pick',
    version = false,
    config = function()
        local pick = require('mini.pick')
        pick.setup({
            -- Window configuration
            window = {
                -- Floating window configuration
                config = {
                    relative = 'editor',
                    width = 0.9,
                    height = 0.8,
                },
            },
            -- Options for file source
            options = {
                -- Use case-sensitive matching
                use_case = 'smart',
                -- Show hidden files
                show_hidden = false,
            },
            
            mappings = {
                choose = '<CR>',
                choose_in_split = '<C-s>',
                choose_in_vsplit = '<C-v>',
                choose_in_tab = '<C-t>',
                scroll_up = '<C-b>',
                scroll_down = '<C-f>',
                toggle_preview = '<C-p>',
            },
        })

        -- Set up some convenient keymaps for quick access
        vim.keymap.set('n', '<leader>ff', function() pick.builtin.files() end, { desc = 'Find files' })
        vim.keymap.set('n', '<leader>fb', function() pick.builtin.buffers() end, { desc = 'Find buffers' })
        vim.keymap.set('n', '<leader>fg', function() pick.builtin.grep_live() end, { desc = 'Live grep' })
        vim.keymap.set('n', '<leader>fh', function() pick.builtin.help() end, { desc = 'Search help' })
    end,
}
