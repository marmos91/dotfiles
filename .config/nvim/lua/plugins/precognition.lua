return {
    "tris203/precognition.nvim",
    event = "VeryLazy",
    keys = {
        {
            "<leader>tp",
            function()
                require("precognition").toggle()
            end,
            desc = "[T]oggle [P]recognition",
        },
    },
}
