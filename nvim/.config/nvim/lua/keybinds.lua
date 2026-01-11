vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Diagnostic keymaps
local function is_quickfix_open()
	local windows = vim.fn.getwininfo()
	for _, win in pairs(windows) do
		if win["quickfix"] == 1 then
			return true
		end
	end
	return false
end

local old_qf_list = {}

---@param opts? vim.diagnostic.setqflist.Opts
local function toggle_quickfix(opts)
	local curr = vim.api.nvim_get_current_win()
	local already_open = is_quickfix_open()
	vim.diagnostic.setqflist(opts)
	local qf_list = vim.fn.getqflist()
	if already_open then
		if vim.deep_equal(old_qf_list, qf_list) then
			vim.cmd.cclose()
		end
	end
	if vim.api.nvim_get_current_win() ~= curr then
		vim.api.nvim_set_current_win(curr)
	end
	old_qf_list = qf_list
end

local function toggle_qf_default()
	toggle_quickfix({})
end

local function toggle_qf_special()
	toggle_quickfix({
		severity = vim.diagnostic.severity.ERROR,
	})
end

vim.keymap.set("n", "<leader>q", toggle_qf_default, { desc = "Open diagnostic [Q]uickfix list" })
vim.keymap.set("n", "<leader>Q", toggle_qf_special, { desc = "Open diagnostic [Q]uickfix list special" })

vim.keymap.set("n", "C-q", vim.diagnostic.setqflist, { desc = "Open diagnostic [Q]uickfix list" })

vim.keymap.set("n", "<leader>o", vim.diagnostic.open_float, { desc = "[O]pen floating diagnostic" })

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
vim.keymap.set("t", "<C-n><C-n>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

vim.keymap.set("n", "<leader>w", ":w<CR>", { desc = "[W]rite" })

-- Vim config
vim.keymap.set("n", "<leader>vi", ":e ~/.config/nvim/init.lua<CR>", { desc = "Edit [Vim] [I]nit config" })
vim.keymap.set("n", "<leader>vk", ":e ~/.config/nvim/lua/keybinds.lua<CR>", { desc = "Edit [Vim] [K]eybinds config" })
vim.keymap.set("n", "<leader>vc", ":e ~/.config/nvim/lua/console.lua<CR>", { desc = "Edit [Vim] [C]onsole config" })
vim.keymap.set("n", "<leader>vo", ":e ~/.config/nvim/lua/options.lua<CR>", { desc = "Edit [Vim] [O]ptions config" })
vim.keymap.set("n", "<leader>vp", ":e ~/.config/nvim/lua/plugins<CR>", { desc = "Edit [Vim] [P]lugins" })
vim.keymap.set("n", "<leader>vl", ":e ~/.config/nvim/lua/plugins/lsp.lua<CR>", { desc = "Edit [Vim] [L]sp config" })

vim.keymap.set({ "n", "i", "v" }, "<C-p>", "<C-r>*", { desc = "Paste Default Register" })

vim.keymap.set("n", "<C-k>", "<cmd>cprev<CR>", { desc = "Move to previous item in quick fix list" })
vim.keymap.set("n", "<C-j>", "<cmd>cnext<CR>", { desc = "Move to next item in quick fix list" })

-- Start trying to use C-w C-w instead.
-- vim.keymap.set("n", "<C-h>", "<C-w><C-h>", { desc = "Move focus to the left window" })
-- vim.keymap.set("n", "<C-l>", "<C-w><C-l>", { desc = "Move focus to the right window" })
-- vim.keymap.set("n", "<C-j>", "<C-w><C-j>", { desc = "Move focus to the lower window" })
-- vim.keymap.set("n", "<C-k>", "<C-w><C-k>", { desc = "Move focus to the upper window" })

vim.keymap.set("n", "<down>", ":m .+1<CR>==") -- move line up(n)
vim.keymap.set("n", "<up>", ":m .-2<CR>==") -- move line down(n)
vim.keymap.set("v", "<down>", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "<up>", ":m '<-2<CR>gv=gv")

vim.keymap.set("n", "<leader>d", "<cmd>e todo.md<CR>", { desc = "Open to[d]o", silent = true })

-- Tabbing
vim.keymap.set("v", "<leader>r", "<cmd>'<,'>retab!<CR>", { desc = "retab", silent = true })

vim.keymap.set("v", "<S-Tab>", "<gv", { desc = "Indent left", silent = true })
vim.keymap.set("v", "<Tab>", ">gv", { desc = "Indent right", silent = true })
