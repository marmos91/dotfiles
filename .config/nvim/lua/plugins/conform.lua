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
                    if vim.g.disable_autoformat or vim.b.disable_autoformat then
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
            default_format_opts = {
                timeout_ms = 3000,
                lsp_format = "fallback",
            },
            notify_on_error = true,
            format_on_save = function(bufnr)
                if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
                    return nil
                end
                -- Disable "format_on_save lsp_fallback" for languages that don't
                -- have a well standardized coding style. You can add additional
                -- languages here or re-enable it for the disabled ones.
                local disable_filetypes = {
                    c = true,
                    cpp = true,
                }
                -- Set lsp_format itself, not lsp_fallback: conform fills an unset
                -- lsp_format from default_format_opts before translating
                -- lsp_fallback, so lsp_fallback = false would be overridden.
                return {
                    timeout_ms = 500,
                    lsp_format = disable_filetypes[vim.bo[bufnr].filetype] and "never" or "fallback",
                }
            end,
            formatters_by_ft = {
                lua = { "stylua" },
                python = { "black" },
                bzl = { "buildifier" },
                bash = { "shfmt" },
                sh = { "shfmt" },
                ["markdown"] = { "markdownlint" },
                ["markdown.mdx"] = { "markdownlint" },
                nix = { "nixfmt" },
                -- TypeScript/TSX formatting is owned by vtsls, which conform
                -- reaches through lsp_format above.
                rust = { "rustfmt" },
            },
        },
        config = function(_, opts)
            require("conform").setup(opts)

            -- `!` scopes the switch to the current buffer; without it the whole
            -- session is toggled.
            vim.api.nvim_create_user_command("FormatDisable", function(args)
                if args.bang then
                    vim.b.disable_autoformat = true
                else
                    vim.g.disable_autoformat = true
                end
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
