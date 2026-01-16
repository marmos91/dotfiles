return {
    { -- Highlight, edit, and navigate code
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        event = { "BufReadPost", "BufNewFile" },
        config = function()
            -- Prefer git instead of curl in order to improve connectivity in some environments
            require("nvim-treesitter").prefer_git = true

            -- Install parsers
            require("nvim-treesitter").setup({
                ensure_installed = {
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
                },
                auto_install = true,
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
