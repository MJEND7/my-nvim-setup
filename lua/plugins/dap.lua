return {
	{

		"ramboe/ramboe-dotnet-utils",
		dependencies = { "mfussenegger/nvim-dap" },
	},
	{
		"theHamsta/nvim-dap-virtual-text",
		config = function()
			require("nvim-dap-virtual-text").setup({
				enabled = true, -- enable this plugin (the default)
				enabled_commands = true, -- create commands DapVirtualTextEnable, DapVirtualTextDisable, DapVirtualTextToggle, (DapVirtualTextForceRefresh for refreshing when debug adapter did not notify its termination)
				highlight_changed_variables = true, -- highlight changed values with NvimDapVirtualTextChanged, else always NvimDapVirtualText
				highlight_new_as_changed = false, -- highlight new variables in the same way as changed variables (if highlight_changed_variables)
				show_stop_reason = true, -- show stop reason when stopped for exceptions
				commented = false, -- prefix virtual text with comment string
				only_first_definition = true, -- only show virtual text at first definition (if there are multiple)
				all_references = false, -- show virtual text on all all references of the variable (not only definitions)
				clear_on_continue = false, -- clear virtual text on "continue" (might cause flickering when stepping)
				--- A callback that determines how a variable is displayed or whether it should be omitted
				--- @param variable Variable https://microsoft.github.io/debug-adapter-protocol/specification#Types_Variable
				--- @param buf number
				--- @param stackframe dap.StackFrame https://microsoft.github.io/debug-adapter-protocol/specification#Types_StackFrame
				--- @param node userdata tree-sitter node identified as variable definition of reference (see `:h tsnode`)
				--- @param options nvim_dap_virtual_text_options Current options for nvim-dap-virtual-text
				--- @return string|nil A text how the virtual text should be displayed or nil, if this variable shouldn't be displayed
				display_callback = function(variable, buf, stackframe, node, options)
					-- by default, strip out new line characters
					if options.virt_text_pos == "inline" then
						return " = " .. variable.value:gsub("%s+", " ")
					else
						return variable.name .. " = " .. variable.value:gsub("%s+", " ")
					end
				end,
				-- position of virtual text, see `:h nvim_buf_set_extmark()`, default tries to inline the virtual text. Use 'eol' to set to end of line
				virt_text_pos = vim.fn.has("nvim-0.10") == 1 and "inline" or "eol",

				-- experimental features:
				all_frames = false, -- show virtual text for all stack frames not only current. Only works for debugpy on my machine.
				virt_lines = false, -- show virtual lines instead of virtual text (will flicker!)
				virt_text_win_col = nil, -- position the virtual text at a fixed window column (starting from the first text column) ,
				-- e.g. 80 to position at column 80, see `:h nvim_buf_set_extmark()`
			})
		end,
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
			map("n", "<F7>", "<Cmd>lua require'dap'.step_out()<CR>", opts)

			map("n", "<F11>", "<Cmd>lua require'dap'.step_into()<CR>", opts)
			map("n", "<F8>", function()
				require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
			end, { desc = "Set conditional breakpoint" })

			map("n", "<leader>dr", "<Cmd>lua require'dap'.repl.open()<CR>", opts)
			map("n", "<leader>dl", "<Cmd>lua require'dap'.run_last()<CR>", opts)
			map("n", "<leader>db", function()
				local choice = vim.fn.input("Build before restart? (y/N): ")
				if choice:lower() == "y" then
					print("Building project...")
					local output = vim.fn.system("dotnet build -c Debug")
					print(output)
					if vim.v.shell_error ~= 0 then
						print("❌ Build failed — not restarting debug session.")
						return
					end
					print("✅ Build succeeded.")
				end

				-- Restart debug session
				require("dap").restart()
			end, { noremap = true, silent = true, desc = "Prompt build and restart DAP" })
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
			local map = vim.keymap.set
			local dap = require("dap")

			map("n", "<leader>du", function()
				dapui.close()
				dap.terminate()
			end)
			dap.listeners.after.event_initialized["dapui_config"] = function()
				dapui.open()
			end

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
