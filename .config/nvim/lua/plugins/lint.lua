return {
    { -- Linting
        "mfussenegger/nvim-lint",
        event = { "BufReadPre", "BufNewFile" },
        opts = {
            linters_by_ft = {
                markdown = { "markdownlint" },
                javascript = { "eslint_d" },
                javascriptreact = { "eslint_d" },
                typescript = { "eslint_d" },
                typescriptreact = { "eslint_d" },
                bzl = { "buildifier" },
            },
        },
        config = function(_, opts)
            local lint = require("lint")
            lint.linters_by_ft = opts.linters_by_ft

            -- Create autocommand which carries out the actual linting
            -- on the specified events.
            local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })
            vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "TextChanged", "InsertLeave" }, {
                group = lint_augroup,
                callback = function()
                    require("lint").try_lint()
                end,
            })
        end,
    },
}
