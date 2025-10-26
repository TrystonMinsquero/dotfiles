return {
	{
		"xiyaowong/transparent.nvim",
		config = function()
			vim.keymap.set("n", "<leader>to", "<cmd>TransparentToggle<CR>", { desc = "[T]oggle [O]pacity" })
		end,
	},
}
