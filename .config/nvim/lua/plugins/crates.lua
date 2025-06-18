return {
    "saecki/crates.nvim",
    event = { "BufRead Cargo.toml" },
    dependencies = "hrsh7th/nvim-cmp",
    opts = {
        completion = {
            crates = {
                enabled = true,
                max_results = 8,
                min_chars = 3,
            },
        },
    },
    config = function(_, opts)
        local crates = require("crates")
        crates.setup(opts)

        crates.show()
    end,
    keys = {
        {
            "<leader>rct",
            function()
                require("crates").toggle()
            end,
            mode = "n",
            desc = "[R]ust [C]rates [T]oggle",
        },
        {
            "<leader>rcu",
            function()
                require("crates").update_crate()
            end,
            mode = "n",
            desc = "[R]ust [C]rates [U]pdate crate",
        },
        {
            "<leader>rcu",
            function()
                require("crates").update_crates()
            end,
            mode = "v",
            desc = "[R]ust [C]rates [U]pdate crates",
        },
        {
            "<leader>rca",
            function()
                require("crates").update_all_crates()
            end,
            mode = "v",
            desc = "[R]ust [C]rates Update [A]ll",
        },
        {
            "<leader>rcU",
            function()
                require("crates").upgrade_crate()
            end,
            mode = "n",
            desc = "[R]ust [C]rates [U]pgrade crate",
        },
        {
            "<leader>rcU",
            function()
                require("crates").upgrade_crates()
            end,
            mode = "v",
            desc = "[R]ust [C]rates [U]pgrade crates",
        },
        {
            "<leader>rcA",
            function()
                require("crates").upgrade_all_crates()
            end,
            mode = "n",
            desc = "[R]ust [C]rates upgrade [A]ll",
        },
        {
            "<leader>rcf",
            function()
                require("crates").show_features_popup()
            end,
            mode = "n",
            desc = "[R]ust [C]rates show [F]eatures",
        },
        {
            "<leader>rcv",
            function()
                require("crates").show_versions_popup()
            end,
            mode = "n",
            desc = "[R]ust [C]rates show [V]ersions",
        },

        {
            "<leader>rcd",
            function()
                require("crates").show_dependencies_popup()
            end,
            mode = "n",
            desc = "[R]ust [C]rates show [D]ependencies",
        },
    },
}
