return {
    "mbbill/undotree",
    lazy = false,
    keys = {
        {
            "<leader>uu",
            function()
                vim.cmd.UndotreeToggle()
            end,
            desc = "[U]ndo-tree toggle",
        },
    },
}
