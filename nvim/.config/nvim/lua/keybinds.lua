vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Diagnostic keymaps
-- vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostic [Q]uickfix list" })
vim.keymap.set("n", "<leader>q", vim.diagnostic.setqflist, { desc = "Open diagnostic [Q]uickfix list" })

local function is_quickfix_open()
	local windows = vim.fn.getwininfo()
	for _, win in pairs(windows) do
		if win["quickfix"] == 1 then
			return true
		end
	end
	return false
end

local function toggle_quickfix()
	local quickfix_open = is_quickfix_open()
	if quickfix_open then
		vim.cmd.cclose()
	else
		vim.cmd.copen()
	end
end

vim.keymap.set("n", "<Leader>tq", toggle_quickfix, { desc = "[T]oggle [Q]uickfix Window" })

vim.keymap.set("n", "C-q", vim.diagnostic.setqflist, { desc = "Open diagnostic [Q]uickfix list" })

vim.keymap.set("n", "<leader>o", vim.diagnostic.open_float, { desc = "[O]pen floating diagnostic" })

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

vim.keymap.set("n", "<leader>w", ":w<CR>", { desc = "[W]rite" })

-- Vim config
vim.keymap.set("n", "<leader>vi", ":e ~/.config/nvim/init.lua<CR>", { desc = "Edit [Vim] [I]nit config" })
vim.keymap.set("n", "<leader>vk", ":e ~/.config/nvim/lua/keybinds.lua<CR>", { desc = "Edit [Vim] [K]eybinds config" })
vim.keymap.set("n", "<leader>vc", ":e ~/.config/nvim/lua/console.lua<CR>", { desc = "Edit [Vim] [C]onsole config" })
vim.keymap.set("n", "<leader>vo", ":e ~/.config/nvim/lua/options.lua<CR>", { desc = "Edit [Vim] [O]ptions config" })
vim.keymap.set("n", "<leader>vp", ":e ~/.config/nvim/lua/plugins<CR>", { desc = "Edit [Vim] [P]lugins" })
vim.keymap.set("n", "<leader>vl", ":e ~/.config/nvim/lua/plugins/lsp.lua<CR>", { desc = "Edit [Vim] [L]sp config" })

vim.keymap.set({ "n", "i", "v" }, "<C-p>", "<C-r>*", { desc = "Paste Default Register" })

vim.keymap.set("n", "<M-k>", "<cmd>cprev<CR>", { desc = "Move to previous item in quick fix list" })
vim.keymap.set("n", "<M-j>", "<cmd>cnext<CR>", { desc = "Move to next item in quick fix list" })

-- Tabbing
vim.keymap.set("v", "<leader>r", "<cmd>'<,'>retab!<CR>", { desc = "retab", silent = true })

vim.keymap.set("v", "<S-Tab>", "<gv", { desc = "Indent left", silent = true })
vim.keymap.set("v", "<Tab>", ">gv", { desc = "Indent right", silent = true })
