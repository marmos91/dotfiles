return {
    {
        "folke/which-key.nvim",
        event = "VimEnter", -- Sets the loading event to 'VimEnter'
        config = function() -- This is the function that runs, AFTER loading
            local wk = require("which-key")

            -- Document existing key chains
            wk.add({
                { "<leader>b", group = "[B]uffer" },
                { "<leader>c", group = "[C]ode" },
                { "<leader>d", group = "[D]iagnostics" },
                { "<leader>g", group = "[G]it" },
                { "<leader>m", group = "[M]arkdown" },
                { "<leader>n", group = "[N]otifications" },
                { "<leader>s", group = "[S]earch" },
                { "<leader>r", group = "[R]ust" },
                { "<leader>rc", group = "[C]rates" },
                { "<leader>t", group = "[T]oggle" },
                { "<leader>g", desc = "[G]it", mode = "v" },
            })
        end,
        keys = {
            {
                "<leader>?",
                function()
                    require("which-key").show({ global = false })
                end,
                desc = "Buffer Local Keymaps (which-key)",
            },
        },
    },
}
-- vim: ts=2 sts=2 sw=2 et
