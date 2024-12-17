return {
    {
        "nvim-pack/nvim-spectre",
        dependencies = { "nvim-lua/plenary.nvim" },
        keys = {
            {
                "<leader>ss",
                function()
                    require("spectre").open()
                end,
                mode = "n",
                desc = "[S]earch [S]pectre",
            },
        },
    },
}
