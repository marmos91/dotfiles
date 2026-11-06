return {
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            -- Automatically install LSPs and related tools to stdpath for Neovim
            { "williamboman/mason.nvim", config = true }, -- NOTE: Must be loaded before dependants
            "williamboman/mason-lspconfig.nvim",
            "WhoIsSethDaniel/mason-tool-installer.nvim",

            -- Useful status updates for LSP.
            { "j-hui/fidget.nvim", opts = {} },

            -- JSON/YAML schema support
            "b0o/schemastore.nvim",

            -- lazydev.nvim is already configured in lua/plugins/lazyedev.lua
            -- neodev.nvim has been removed as it's no longer needed with lazydev.nvim
            { "towolf/vim-helm", ft = "helm" },
        },
        config = function()
            require("config.lsp.attach")

            -- LSP servers and clients are able to communicate to each other what features they support.
            --  By default, Neovim doesn't support everything that is in the LSP specification.
            --  When you add nvim-cmp, luasnip, etc. Neovim now has *more* capabilities.
            --  So, we create new capabilities with nvim cmp, and then broadcast that to the servers.
            local capabilities = vim.lsp.protocol.make_client_capabilities()
            capabilities = vim.tbl_deep_extend("force", capabilities, require("cmp_nvim_lsp").default_capabilities())

            local servers = require("config.lsp.servers")

            -- Ensure the servers (config/lsp/servers.lua) and tools below are installed
            --  To check the current status of installed tools and/or manually install
            --  other tools, you can run
            --    :Mason
            --
            --  You can press `g?` for help in this menu.
            require("mason").setup()

            -- LSP servers to install via mason-lspconfig
            local lsp_servers = vim.tbl_keys(servers or {})

            -- Additional tools (formatters/linters) to install via mason-tool-installer.
            -- Everything else conform/lint/gopls reference is provided by Nix
            -- (nixfmt, rustfmt, black, shfmt, buildifier, markdownlint, taplo, gofumpt)
            -- or by the LSP servers in config/lsp/servers.lua.
            local tools = {
                "stylua", -- Lua formatter, referenced by conform
                "tree-sitter-cli", -- Required by nvim-treesitter (main branch) to compile parsers
            }

            -- Apply our overrides on top of the server configs shipped in
            -- nvim-lspconfig's lsp/ directory, which vim.lsp.config resolves.
            -- mason-lspconfig's automatic_enable then calls vim.lsp.enable().
            for server_name, server in pairs(servers) do
                server.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {})
                vim.lsp.config(server_name, server)
            end

            require("mason-lspconfig").setup({
                ensure_installed = lsp_servers,
                automatic_enable = true,
            })

            -- Use mason-tool-installer for formatters/linters
            require("mason-tool-installer").setup({
                ensure_installed = tools,
            })
        end,
    },
}
