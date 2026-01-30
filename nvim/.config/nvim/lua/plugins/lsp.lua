return {
	{
		-- Main LSP Configuration
		"neovim/nvim-lspconfig",
		dependencies = {
			-- Automatically install LSPs and related tools to stdpath for Neovim
			-- Mason must be loaded before its dependents so we need to set it up here.
			-- NOTE: `opts = {}` is the same as calling `require('mason').setup({})`
			{ "mason-org/mason.nvim", opts = {} },
			"mason-org/mason-lspconfig.nvim",
			"WhoIsSethDaniel/mason-tool-installer.nvim",

			-- Useful status updates for LSP.
			{ "j-hui/fidget.nvim", opts = {} },

			-- Allows extra capabilities provided by blink.cmp
			"saghen/blink.cmp",
		},
		config = function()
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
				callback = function(event)
					local map = function(keys, func, desc, mode)
						mode = mode or "n"
						vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
					end

					-- Rename the variable under your cursor.
					--  Most Language Servers support renaming across files, etc.
					map("<leader>ln", vim.lsp.buf.rename, "[R]e[n]ame")

					-- Execute a code action, usually your cursor needs to be on top of an error
					-- or a suggestion from your LSP for this to activate.
					map("<leader>la", vim.lsp.buf.code_action, "[G]oto Code [A]ction", { "n", "x" })
					map("<leader>a", vim.lsp.buf.code_action, "[G]oto Code [A]ction", { "n", "x" })

					map("<leader>lh", vim.lsp.buf.hover, "Show [h]over")
					map("K", vim.lsp.buf.hover, "Show [h]over")
					map("<leader>ls", "<cmd>LspClangdSwitchSourceHeader<CR>", "[S]witch Source Header")
					map("<C-h>", "<cmd>LspClangdSwitchSourceHeader<CR>", "Switch Source [H]eader")

					-- Find references for the word under your cursor.
					map("<leader>lr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")
					map("gr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")
					map("<C-c>", require("telescope.builtin").lsp_references, "Show [C]allers")

					-- Jump to the implementation of the word under your cursor.
					--  Useful when your language has ways of declaring types without an actual implementation.
					map("<leader>li", require("telescope.builtin").lsp_implementations, "[G]oto [I]mplementation")

					-- Jump to the definition of the word under your cursor.
					--  This is where a variable was first declared, or where a function is defined, etc.
					--  To jump back, press <C-t>.
					map("<leader>ld", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")
					map("gd", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")

					-- WARN: This is not Goto Definition, this is Goto Declaration.
					--  For example, in C this would take you to the header.
					map("<leader>lD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")

					-- Fuzzy find all the symbols in your current document.
					--  Symbols are things like variables, functions, types, etc.
					--  Doing both to see which one I like more
					map(
						"<leader>sS",
						require("telescope.builtin").lsp_document_symbols,
						"[S]earch [S]ymbols in current buffer"
					)
					map(
						"<leader>sb",
						require("telescope.builtin").lsp_document_symbols,
						"[S]earch symbols in current [B]uffer"
					)

					-- Fuzzy find all the symbols in your current workspace.
					--  Similar to document symbols, except searches over your entire project.
					map(
						"<leader>ss",
						require("telescope.builtin").lsp_dynamic_workspace_symbols,
						"[S]earch [S]ymbols in workspace"
					)

					-- Jump to the type of the word under your cursor.
					--  Useful when you're not sure what type a variable is and you want to see
					--  the definition of its *type*, not where it was *defined*.
					map("<leader>lt", require("telescope.builtin").lsp_type_definitions, "[G]oto [T]ype Definition")
					map("<leader>gt", require("telescope.builtin").lsp_type_definitions, "[G]oto [T]ype Definition")

					-- This function resolves a difference between neovim nightly (version 0.11) and stable (version 0.10)
					---@param client vim.lsp.Client
					---@param method vim.lsp.protocol.Method
					---@param bufnr? integer some lsp support methods only in specific files
					---@return boolean
					local function client_supports_method(client, method, bufnr)
						if vim.fn.has("nvim-0.11") == 1 then
							return client:supports_method(method, bufnr)
						else
							return client.supports_method(method, { bufnr = bufnr })
						end
					end

					local client = vim.lsp.get_client_by_id(event.data.client_id)

					if
						client
						and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf)
					then
						map("<leader>th", function()
							vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }))
						end, "[T]oggle Inlay [H]ints")
					end
				end,
			})

			-- Diagnostic Config
			-- See :help vim.diagnostic.Opts
			vim.diagnostic.config({
				severity_sort = true,
				float = { border = "rounded", source = "if_many" },
				underline = { severity = vim.diagnostic.severity.ERROR },
				signs = vim.g.have_nerd_font and {
					text = {
						[vim.diagnostic.severity.ERROR] = "󰅚 ",
						[vim.diagnostic.severity.WARN] = "󰀪 ",
						[vim.diagnostic.severity.INFO] = "󰋽 ",
						[vim.diagnostic.severity.HINT] = "󰌶 ",
					},
				} or {},
				virtual_text = {
					source = "if_many",
					spacing = 2,
					format = function(diagnostic)
						local diagnostic_message = {
							[vim.diagnostic.severity.ERROR] = diagnostic.message,
							[vim.diagnostic.severity.WARN] = diagnostic.message,
							[vim.diagnostic.severity.INFO] = diagnostic.message,
							[vim.diagnostic.severity.HINT] = diagnostic.message,
						}
						return diagnostic_message[diagnostic.severity]
					end,
				},
			})

			-- LSP servers and clients are able to communicate to each other what features they support.
			--  By default, Neovim doesn't support everything that is in the LSP specification.
			--  When you add blink.cmp, luasnip, etc. Neovim now has *more* capabilities.
			--  So, we create new capabilities with blink.cmp, and then broadcast that to the servers.
			local capabilities = require("blink.cmp").get_lsp_capabilities()

			--  Add any additional override configuration in the following tables. Available keys are:
			--  - cmd (table): Override the default command used to start the server
			--  - filetypes (table): Override the default list of associated filetypes for the server
			--  - capabilities (table): Override fields in capabilities. Can be used to disable certain LSP features.
			--  - settings (table): Override the default settings passed when initializing the server.
			--				For example, to see the options for `lua_ls`, you could go to: https://luals.github.io/wiki/settings/
			-- etc. See `:help lspconfig-all` for a list of all the pre-configured LSPs
			local servers = {
				-- clangd = {},
				gopls = {},
				harper_ls = {
					filetypes = {
						"markdown",
						"md",
					},
				},
				pyrefly = {},

				lua_ls = {
					on_attach = function(_, bufnr)
						vim.bo[bufnr].sw = 4
						vim.bo[bufnr].ts = 4
						vim.bo[bufnr].expandtab = false
					end,
					settings = {
						-- Info: https://luals.github.io/wiki/settings/
						Lua = {
							completion = {
								callSnippet = "Replace",
							},
							-- You can toggle below to ignore Lua_LS's noisy `missing-fields` warnings
							-- diagnostics = { disable = { 'missing-fields' } },
						},
					},
				},
			} -- Ensure the servers and tools above are installed

			local ensure_installed = vim.tbl_keys(servers or {})
			vim.list_extend(ensure_installed, {
				"stylua", -- Used to format Lua code
			})
			require("mason-tool-installer").setup({ ensure_installed = ensure_installed })

			require("mason-lspconfig").setup({
				ensure_installed = {}, -- explicitly set to an empty table (Kickstart populates installs via mason-tool-installer)
				automatic_installation = false,
			})

			-- Setup configs for lsps
			for key, value in pairs(servers) do
				if vim.fn.has("nvim-0.11") == 1 then
					vim.lsp.config(key, value)
				else
					require("lspconfig")[key].setup(value)
				end
			end

			local function toggle_spell_check()
				local clients = vim.lsp.get_clients({ name = "harper_ls", bufnr = 0 })
				if #clients <= 0 then
					vim.lsp.start({ name = "harper_ls", cmd = { "harper-ls", "--stdio" } }, { bufnr = 0 })
				else
					assert(#clients == 1)
					vim.lsp.buf_detach_client(0, clients[1].id)
				end
			end
			vim.keymap.set("n", "<leader>ts", toggle_spell_check, { desc = "[T]oggle [S]pellcheck" })
		end,
	},
}
