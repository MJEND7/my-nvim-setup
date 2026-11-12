return {
	{
		"stevearc/conform.nvim",
		cmd = { "ConformInfo", "Format" },
		opts = {
			formatters_by_ft = {
				javascript = { "prettier" },
				javascriptreact = { "prettier" },
				typescript = { "prettier" },
				typescriptreact = { "prettier" },
				vue = { "prettier" },
				svelte = { "prettier" },
				css = { "prettier" },
				scss = { "prettier" },
				less = { "prettier" },
				html = { "prettier" },
				json = { "prettier" },
				jsonc = { "prettier" },
				yaml = { "prettier" },
				markdown = { "prettier" },
				graphql = { "prettier" },
				cs = { "csharpier" },
				lua = { "stylua" },
				sh = { "shfmt" },
				xml = { "xmlformatter" },
			},
			formatters = {
				prettier = {
					-- Only run prettier if the project has it configured.
					condition = function(_, ctx)
						return vim.fs.find(
							{ ".prettierrc", ".prettierrc.json", ".prettierrc.js", ".prettierrc.cjs", ".prettierrc.mjs", ".prettierrc.yaml", ".prettierrc.yml", ".prettierrc.toml", "prettier.config.js", "prettier.config.cjs", "prettier.config.mjs" },
							{ upward = true, path = vim.fs.dirname(ctx.filename) }
						)[1] ~= nil
					end,
				},
			},
		},
		init = function()
			vim.api.nvim_create_user_command("Format", function(args)
				local range = nil
				if args.count ~= -1 then
					local end_line = vim.api.nvim_buf_get_lines(0, args.line2 - 1, args.line2, true)[1]
					range = {
						start = { args.line1, 0 },
						["end"] = { args.line2, end_line:len() },
					}
				end
				require("conform").format({ async = true, lsp_format = "fallback", range = range })
			end, { range = true, desc = "Run formatters on buffer or range" })
		end,
	},
}
