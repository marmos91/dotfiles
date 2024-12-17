return {
    {
        "nvimdev/dashboard-nvim",
        dependencies = {
            "MaximilianLloyd/ascii.nvim",
            "MunifTanjim/nui.nvim",
        },
        event = "VimEnter",
        opts = function()
            local logo = require("ascii").art.text.neovim.sharp

            for _ = 0, 8 do
                table.insert(logo, 1, [[                                                                       ]])
            end

            for _ = 0, 2 do
                table.insert(logo, [[                                                                       ]])
            end

            local opts = {
                theme = "hyper",
                hide = {
                    -- this is taken care of by lualine
                    -- enabling this messes up the actual laststatus setting after loading a file
                    statusline = false,
                },
                config = {
                    header = logo,
                    week_header = {
                        enable = false,
                    },
                    packages = { enable = true },
                    shortcut = {
                        { desc = "󰊳 Update", group = "@property", action = "Lazy update", key = "u" },
                        {
                            icon = " ",
                            icon_hl = "@variable",
                            desc = "Files",
                            group = "Label",
                            action = "Telescope find_files",
                            key = "f",
                        },
                        {
                            action = "Telescope oldfiles",
                            desc = " Recent Files",
                            icon = " ",
                            key = "r",
                        },
                        {
                            action = "Telescope live_grep",
                            desc = " Find Text",
                            icon = " ",
                            key = "g",
                        },
                        {
                            action = function()
                                require("telescope.builtin").find_files({ cwd = vim.fn.stdpath("config") })
                            end,
                            desc = " Config",
                            icon = " ",
                            key = "c",
                        },
                        {
                            action = "Lazy",
                            desc = " Lazy",
                            icon = "󰒲 ",
                            key = "l",
                        },
                        {
                            action = "qa",
                            desc = " Quit",
                            icon = " ",
                            key = "q",
                        },
                    },
                },
            }

            -- close Lazy and re-open when the dashboard is ready
            if vim.o.filetype == "lazy" then
                vim.cmd.close()
                vim.api.nvim_create_autocmd("User", {
                    pattern = "DashboardLoaded",
                    callback = function()
                        require("lazy").show()
                    end,
                })
            end

            return opts
        end,
    },
}
