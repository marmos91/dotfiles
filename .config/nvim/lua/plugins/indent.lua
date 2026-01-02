return {
    { -- Add indentation guides even on blank lines
        "lukas-reineke/indent-blankline.nvim",
        -- Enable `lukas-reineke/indent-blankline.nvim`
        -- See `:help ibl`
        event = "VeryLazy",
        main = "ibl",
        opts = {
            exclude = {
                filetypes = { "help", "alpha", "dashboard", "Trouble", "lazy", "neo-tree" },
            },
        },
    },
}
