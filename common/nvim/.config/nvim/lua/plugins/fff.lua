return {
	{
		-- https://github.com/dmtrKovalenko/fff#fffnvim
		"dmtrKovalenko/fff.nvim",
		build = function()
			-- downloads a prebuilt binary or falls back to cargo build
			require("fff.download").download_or_build_binary()
		end,
		-- for nixos:
		-- build = "nix run .#release",
		opts = {
			debug = {
				enabled = true,
				show_scores = true,
			},
		},
		lazy = false, -- the plugin lazy-initialises itself
		keys = {
			{
				"<leader>ff",
				function()
					require("fff").find_files()
				end,
				desc = "FFFind files",
			},
			{
				"<leader>fg",
				function()
					require("fff").live_grep()
				end,
				desc = "LiFFFe grep",
			},
			{
				"<leader>fz",
				function()
					require("fff").live_grep({ grep = { modes = { "fuzzy", "plain" } } })
				end,
				desc = "Live fffuzy grep",
			},
			{
				"<leader>fr",
				function()
					require("fff").resume()
				end,
				desc = "Resume last fff finder",
			},
			{
				"<leader>fw",
				function()
					require("fff").live_grep_under_cursor()
				end,
				mode = { "n", "x" },
				desc = "Search current word / selection",
			},
		},
	},
}
