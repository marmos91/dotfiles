return {
    {
        "zbirenbaum/copilot.lua",
        cmd = "Copilot",
        event = "InsertEnter",
        opts = {
            suggestion = {
                enabled = false, -- Disabled because using copilot-cmp integration
                auto_trigger = false,
            },
            panel = { enabled = false },
            filetypes = {
                markdown = true,
                help = true,
                yaml = true,
                ["."] = true,
            },
        },
        config = function(_, opts)
            require("copilot").setup(opts)
        end,
    },
}
