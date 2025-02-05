return {
    'numToStr/Comment.nvim',
    opts = {
        -- add any custom configurations here
    },
    config = function()
        require('Comment').setup({
            -- Enable keybindings
            -- `gc` operator for line comments
            -- `gb` operator for block comments
        })

        local api = require('Comment.api')
        
        vim.keymap.set('n', '<C-/>', api.toggle.linewise.current, { desc = 'Toggle comment line' })
        vim.keymap.set('v', '<C-/>', '<ESC><cmd>lua require("Comment.api").toggle.linewise(vim.fn.visualmode())<CR>', { desc = 'Toggle comment line' })
        
        -- Block commenting (alternative mapping since some terminals might intercept Ctrl+/)
        vim.keymap.set('n', '<C-_>', api.toggle.linewise.current, { desc = 'Toggle comment line' })
        vim.keymap.set('v', '<C-_>', '<ESC><cmd>lua require("Comment.api").toggle.linewise(vim.fn.visualmode())<CR>', { desc = 'Toggle comment line' })
    end
}

