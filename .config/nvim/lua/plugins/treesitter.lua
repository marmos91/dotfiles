return {
    { -- Highlight, edit, and navigate code
        "nvim-treesitter/nvim-treesitter",
        branch = "main",
        lazy = false,
        config = function()
            local parsers = {
                "bash",
                "c",
                "css",
                "diff",
                "dockerfile",
                "fish",
                "gitcommit",
                "git_rebase",
                "go",
                "gomod",
                "gosum",
                "helm",
                "html",
                "javascript",
                "json",
                "lua",
                "luadoc",
                "markdown",
                "markdown_inline",
                "python",
                "regex",
                "rust",
                "terraform",
                "toml",
                "tsx",
                "typescript",
                "vim",
                "vimdoc",
                "yaml",
            }

            local function install_parsers()
                if vim.fn.executable("tree-sitter") == 1 then
                    require("nvim-treesitter").install(parsers)
                end
            end

            -- tree-sitter CLI is provided by Mason; install parsers either now
            -- (if Mason already has it) or once Mason finishes installing it.
            install_parsers()
            vim.api.nvim_create_autocmd("User", {
                pattern = "MasonToolsUpdateCompleted",
                callback = install_parsers,
            })

            -- Enable treesitter-based highlighting
            vim.api.nvim_create_autocmd("FileType", {
                callback = function()
                    pcall(vim.treesitter.start)
                end,
            })
        end,
    },
}
-- vim: ts=2 sts=2 sw=2 et
