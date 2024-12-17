return {
    {
        "nvim-lualine/lualine.nvim",
        event = "VeryLazy",
        dependencies = {
            { "ofseed/copilot-status.nvim" },
            { "folke/noice.nvim" },
        },
        config = function()
            require("lualine").setup({
                options = {
                    theme = "auto",
                    globalstatus = true,
                    disabled_filetypes = { statusline = { "dashboard", "alpha", "starter" } },
                },
                sections = {
                    lualine_x = {
                        {
                            ---@diagnostic disable-next-line: undefined-field
                            require("noice").api.status.mode.get,
                            ---@diagnostic disable-next-line: undefined-field
                            cond = require("noice").api.status.mode.has,
                            color = { fg = "#ff9e64" },
                        },
                        "copilot",
                        "filetype",
                        "fileformat",
                        "encoding",
                    },
                },
            })
        end,
    },
}
