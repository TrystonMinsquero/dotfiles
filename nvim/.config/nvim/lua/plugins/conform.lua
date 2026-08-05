return {
	{ -- Autoformat
		"stevearc/conform.nvim",
		event = {},
		cmd = { "ConformInfo" },
		keys = {
			{
				"<leader>f",
				function()
					require("conform").format({ async = true, lsp_format = "fallback" })
				end,
				mode = "",
				desc = "[F]ormat buffer",
			},
		},
		opts = {
			notify_on_error = true,
			format_on_save = function(bufnr)
				-- Disable "format_on_save lsp_fallback" for languages that don't
				-- have a well standardized coding style. You can add additional
				-- languages here or re-enable it for the disabled ones.
				local enable_filestypes = { go = true }
				if not enable_filestypes[vim.bo[bufnr].filetype] then
					return nil
				else
					return {
						timeout_ms = 500,
						lsp_format = "fallback",
					}
				end
			end,
			-- See all using :help conform-formatters
			formatters_by_ft = {
				lua = { "stylua" },
				markdown = { "mdformat" },
				-- Conform can also run multiple formatters sequentially
				-- python = { "isort", "black" },
				--
				-- You can use 'stop_after_first' to run the first available formatter from the list
				-- javascript = { "prettierd", "prettier", stop_after_first = true },
			},
		},
		config = function(_, opts)
			require("conform").setup(opts)
			vim.api.nvim_create_user_command("AddFormatter", function (args)
				-- require("conform").formatters_by_ft	
			end, {})
		end
	},
}
