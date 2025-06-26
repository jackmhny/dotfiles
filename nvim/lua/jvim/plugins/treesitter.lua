return {
    {
        "nvim-treesitter/nvim-treesitter",
        dependencies = {
            "nvim-treesitter/nvim-treesitter-textobjects",
        },
        config = function()
            require('nvim-treesitter.configs').setup({
                highlight = {
                    enable = true,
                },
                textobjects = {
                    select = {
                        enable = true,
                        keymaps = {
                            ["at"] = "@tag.outer",
                            ["it"] = "@tag.inner",
                        },
                    },
                    move = {
                        enable = true,
                        goto_next_start = {
                            ["]t"] = "@tag.outer",
                        },
                        goto_previous_start = {
                            ["[t"] = "@tag.outer",
                        },
                    },
                },
            })
        end
    }
}
