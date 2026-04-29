return {
	{
		"stevearc/conform.nvim",
		event = { "BufWritePre" },
		cmd = { "ConformInfo" },
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
			-- Run on save, but only if the project actually has prettier configured
			-- (so we don't reformat files in projects that don't use it).
			format_on_save = function(bufnr)
				if vim.b[bufnr].disable_autoformat or vim.g.disable_autoformat then
					return
				end
				return { timeout_ms = 2000, lsp_format = "fallback" }
			end,
			formatters = {
				prettier = {
					-- Only run prettier if the project has it configured.
					-- This makes nvim respect each project's setup:
					-- - skips projects without prettier (no surprise reformats)
					-- - uses the project's local prettier + .prettierrc when present
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
			-- Toggle commands for opting out of format-on-save per buffer/globally
			vim.api.nvim_create_user_command("FormatDisable", function(args)
				if args.bang then
					vim.b.disable_autoformat = true
				else
					vim.g.disable_autoformat = true
				end
			end, { desc = "Disable autoformat-on-save", bang = true })

			vim.api.nvim_create_user_command("FormatEnable", function()
				vim.b.disable_autoformat = false
				vim.g.disable_autoformat = false
			end, { desc = "Re-enable autoformat-on-save" })
		end,
	},
}
