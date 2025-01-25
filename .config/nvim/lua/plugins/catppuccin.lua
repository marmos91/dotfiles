return {
    {
        "catppuccin/nvim",
        name = "catppuccin",
        priority = 1000,
        config = function()
            require("catppuccin").setup({
                cmp = true,
                gitsigns = true,
                indent_blankline = {
                    enabled = false,
                    scope_color = "sapphire",
                    colored_indent_levels = false,
                },
                mason = true,
                native_lsp = {
                    enabled = true,
                },
                notify = true,
                neotree = true,
                telescope = true,
                treesitter = true,
            })

            vim.cmd.colorscheme("catppuccin")
        end,
    },
}
