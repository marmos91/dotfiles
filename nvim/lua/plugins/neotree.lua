return {
    "nvim-neo-tree/neo-tree.nvim",
    version = "*",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
        "MunifTanjim/nui.nvim",
    },
    cmd = "Neotree",
    opts = {
        close_if_last_window = true,
        filesystem = {
            follow_current_file = {
                enabled = true,
                leave_dirs_open = true,
            },
        },
    },
    keys = {
        {
            "<c-n>",
            function()
                require("neo-tree.command").execute({ toggle = true, reveal = true })
            end,
            desc = "Explorer NeoTree (Root Dir)",
        },
    },
}
