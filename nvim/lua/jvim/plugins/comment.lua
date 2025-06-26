return {
    'numToStr/Comment.nvim',
    opts = {
        -- add any custom configurations here
    },
    config = function()
        require('Comment').setup({
            mappings = {
                basic = false,  -- Disable gc/gb mappings
                extra = false,  -- Disable gco/gcO/etc mappings
            }

        })

        local api = require('Comment.api')
        
        vim.keymap.set('n', '<C-/>', api.toggle.linewise.current, { desc = 'Toggle comment line' })
        vim.keymap.set('v', '<C-/>', '<ESC><cmd>lua require("Comment.api").toggle.linewise(vim.fn.visualmode())<CR>', { desc = 'Toggle comment line' })
        
        -- Block commenting (alternative mapping since some terminals might intercept Ctrl+/)
        vim.keymap.set('n', '<C-_>', api.toggle.linewise.current, { desc = 'Toggle comment line' })
        vim.keymap.set('v', '<C-_>', '<ESC><cmd>lua require("Comment.api").toggle.linewise(vim.fn.visualmode())<CR>', { desc = 'Toggle comment line' })
    end
}

