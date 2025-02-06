return {
    "NvChad/nvim-colorizer.lua",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
        require("colorizer").setup({
            "*",                -- Highlight all files
            "!lazy",           -- Exclude lazy window
        }, {
            RGB = true,        -- #RGB hex codes
            RRGGBB = true,     -- #RRGGBB hex codes
            names = true,      -- "Name" codes like Blue or blue
            RRGGBBAA = true,   -- #RRGGBBAA hex codes
            AARRGGBB = true,   -- 0xAARRGGBB hex codes
            rgb_fn = true,     -- CSS rgb() and rgba() functions
            hsl_fn = true,     -- CSS hsl() and hsla() functions
            css = true,        -- Enable all CSS features: rgb_fn, hsl_fn, names, RGB, RRGGBB
            css_fn = true,     -- Enable all CSS *functions*: rgb_fn, hsl_fn
            mode = "background", -- Set the display mode: foreground/background/virtualtext
            tailwind = true,   -- Enable tailwind colors
            sass = { enable = true }, -- Enable sass colors
            virtualtext = "■",
        })
    end,
}

