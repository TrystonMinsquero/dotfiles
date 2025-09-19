vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Diagnostic keymaps
-- vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostic [Q]uickfix list" })
vim.keymap.set("n", "<leader>q", vim.diagnostic.setqflist, { desc = "Open diagnostic [Q]uickfix list" })
vim.keymap.set("n", "<leader>o", vim.diagnostic.open_float,
  { desc = "[O]pen floating diagnostic"})

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- Ctrl+S as god intended
vim.keymap.set("n", "<C-s>", "<cmd>:w<CR>")

vim.api.nvim_create_user_command("E", "Explore", {})
vim.keymap.set("n", "<leader>e", ":Explore<CR>", { desc = "[E]xplore"})

vim.keymap.set("n", "<leader>w", ":w<CR>", { desc = "[W]rite"})
vim.keymap.set("n", "<leader>v", ":e $MYVIMRC<CR>", { desc = "Edit [Vim] config"})

-- vim.keymap.set("n", "<left>", "<C-w><C-h>", { desc = "Move focus to the left window" })
-- vim.keymap.set("n", "<down>", "<C-w><C-j>", { desc = "Move focus to the lower window" })
-- vim.keymap.set("n", "<up>", "<C-w><C-k>", { desc = "Move focus to the upper window" })
-- vim.keymap.set("n", "<right", "<C-w><C-l>", { desc = "Move focus to the right window" })
--
vim.keymap.set("n", "<C-h>", "<C-w><C-h>", { desc = "Move focus to the left window" })
vim.keymap.set("n", "<C-l>", "<C-w><C-l>", { desc = "Move focus to the right window" })
vim.keymap.set("n", "<C-j>", "<C-w><C-j>", { desc = "Move focus to the lower window" })
vim.keymap.set("n", "<C-k>", "<C-w><C-k>", { desc = "Move focus to the upper window" })

