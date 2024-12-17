return {
    "epwalsh/obsidian.nvim",
    version = "*", -- recommended, use latest release instead of latest commit
    lazy = true,
    event = {
        "BufReadPre " .. vim.fn.expand("~") .. "/vaults/**.md",
        "BufNewFile " .. vim.fn.expand("~") .. "/vaults/**.md",
    },
    dependencies = {
        "nvim-lua/plenary.nvim",
        "hrsh7th/nvim-cmp",
        "nvim-telescope/telescope.nvim",
        "nvim-treesitter/nvim-treesitter",
    },
    opts = {
        workspaces = {
            {
                name = "cubbit",
                path = "~/vaults/cubbit",
            },
            {
                name = "personal",
                path = "~/vaults/personal",
            },
        },
        mappings = {
            -- Overrides the 'gf' mapping to work on markdown/wiki links within your vault.
            ["gf"] = {
                action = function()
                    return require("obsidian").util.gf_passthrough()
                end,
                opts = { noremap = false, expr = true, buffer = true },
            },
            -- Toggle check-boxes.
            ["<leader>oc"] = {
                action = function()
                    return require("obsidian").util.toggle_checkbox()
                end,
                desc = "[O]bsidian: Toggle [C]heckbox",
                opts = { buffer = true },
            },
            -- Smart action depending on context, either follow link or toggle checkbox.
            ["<cr>"] = {
                action = function()
                    return require("obsidian").util.smart_action()
                end,
                opts = { buffer = true, expr = true },
            },
        },
        templates = {
            folder = "templates",
            date_format = "%Y-%m-%d",
            time_format = "%H:%M",
            -- A map for custom variables, the key should be the variable and the value a function
            substitutions = {},
        },
        picker = {
            -- Set your preferred picker. Can be one of 'telescope.nvim', 'fzf-lua', or 'mini.pick'.
            name = "telescope.nvim",
        },
    },
    keys = {
        {
            "<leader>on",
            "<cmd>ObsidianTemplate note<cr>",
            desc = "[O]bsidian [N]ew note",
        },
        {
            "<leader>of",
            "<cmd>s/\\(# \\)[^_]*_/\\1/ | s/-/ /g<cr>", -- strip date from note title and replace dashes with spaces. Must have cursor on title
            desc = "[O]bsidian [F]ormat title",
        },
        {
            "<leader>so",
            "<cmd>Telescope find_files search_dirs={" .. os.getenv("OBSIDIAN_VAULTS_DIR") .. "}<cr>",
            desc = "[S]earch [O]bsidian files",
        },
        {
            "<leader>ok",
            "<cmd>:!mv %:p %:p:s/0-inbox/1-zettelkasten/<cr>:bd<cr>", -- Moves note from the 0-inbox folder to 1-zettelkasten
            desc = "[O]bsidian [C]ubbit note accept(O[K])",
        },
        {
            "<leader>od",
            "<cmd>!rm '%:p'<cr>:bd<cr>",
            desc = "[O]bsidian [D]elete current buffer",
        },
        {
            "<leader>oo",
            "<cmd>!obsidian<cr>",
            desc = "[O]bsidian [O]pen",
        },
    },
}
