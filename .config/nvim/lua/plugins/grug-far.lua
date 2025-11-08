return {
    "MagicDuck/grug-far.nvim",
    config = function()
        -- optional setup call to override plugin options
        -- alternatively you can set options with vim.g.grug_far = { ... }
        require("grug-far").setup({
            -- options, see Configuration section below
            -- there are no required options atm
        })
    end,
    keys = {
        {
            "<leader>ss",
            function()
                require("grug-far").open()
            end,
            mode = "n",
            desc = "[S]earch [S]pectre",
        },
    },
}
