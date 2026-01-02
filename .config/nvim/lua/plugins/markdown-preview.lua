return {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    ft = { "markdown" },
    build = function()
        vim.fn["mkdp#util#install"]()
    end,
    keys = {
        {
            "<leader>mp",
            "<cmd>MarkdownPreviewToggle<cr>",
            desc = "[M]arkdown [P]review Toggle",
        },
    },
    config = function()
        vim.cmd([[do FileType]])
    end,
}
