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

            -- lazydev.nvim is already configured in lua/plugins/lazyedev.lua
            -- neodev.nvim has been removed as it's no longer needed with lazydev.nvim
            { "towolf/vim-helm", ft = "helm" },
        },
        config = function()
            local lsp_group = vim.api.nvim_create_augroup("lsp-group", { clear = true })

            vim.api.nvim_create_autocmd("LspAttach", {
                group = lsp_group,
                callback = function(event)
                    -- In this case, we create a function that lets us more easily define mappings specific
                    -- for LSP related items. It sets the mode, buffer and description for us each time.
                    local map = function(keys, func, desc)
                        vim.keymap.set("n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
                    end

                    -- Jump to the definition of the word under your cursor.
                    --  This is where a variable was first declared, or where a function is defined, etc.
                    --  To jump back, press <C-t>.
                    map("gd", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")

                    -- Find references for the word under your cursor.
                    map("gr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")

                    -- Jump to the implementation of the word under your cursor.
                    --  Useful when your language has ways of declaring types without an actual implementation.
                    map("gI", require("telescope.builtin").lsp_implementations, "[G]oto [I]mplementation")

                    -- Jump to the type of the word under your cursor.
                    --  Useful when you're not sure what type a variable is and you want to see
                    --  the definition of its *type*, not where it was *defined*.
                    map("<leader>D", require("telescope.builtin").lsp_type_definitions, "Type [D]efinition")

                    -- Fuzzy find all the symbols in your current document.
                    --  Symbols are things like variables, functions, types, etc.
                    map("<leader>cds", require("telescope.builtin").lsp_document_symbols, "[C]ode [D]ocument [S]ymbols")

                    -- Fuzzy find all the symbols in your current workspace.
                    --  Similar to document symbols, except searches over your entire project.
                    map(
                        "<leader>cws",
                        require("telescope.builtin").lsp_dynamic_workspace_symbols,
                        "[C]ode [W]orkspace [S]ymbols"
                    )

                    -- Execute a code action, usually your cursor needs to be on top of an error
                    -- or a suggestion from your LSP for this to activate.
                    map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")

                    -- Opens a popup that displays documentation about the word under your cursor
                    --  See `:help K` for why this keymap.
                    map("K", vim.lsp.buf.hover, "Hover Documentation")

                    -- WARN: This is not Goto Definition, this is Goto Declaration.
                    --  For example, in C this would take you to the header.
                    map("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")

                    -- The following two autocommands are used to highlight references of the
                    -- word under your cursor when your cursor rests there for a little while.
                    --    See `:help CursorHold` for information about when this is executed
                    --
                    -- When you move your cursor, the highlights will be cleared (the second autocommand).
                    local client = vim.lsp.get_client_by_id(event.data.client_id)

                    if client and client.server_capabilities.documentHighlightProvider then
                        local highlight_augroup = vim.api.nvim_create_augroup("marmos-lsp-highlight", { clear = false })
                        vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
                            buffer = event.buf,
                            group = highlight_augroup,
                            callback = vim.lsp.buf.document_highlight,
                        })

                        vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
                            buffer = event.buf,
                            group = highlight_augroup,
                            callback = vim.lsp.buf.clear_references,
                        })

                        vim.api.nvim_create_autocmd("LspDetach", {
                            group = vim.api.nvim_create_augroup("marmos-lsp-detach", { clear = true }),
                            callback = function(event2)
                                vim.lsp.buf.clear_references()
                                vim.api.nvim_clear_autocmds({ group = "marmos-lsp-highlight", buffer = event2.buf })
                            end,
                        })
                    end

                    -- The following autocommand is used to enable inlay hints in your
                    -- code, if the language server you are using supports them
                    --
                    -- This may be unwanted, since they displace some of your code
                    if client and client.server_capabilities.inlayHintProvider then
                        map("<leader>th", function()
                            local bufnr = vim.api.nvim_get_current_buf()

                            -- Try different API versions
                            if vim.lsp.inlay_hint and type(vim.lsp.inlay_hint) == "table" then
                                if vim.lsp.inlay_hint.enable and vim.lsp.inlay_hint.is_enabled then
                                    -- Neovim 0.10+ API
                                    local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr })
                                    vim.lsp.inlay_hint.enable(not enabled, { bufnr = bufnr })
                                    print("Inlay hints " .. (not enabled and "enabled" or "disabled"))
                                elseif vim.lsp.inlay_hint.toggle then
                                    -- Alternative toggle API
                                    vim.lsp.inlay_hint.toggle({ bufnr = bufnr })
                                end
                            elseif type(vim.lsp.inlay_hint) == "function" then
                                -- Function-based API
                                vim.lsp.inlay_hint(bufnr, nil)
                            elseif vim.lsp.buf.inlay_hint then
                                -- Older buffer-based API
                                vim.lsp.buf.inlay_hint(bufnr, nil)
                            else
                                vim.notify("Inlay hints API not found", vim.log.levels.WARN)
                                print("vim.lsp.inlay_hint type: " .. type(vim.lsp.inlay_hint))
                            end
                        end, "[T]oggle Inlay [H]ints")
                    end
                end,
            })

            -- LSP servers and clients are able to communicate to each other what features they support.
            --  By default, Neovim doesn't support everything that is in the LSP specification.
            --  When you add nvim-cmp, luasnip, etc. Neovim now has *more* capabilities.
            --  So, we create new capabilities with nvim cmp, and then broadcast that to the servers.
            local capabilities = vim.lsp.protocol.make_client_capabilities()
            capabilities = vim.tbl_deep_extend("force", capabilities, require("cmp_nvim_lsp").default_capabilities())

            -- Enable the following language servers
            --  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
            --
            --  Add any additional override configuration in the following tables. Available keys are:
            --  - cmd (table): Override the default command used to start the server
            --  - filetypes (table): Override the default list of associated filetypes for the server
            --  - capabilities (table): Override fields in capabilities. Can be used to disable certain LSP features.
            --  - settings (table): Override the default settings passed when initializing the server.
            --        For example, to see the options for `lua_ls`, you could go to: https://luals.github.io/wiki/settings/
            local servers = {
                bashls = {},
                bzl = {},
                cssls = {},
                eslint = {
                    settings = {
                        -- helps eslint find the eslintrc when it's placed in a subfolder instead of the cwd root
                        workingDirectories = { mode = "auto" },
                    },
                },
                gopls = {},
                helm_ls = {
                    settings = {
                        ["helm-ls"] = {
                            yamlls = {
                                path = "yaml-language-server",
                            },
                        },
                    },
                },
                jsonls = {},
                lua_ls = {
                    -- cmd = {...},
                    -- filetypes = { ...},
                    -- capabilities = {},
                    settings = {
                        Lua = {
                            completion = {
                                callSnippet = "Replace",
                            },
                            -- You can toggle below to ignore Lua_LS's noisy `missing-fields` warnings
                            -- diagnostics = { disable = { 'missing-fields' } },
                        },
                    },
                },
                marksman = {},
                pylsp = {},
                -- rust_analyzer = {},
                terraformls = {},
                vtsls = {
                    capabilities = vim.tbl_extend("keep", capabilities, {
                        documentFormattingProvider = false,
                        documentRangeFormattingProvider = false,
                    }),
                },
                yamlls = {
                    filetypes_exclude = { "helm" },
                },
            }

            -- Ensure the servers and tools above are installed
            --  To check the current status of installed tools and/or manually install
            --  other tools, you can run
            --    :Mason
            --
            --  You can press `g?` for help in this menu.
            require("mason").setup()

            -- LSP servers to install via mason-lspconfig
            local lsp_servers = vim.tbl_keys(servers or {})

            -- Additional tools (formatters/linters) to install via mason-tool-installer
            local tools = {
                "stylua", -- Lua formatter
                "markdownlint", -- Markdown linter
                "markdown-toc", -- Markdown TOC generator
                "eslint_d", -- Fast ESLint daemon (used by conform/none-ls)
                "black", -- Python formatter
                "gofumpt", -- Go formatter
                "goimports", -- Go imports organizer
                "shfmt", -- Shell formatter
                "buildifier", -- Bazel formatter
                "prettierd", -- Fast Prettier (for web dev)
                "ruff", -- Fast Python linter
                "taplo", -- TOML formatter
            }

            require("mason-lspconfig").setup({
                handlers = {
                    function(server_name)
                        local server = servers[server_name] or {}
                        -- This handles overriding only values explicitly passed
                        -- by the server configuration above. Useful when disabling
                        -- certain features of an LSP (for example, turning off formatting for tsserver)
                        server.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {})

                        require("lspconfig")[server_name].setup(server)
                    end,
                },
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
