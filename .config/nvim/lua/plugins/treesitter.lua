return {
    { -- Highlight, edit, and navigate code
        "nvim-treesitter/nvim-treesitter",
        branch = "main",
        lazy = false,
        -- Refresh already-installed parsers when the plugin updates; install()
        -- below skips parsers that are merely present, so a parser built against
        -- an older grammar revision would otherwise never be recompiled.
        build = ":TSUpdate",
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
            local warned = false
            vim.api.nvim_create_autocmd("FileType", {
                callback = function(args)
                    local ok = pcall(vim.treesitter.start, args.buf)
                    -- Only warn for parsers this config installs. UI buffers
                    -- (dashboard, qf, lazy) legitimately have none, and
                    -- get_lang returns an unknown filetype unchanged.
                    if
                        not ok
                        and not warned
                        and vim.tbl_contains(parsers, vim.treesitter.language.get_lang(args.match))
                    then
                        warned = true
                        vim.notify(
                            "Treesitter highlighting unavailable — parsers are not installed yet. "
                                .. "Run :TSInstall or check :checkhealth nvim-treesitter.",
                            vim.log.levels.WARN
                        )
                    end
                end,
            })
        end,
    },
}
-- vim: ts=2 sts=2 sw=2 et
