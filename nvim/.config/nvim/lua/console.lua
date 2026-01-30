local function is_term_buff(bufnr)
	local buf_name = vim.api.nvim_buf_get_name(bufnr)
	if buf_name then
		if buf_name:match("term:") then
			return true
		end
	end
	return false
end

local function find_term_buff()
	for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(bufnr) then
			if is_term_buff(bufnr) then
				return bufnr
			end
		end
	end
	return -1
end

local function find_term_win()
	for _, winnr in ipairs(vim.api.nvim_list_wins()) do
		if is_term_buff(vim.api.nvim_win_get_buf(winnr)) then
			return winnr
		end
	end
	return -1
end

local function type_keys(key_str)
	local keys = vim.api.nvim_replace_termcodes(key_str, true, true, true)
	vim.api.nvim_feedkeys(keys, "n", false)
end

local function open_terminal()
	local term_buff = find_term_buff()
	if term_buff >= 0 then
		local term_win = find_term_win()
		if term_win >= 0 then
			vim.api.nvim_set_current_win(term_win)
		else
			vim.cmd("vsplit | term")
			term_win = find_term_win()
			vim.api.nvim_set_current_win(term_win)
		end
	else
		vim.cmd("vsplit | term")
		local term_win = find_term_win()
		vim.api.nvim_set_current_win(term_win)
	end
end

local function enter_terminal()
	open_terminal()
	type_keys("A")
end

local function run_terminal_command(command)
	-- local curr_win = vim.api.nvim_get_current_win()
	open_terminal()
	type_keys("<C-c><up>" .. command .. "<CR>")
	-- vim.api.nvim_set_current_win(curr_win)
end

vim.keymap.set("n", "<leader>k", function()
	run_terminal_command("zig build -Dtarget=x86_64-windows-gnu run")
end, { desc = "Run last command in terminal" })

local function run_last_command()
	local curr_win = vim.api.nvim_get_current_win()
	open_terminal()
	type_keys("A<C-c><up><up><CR><C-\\><C-n>G")
	vim.schedule(function()
		vim.api.nvim_set_current_win(curr_win)
	end)
end

local function type_last_command()
	open_terminal()
	type_keys("A<C-c><up><up>")
end

vim.keymap.set("n", "<leader>r", function()
	vim.cmd.write({ "%", bang = true })
	run_last_command()
end, { desc = "[R]un last" })

vim.keymap.set("n", "<leader>cl", type_last_command, { desc = "[C]onsole run [L]ast" })

vim.keymap.set("n", "<leader>co", enter_terminal, { desc = "[C]onsole [O]pen" })
