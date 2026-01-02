return {
    {
        "apzelos/blamer.nvim",
        event = "VeryLazy",
        init = function(_)
            vim.g.blamer_enabled = 1
        end,
    },
}
