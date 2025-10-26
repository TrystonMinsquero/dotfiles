return {
	{
		"mbbill/undotree",
		event = "VimEnter",
		config = function()
			vim.keymap.set("n", "<leader>u", "<cmd>UndotreeToggle<CR><C-w><C-h>", { desc = "[U]ndo Tree Toggle" })
		end,
	},
}
