return {
    { -- Adds git related signs to the gutter, as well as utilities for managing changes
        "lewis6991/gitsigns.nvim",
        opts = {
            signs = {
                add = { text = "+" },
                change = { text = "~" },
                delete = { text = "_" },
                topdelete = { text = "‾" },
                changedelete = { text = "~" },
            },
            on_attach = function(bufnr)
                local gitsigns = require("gitsigns")

                local function map(mode, l, r, opts)
                    opts = opts or {}
                    opts.buffer = bufnr
                    vim.keymap.set(mode, l, r, opts)
                end

                -- Navigation
                map("n", "]c", function()
                    if vim.wo.diff then
                        vim.cmd.normal({ "]c", bang = true })
                    else
                        gitsigns.nav_hunk("next")
                    end
                end, { desc = "Jump to next git [c]hange" })

                map("n", "[c", function()
                    if vim.wo.diff then
                        vim.cmd.normal({ "[c", bang = true })
                    else
                        gitsigns.nav_hunk("prev")
                    end
                end, { desc = "Jump to previous git [c]hange" })

                -- Actions
                -- normal mode
                map("n", "<leader>gb", gitsigns.blame_line, { desc = "[G]it [b]lame line" })
                map("n", "<leader>gd", gitsigns.diffthis, { desc = "[G]it [d]iff against index" })
                map("n", "<leader>gD", function()
                    gitsigns.diffthis("@")
                end, { desc = "git [D]iff against last commit" })
                -- Toggles
                map("n", "<leader>tb", gitsigns.toggle_current_line_blame, { desc = "[T]oggle git show [b]lame line" })
                map("n", "<leader>tD", gitsigns.toggle_deleted, { desc = "[T]oggle git show [D]eleted" })
            end,
        },
    },
}
-- vim: ts=2 sts=2 sw=2 et
