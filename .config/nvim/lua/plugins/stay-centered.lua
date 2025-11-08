return {
    "arnamak/stay-centered.nvim",
    lazy = false,
    opts = {
        skip_filetypes = {},
    },
    keys = {
        {
            "<leader>sc",
            function()
                require("stay-centered").toggle()
            end,
            desc = "Toggle Stay Centered",
        },
    },
}
