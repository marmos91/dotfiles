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
    cssls = {},
    dockerls = {},
    docker_compose_language_service = {},
    eslint = {
        settings = {
            -- helps eslint find the eslintrc when it's placed in a subfolder instead of the cwd root
            workingDirectories = { mode = "auto" },
        },
    },
    gopls = {
        settings = {
            gopls = {
                gofumpt = true,
                staticcheck = true,
                usePlaceholders = true,
                completeUnimported = true,
                analyses = {
                    unusedparams = true,
                    shadow = true,
                },
                hints = {
                    assignVariableTypes = true,
                    compositeLiteralFields = true,
                    compositeLiteralTypes = true,
                    constantValues = true,
                    functionTypeParameters = true,
                    parameterNames = true,
                    rangeVariableTypes = true,
                },
            },
        },
    },
    helm_ls = {
        settings = {
            ["helm-ls"] = {
                yamlls = {
                    path = "yaml-language-server",
                },
            },
        },
    },
    html = {},
    jsonls = {
        settings = {
            json = {
                validate = { enable = true },
                schemas = require("schemastore").json.schemas(),
            },
        },
    },
    lua_ls = {
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
    -- rust_analyzer = {}, -- handled by rustaceanvim
    taplo = {},
    terraformls = {},
    vtsls = {
        settings = {
            typescript = {
                inlayHints = {
                    parameterNames = { enabled = "all" },
                    parameterTypes = { enabled = true },
                    variableTypes = { enabled = true },
                    propertyDeclarationTypes = { enabled = true },
                    functionLikeReturnTypes = { enabled = true },
                },
            },
            javascript = {
                inlayHints = {
                    parameterNames = { enabled = "all" },
                    parameterTypes = { enabled = true },
                    variableTypes = { enabled = true },
                    propertyDeclarationTypes = { enabled = true },
                    functionLikeReturnTypes = { enabled = true },
                },
            },
        },
    },
    yamlls = {
        filetypes = { "yaml", "yaml.docker-compose", "yaml.gitlab" },
        settings = {
            yaml = {
                schemaStore = {
                    enable = false,
                    url = "",
                },
                -- Lazy-load schemastore
                schemas = require("schemastore").yaml.schemas(),
                validate = true,
                completion = true,
                hover = true,
            },
        },
    },
}

-- Add bzl only on macOS (Mason doesn't support it on Linux)
if vim.fn.has("mac") == 1 then
    servers.bzl = {}
end

return servers
