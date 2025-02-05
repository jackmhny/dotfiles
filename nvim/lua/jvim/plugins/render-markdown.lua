return {
      {
          'ryleelyman/latex.nvim',
          opts = {}
    },
    {
        'MeanderingProgrammer/render-markdown.nvim',
        dependencies = {
            'nvim-treesitter/nvim-treesitter',
            'echasnovski/mini.icons'
        },
        config = function()
            require('render-markdown').setup({
                sign = {
                    enabled = false
                },
                latex = {
                    enabled = true
                },
                win_options = {
                    conceallevel = {
                        rendered = 2
                    }
                },
            })
        end,
    },
    {
        'nvim-treesitter/nvim-treesitter',
        build = ':TSUpdate',
        config = function()
            require('nvim-treesitter.configs').setup({
                ensure_installed = {
                    'bibtex',
                    'latex',
                    'markdown',
                    'markdown_inline'
                },
                sync_install = true,
                auto_install = true,
                highlight = {
                    enable = true
                },
                indent = {
                    enable = true
                }
            })
        end
    }
}
