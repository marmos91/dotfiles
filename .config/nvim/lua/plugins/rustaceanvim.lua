return {
    "mrcjkb/rustaceanvim",
    version = "^6",
    lazy = false,
    opts = {
        server = {
            settings = {
                ["rust-analyzer"] = {
                    -- Enable all inlay hints
                    inlayHints = {
                        enable = true,
                        chainingHints = { enable = true },
                        parameterHints = { enable = true },
                        typeHints = { enable = true },
                        closingBraceHints = { enable = true, minLines = 25 },
                        maxLength = 25,
                        renderColons = true,
                    },
                },
            },
        },
    },
    config = function(_, opts)
        vim.g.rustaceanvim = opts

        -- Auto-enable inlay hints for Rust files
        vim.api.nvim_create_autocmd("FileType", {
            pattern = "rust",
            callback = function()
                vim.lsp.inlay_hint.enable(true, { bufnr = 0 })
            end,
        })
    end,
}
