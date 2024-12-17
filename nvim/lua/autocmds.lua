vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
    pattern = "Tiltfile",
    command = "setfiletype bzl",
})

vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
    pattern = "*.mdx",
    command = "setfiletype markdown",
})

vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
    pattern = "*.tilt",
    command = "setfiletype bzl",
})

vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
    pattern = { os.getenv("HOME") .. "/.local/share/chezmoi/*" },
    callback = function()
        vim.schedule(require("chezmoi.commands.__edit").watch)
    end,
})
