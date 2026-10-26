return {
	{
		"lukas-reineke/virt-column.nvim",
		opts = {},
		event = "VimEnter",
		config = function()
			require("virt-column").setup({
				virtcolumn = "+1,80",
			})
		end,
	},
}
