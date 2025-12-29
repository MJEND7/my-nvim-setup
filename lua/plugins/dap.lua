return {
	{

		"ramboe/ramboe-dotnet-utils",
		dependencies = { "mfussenegger/nvim-dap" },
	},
	{
		-- Debug Framework
		"mfussenegger/nvim-dap",
		dependencies = {
			"rcarriga/nvim-dap-ui",
		},
		config = function()
			local dap = require("dap")

			local mason_path = vim.fn.stdpath("data") .. "/mason/packages/netcoredbg/netcoredbg"

			local netcoredbg_adapter = {
				type = "executable",
				command = mason_path,
				args = { "--interpreter=vscode" },
			}

			dap.adapters.netcoredbg = netcoredbg_adapter -- needed for normal debugging
			dap.adapters.coreclr = netcoredbg_adapter -- needed for unit test debugging

			dap.configurations.cs = {
				{
					type = "coreclr",
					name = "launch - netcoredbg",
					request = "launch",
					program = function()
						return require("dap-dll-autopicker").build_dll_path()
					end,

					-- justMyCode = false,
					-- stopAtEntry = false,
					-- -- program = function()
					-- --   -- todo: request input from ui
					-- --   return "/path/to/your.dll"
					-- -- end,
					-- env = {
					--   ASPNETCORE_ENVIRONMENT = function()
					--     -- todo: request input from ui
					--     return "Development"
					--   end,
					--   ASPNETCORE_URLS = function()
					--     -- todo: request input from ui
					--     return "http://localhost:5050"
					--   end,
					-- },
					-- cwd = function()
					--   -- todo: request input from ui
					--   return vim.fn.getcwd()
					-- end,
				},
			}

			local map = vim.keymap.set

			local opts = { noremap = true, silent = true }

			map("n", "<F5>", "<Cmd>lua require'dap'.continue()<CR>", opts)
			map("n", "<F6>", "<Cmd>lua require('neotest').run.run({strategy = 'dap'})<CR>", opts)
			map("n", "<F9>", "<Cmd>lua require'dap'.toggle_breakpoint()<CR>", opts)
			map("n", "<F10>", "<Cmd>lua require'dap'.step_over()<CR>", opts)
			map("n", "<F11>", "<Cmd>lua require'dap'.step_into()<CR>", opts)
			map("n", "<F8>", "<Cmd>lua require'dap'.step_out()<CR>", opts)
			-- map("n", "<F12>", "<Cmd>lua require'dap'.step_out()<CR>", opts)
			map("n", "<leader>dr", "<Cmd>lua require'dap'.repl.open()<CR>", opts)
			map("n", "<leader>dl", "<Cmd>lua require'dap'.run_last()<CR>", opts)
			map("n", "<leader>du", "<Cmd>lua require('dapui').toggle()<CR>", { noremap = true, silent = true, desc = "toggle dapui" })
			map(
				"n",
				"<leader>dt",
				"<Cmd>lua require('neotest').run.run({strategy = 'dap'})<CR>",
				{ noremap = true, silent = true, desc = "debug nearest test" }
			)
			require("neotest").setup({
				adapters = {
					require("neotest-dotnet"),
				},
			})
		end,
		event = "VeryLazy",
	},
	{ "nvim-neotest/nvim-nio" },
	{
		-- UI for debugging
		"rcarriga/nvim-dap-ui",
		dependencies = {
			"mfussenegger/nvim-dap",
		},
		config = function()
			local dapui = require("dapui")
			local dap = require("dap")

			--- open ui immediately when debugging starts
			dap.listeners.after.event_initialized["dapui_config"] = function()
				dapui.open()
			end
			-- Commented out to debug auto-close issue
			-- dap.listeners.before.event_terminated["dapui_config"] = function()
			-- 	dapui.close()
			-- end
			-- dap.listeners.before.event_exited["dapui_config"] = function()
			-- 	dapui.close()
			-- end

			-- default configuration
			dapui.setup()
		end,
	},
	{
		"nvim-neotest/neotest",
		requires = {
			{
				"Issafalcon/neotest-dotnet",
			},
		},
		dependencies = {
			"nvim-neotest/nvim-nio",
			"nvim-lua/plenary.nvim",
			"antoinemadec/FixCursorHold.nvim",
			"nvim-treesitter/nvim-treesitter",
		},
	},
	{
		"Issafalcon/neotest-dotnet",
		lazy = false,
		dependencies = {
			"nvim-neotest/neotest",
		},
	},
}
