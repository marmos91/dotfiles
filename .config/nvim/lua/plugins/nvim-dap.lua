return {
    "mfussenegger/nvim-dap",
    event = "VeryLazy",
    dependencies = {
        {
            "rcarriga/nvim-dap-ui",
            config = function(_, opts)
                local dap, dapui = require("dap"), require("dapui")

                dapui.setup(opts)

                dap.listeners.before.attach.dapui_config = function()
                    dapui.open()
                end
                dap.listeners.before.launch.dapui_config = function()
                    dapui.open()
                end
                dap.listeners.before.event_terminated.dapui_config = function()
                    dapui.close()
                end
                dap.listeners.before.event_exited.dapui_config = function()
                    dapui.close()
                end
            end
        },
        "nvim-neotest/nvim-nio",
        {
            "jay-babu/mason-nvim-dap.nvim",
            opts = {
                ensure_installed = { "codelldb", "delve", "cpptools" },
                automatic_installation = true,
                handlers = {
                    function(config)
                        require("mason-nvim-dap").default_setup(config)
                    end,
                },
            },
        },
        {
            "theHamsta/nvim-dap-virtual-text",
        },
    },
    opts = {
        configurations = {
            go = {
                {
                    type = "delve",
                    name = "Debug",
                    request = "launch",
                    program = "${file}",
                },
                {
                    type = "delve",
                    name = "Debug test", -- configuration for debugging test files
                    request = "launch",
                    mode = "test",
                    program = "${file}",
                },
                -- works with go.mod packages and sub packages
                {
                    type = "delve",
                    name = "Debug test (go.mod)",
                    request = "launch",
                    mode = "test",
                    program = "./${relativeFileDirname}",
                },
            },
        },
    },
    init = function()
        vim.fn.sign_define("DapBreakpoint", { text = "🐞" })
    end,
    keys = {
        {
            "<leader>dt",
            function()
                require("dap").toggle_breakpoint()
            end,
            desc = "Toggle Breakpoint",
            nowait = true,
            remap = false,
        },
        {
            "<leader>dc",
            function()
                require("dap").continue()
            end,
            desc = "Continue",
            nowait = true,
            remap = false,
        },
        {
            "<leader>di",
            function()
                require("dap").step_into()
            end,
            desc = "Step Into",
            nowait = true,
            remap = false,
        },
        {
            "<leader>do",
            function()
                require("dap").step_over()
            end,
            desc = "Step Over",
            nowait = true,
            remap = false,
        },
        {
            "<leader>du",
            function()
                require("dap").step_out()
            end,
            desc = "Step Out",
            nowait = true,
            remap = false,
        },
        {
            "<leader>dr",
            function()
                require("dap").repl.open()
            end,
            desc = "Open REPL",
            nowait = true,
            remap = false,
        },
        {
            "<leader>dl",
            function()
                require("dap").run_last()
            end,
            desc = "Run Last",
            nowait = true,
            remap = false,
        },
        {
            "<leader>dq",
            function()
                require("dap").terminate()
                require("dapui").close()
                require("nvim-dap-virtual-text").toggle()
            end,
            desc = "Terminate",
            nowait = true,
            remap = false,
        },
        {
            "<leader>db",
            function()
                require("dap").list_breakpoints()
            end,
            desc = "List Breakpoints",
            nowait = true,
            remap = false,
        },
        {
            "<leader>de",
            function()
                require("dap").set_exception_breakpoints({ "all" })
            end,
            desc = "Set Exception Breakpoints",
            nowait = true,
            remap = false,
        },
    },
}
