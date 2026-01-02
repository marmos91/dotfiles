return {
    "arnamak/stay-centered.nvim",
    event = "VeryLazy",
    opts = {
        skip_filetypes = {},
    },
    keys = {
        {
            "<leader>uc",
            function()
                require("stay-centered").toggle()
            end,
            desc = "Toggle Stay [C]entered",
        },
    },
}
