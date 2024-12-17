return {
    {
        "stevearc/conform.nvim",
        event = { "BufReadPre", "BufNewFile" },
        dependencies = {
            "rcarriga/nvim-notify",
        },
        keys = {
            {
                "<leader>cf",
                function()
                    require("conform").format({ async = true, lsp_fallback = true })
                end,
                mode = "",
                desc = "[C]ode [F]ormat",
            },
            {
                "<leader>tf",
                function()
                    if vim.g.disable_autoformat then
                        vim.api.nvim_command("FormatEnable")
                    else
                        vim.api.nvim_command("FormatDisable")
                    end
                end,
                mode = "",
                desc = "[T]oggle [F]ormat",
            },
        },
        ---@class ConformOpts
        opts = {
            format = {
                timeout_ms = 3000,
                async = false,
                quiet = false,
                lsp_format = "fallback",
            },
            notify_on_error = true,
            format_on_save = function(bufnr)
                -- Disable "format_on_save lsp_fallback" for languages that don't
                -- have a well standardized coding style. You can add additional
                -- languages here or re-enable it for the disabled ones.
                local disable_filetypes = {
                    c = true,
                    cpp = true,
                }
                return {
                    timeout_ms = 500,
                    lsp_fallback = not disable_filetypes[vim.bo[bufnr].filetype],
                }
            end,
            formatters_by_ft = {
                lua = { "stylua" },
                python = { "black" },
                bzl = { "buildifier" },
                bash = { "shfmt" },
                ["markdown"] = { "markdownlint", "markdown-toc" },
                ["markdown.mdx"] = { "markdownlint", "markdown-toc" },
                nix = { "nixfmt" },
                typescript = {},
                typescriptreact = {},
                -- Conform can also run multiple formatters sequentially
                -- python = { "isort", "black" },
                --
                -- You can use a sub-list to tell conform to run *until* a formatter
                -- is found.
                -- javascript = { { "prettierd", "prettier" } },
            },
        },
        config = function(_, opts)
            require("conform").setup(opts)

            vim.api.nvim_create_user_command("FormatDisable", function()
                vim.b.disable_autoformat = false
                vim.g.disable_autoformat = true
                require("notify")("Auto-formatting disabled", "info", {
                    title = "Conform",
                })
            end, {
                desc = "Disable autoformat-on-save",
                bang = true,
            })

            vim.api.nvim_create_user_command("FormatEnable", function()
                vim.b.disable_autoformat = false
                vim.g.disable_autoformat = false
                require("notify")("Auto-formatting enabled", "info", {
                    title = "Conform",
                })
            end, {
                desc = "Re-enable autoformat-on-save",
            })
        end,
    },
}
-- vim: ts=2 sts=2 sw=2 et
