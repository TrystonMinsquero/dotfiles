-- Pull in the wezterm API
local wezterm = require("wezterm")
local act = wezterm.action
-- local mux = wezterm.mux
-- This will hold the configuration.
local config = wezterm.config_builder()
-- local gpus = wezterm.gui.enumerate_gpus()
-- config.webgpu_preferred_adapter = gpus[1]
-- config.front_end = "WebGpu"

config.front_end = "OpenGL"
config.max_fps = 144
config.default_cursor_style = "BlinkingBlock"
config.animation_fps = 1
config.cursor_blink_rate = 500
config.term = "xterm-256color" -- Set the terminal type

config.cell_width = 0.9

local opacity = 0.75 -- Value is also used for toggling
local opacity_inc = 0.05 -- increment
config.window_background_opacity = opacity
config.prefer_egl = true
config.font_size = 16.0
config.audible_bell = "Disabled"

config.window_padding = {
	left = 0,
	right = 0,
	top = 0,
	bottom = 0,
}

-- tabs
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = true
-- config.tab_bar_at_bottom = true

-- config.inactive_pane_hsb = {
-- 	saturation = 0.0,
-- 	brightness = 1.0,
-- }

-- This is where you actually apply your config choices
--

local CURSOR_MOD = wezterm.target_triple:find("apple") and "ALT" or "CTRL"

-- Makes it convenient for window managers
wezterm.on("format-window-title", function(tab, pan, tabs, panes, config)
	return "Wezterm"
end)

-- keymaps

wezterm.global_key_assignments = {
	[{ modifiers = "CTRL|SHIFT", key = "N" }] = act.DisableDefaultAssignment,
}

-- Equivalent to POSIX basename(3)
-- Given "/foo/bar" returns "bar"
-- Given "c:\\foo\\bar" returns "bar"
---@param s string
---@return string
local function basename(s)
	return string.gsub(s, "(.*[/\\])(.*)", "%2")
end

---@param path string file path to expand
---@param home_path string? home path to expand ~
---@param cwd string? current working directory to always convert to absolute path
---@return string
local function canonicalizePath(path, home_path, cwd)
	-- 1. Standardize all incoming separators to forward slashes
	path = path:gsub("\\", "/")
	if home_path then
		home_path = home_path:gsub("\\", "/")
	end
	if cwd then
		cwd = cwd:gsub("\\", "/")
	end

	-- 2. Expand Tilde (~) if home_path is provided
	if home_path and path:sub(1, 1) == "~" then
		if home_path:sub(-1) == "/" then
			home_path = home_path:sub(1, -2)
		end
		if path == "~" then
			path = home_path
		elseif path:sub(2, 2) == "/" then
			path = home_path .. path:sub(2)
		end
	end

	-- 3. Prepend cwd if path is relative and cwd is provided
	local is_absolute = path:sub(1, 1) == "/"
	if not is_absolute and cwd then
		if cwd:sub(-1) == "/" then
			cwd = cwd:sub(1, -2)
		end
		path = cwd .. "/" .. path
		is_absolute = true -- Path is now absolute because it stems from cwd
	end

	-- 4. Tokenize and resolve '.' and '..'
	local parts = {}
	for part in path:gmatch("([^/]+)") do
		if part == ".." then
			if #parts > 0 and parts[#parts] ~= ".." then
				table.remove(parts)
			elseif not is_absolute then
				table.insert(parts, "..")
			end
		elseif part ~= "." then
			table.insert(parts, part)
		end
	end

	-- 5. Reconstruct final string
	local result = table.concat(parts, "/")
	if is_absolute then
		result = "/" .. result
	end

	return result == "" and "." or result
end

--- Get base name of current foreground program
---@param pane Pane
---@return string
local function pane_prog(pane)
	return basename(pane:get_foreground_process_name())
end

---@param pane Pane Current pane, will check this first then others in the same tab
---@param prog string the base name of the program you're looking for
---@return Pane?
local function find_pane_using(pane, prog)
	prog = basename(prog)
	if pane_prog(pane) == prog then
		return pane
	end
	for _, other_pane in ipairs(pane:tab():panes()) do
		-- wezterm.log_info("Pane ", other_pane:pane_id(), " = ", other_pane:get_foreground_process_name())
		if pane_prog(other_pane) == prog then
			return other_pane
		end
	end
	return nil
end

local function find_other_pane(pane)
	for _, other_pane in ipairs(pane:tab():panes()) do
		if other_pane:pane_id() ~= pane:pane_id() then
			return other_pane
		end
	end
	return nil
end

local function toast(window, msg)
	wezterm.log_warn(msg) -- also in the debug overlay/log, in case notifications are off
	window:toast_notification("WezTerm", msg, nil, 4000)
end

-- Foreground programs we can safely type a command into
local SHELLS = { [""] = true, zsh = true, bash = true, fish = true, sh = true, nu = true }

---A pane in this tab that's idle at a shell prompt: the current pane if it is, else another.
---@param pane Pane
---@return Pane?
local function find_shell_pane(pane)
	if SHELLS[pane_prog(pane)] then
		return pane
	end
	for _, p in ipairs(pane:tab():panes()) do
		if p:pane_id() ~= pane:pane_id() and SHELLS[pane_prog(p)] then
			return p
		end
	end
	return nil
end

---Single-quote a string for POSIX shells
local function shell_quote(s)
	return "'" .. s:gsub("'", "'\\''") .. "'"
end

---Open file_path at line_num in an nvim pane of this tab. If there is none, start nvim
---in a pane that's idle at a shell (current one first), otherwise in a new split.
---@param window Window
---@param pane Pane
---@param file_path string absolute path
---@param line_num number|string|nil
local function open_in_nvim(window, pane, file_path, line_num)
	line_num = math.max(tonumber(line_num) or 1, 1)
	local nvim_pane = find_pane_using(pane, "nvim")
	if nvim_pane then
		if nvim_pane:pane_id() ~= pane:pane_id() then
			nvim_pane:activate()
		end
		local cmd = ":e +" .. line_num .. " " .. file_path:gsub("([ %%#|\\])", "\\%1")
		wezterm.log_info("Ran nvim cmd |", cmd)
		nvim_pane:send_text("\x1b" .. cmd .. "\r")
		return
	end

	local cmd = "nvim +" .. line_num .. " " .. shell_quote(file_path)
	local shell_pane = find_shell_pane(pane)
	if shell_pane then
		wezterm.log_info("Ran cmd in pane", shell_pane:pane_id(), "|", cmd)
		shell_pane:activate()
		shell_pane:send_text("\x15" .. cmd .. "\r") -- ctrl+u clears the prompt first
	else
		-- e.g. Claude Code / another TUI is in the foreground: don't type into it
		wezterm.log_info("Split with cmd |", cmd)
		pane:split({
			direction = "Right",
			args = { os.getenv("SHELL") or "sh", "-lc", cmd },
		})
	end
end

-- Marker that tools (e.g. Claude Code) put in front of things to open with CTRL|ALT+e
local OPEN_PREFIX = "⟫"

---Figure out what `text` is and open it: URLs go to the browser, anything else is
---treated as `path[:line[:col]]` and opened in nvim.
---@param window Window
---@param pane Pane
---@param text string
local function open_target(window, pane, text)
	local raw = text
	if text:sub(1, #OPEN_PREFIX) == OPEN_PREFIX then
		text = text:sub(#OPEN_PREFIX + 1)
	end
	-- Trim whitespace and surrounding quotes/brackets/punctuation
	text = text:gsub("^%s+", ""):gsub("^[`'\"%(%[<]+", ""):gsub("[`'\"%)%]>%.,;:!?]+$", "")

	if text:match("^%a[%w+.-]*://") and not text:match("^file://") then
		wezterm.log_info("opening url: " .. text)
		wezterm.open_with(text)
		return
	end

	text = text:gsub("^file://", "")
	local file_path, line_num = text:match("^(.-):(%d+):%d+$")
	if not file_path then
		file_path, line_num = text:match("^(.-):(%d+)$")
	end
	file_path = file_path or text
	if file_path == "" then
		toast(window, "Nothing to open in:\n" .. raw)
		return
	end

	local cwdUrl = pane:get_current_working_dir()
	file_path = canonicalizePath(file_path, wezterm.home_dir, cwdUrl and cwdUrl.file_path)
	local f = io.open(file_path, "r")
	if not f then
		toast(window, "File not found:\n" .. file_path)
		return
	end
	f:close()
	open_in_nvim(window, pane, file_path, line_num)
end

-- Closing marker. Lets a target survive being hard-wrapped by TUIs like Claude Code,
-- which insert real newlines + indentation instead of letting the terminal soft-wrap.
local OPEN_SUFFIX = "⟪"
-- How many lines of scrollback CTRL|ALT+e scans
local SCAN_LINES = 2000
-- Most lines a ⟫ ... ⟪ target may wrap onto. A ⟪ further away than this belongs to
-- something else, so the ⟫ is treated as unterminated (stops at end of line/word).
local MAX_TARGET_LINES = 4

---Turn the text between the markers into {kind, value}, undoing line wrapping.
---  `$ cmd`        -> cmd  (wrapped pieces joined with a space, since TUIs wrap at spaces)
---  `scheme://...` -> url  (pieces joined with nothing)
---  anything else  -> file (pieces joined with nothing)
---@param body string
---@return {kind: string, value: string}?
local function parse_target(body)
	local pieces = {}
	for line in body:gmatch("[^\n]+") do
		line = line:gsub("^%s+", ""):gsub("%s+$", "")
		if line ~= "" then
			table.insert(pieces, line)
		end
	end
	if #pieces == 0 then
		return nil
	end
	local first = pieces[1]:gsub("^`+", "")
	pieces[1] = first
	if first:sub(1, 1) == "$" then
		pieces[1] = first:sub(2)
		local cmd = table.concat(pieces, " "):gsub("^%s+", ""):gsub("[%s`]+$", "")
		return cmd ~= "" and { kind = "cmd", value = cmd } or nil
	end
	local value = table.concat(pieces, ""):gsub("^[`'\"%(%[<]+", ""):gsub("[`'\"%)%]>%.,;:!?]+$", "")
	return { kind = value:match("^%a[%w+.-]*://") and "url" or "file", value = value }
end

local function trim(s)
	return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

---Find every ⟫ ... ⟪ target in the pane's scrollback, newest first.
---A ⟫ with no ⟪ before the next ⟫ just runs to the end of its line.
---Each target also gets `fragment`: the text QuickSelect would have matched on its
---first line, used to map a QuickSelect pick back to the full (possibly wrapped) target.
---@param pane Pane
local function collect_targets(pane)
	local text = pane:get_logical_lines_as_text(SCAN_LINES)
	local found = {}
	local pos = 1
	while true do
		local s, e = text:find(OPEN_PREFIX, pos, true)
		if not e then
			break
		end
		local next_open = text:find(OPEN_PREFIX, e + 1, true)
		local close = text:find(OPEN_SUFFIX, e + 1, true)
		local line_end = text:find("\n", e + 1, true) or #text + 1
		local frag_end = math.min(line_end, next_open or #text + 1) - 1
		if close and close < line_end and (not next_open or close < next_open) then
			frag_end = close + #OPEN_SUFFIX - 1
		end
		local fragment = trim(text:sub(s, frag_end))
		local body
		if
			close
			and (not next_open or close < next_open)
			and select(2, text:sub(e + 1, close - 1):gsub("\n", "")) < MAX_TARGET_LINES
		then
			body = text:sub(e + 1, close - 1)
			pos = close + #OPEN_SUFFIX
		else
			-- Unterminated: a `$ cmd` takes the rest of the line, a url/file the next word
			body = text:sub(e + 1, (next_open or #text + 1) - 1):match("^[^\n]*")
			if not body:match("^%s*`?%$") then
				body = body:match("^%s*(%S*)")
			end
			pos = e + 1
		end
		local target = parse_target(body)
		if target then
			target.fragment = fragment
			table.insert(found, 1, target)
		end
	end
	return found
end

---Type cmd into a shell pane in this tab (the current one if it's a shell, else another,
---else a new split), and copy it to the clipboard.
---@param window Window
---@param pane Pane
---@param cmd string
---@param run boolean? also press Enter
local function run_command(window, pane, cmd, run)
	window:copy_to_clipboard(cmd, "Clipboard")
	local target = find_shell_pane(pane)
	local text = cmd .. (run and "\r" or "")
	wezterm.log_info(run and "Running cmd |" or "Sending cmd |", cmd)
	if target then
		target:send_text("\x15" .. text) -- ctrl+u clears the prompt first
	else
		local cwdUrl = pane:get_current_working_dir()
		target = pane:split({ direction = "Bottom", cwd = cwdUrl and cwdUrl.file_path })
		target:send_text(text)
	end
	-- Typed only: focus the shell so you can edit/confirm. Run: stay where you were.
	if run then
		pane:activate()
	else
		target:activate()
	end
end

---QuickSelect a ⟫ target and open it. QuickSelect only matches within a line, so it
---labels the first line of a target; the full target is recovered from scrollback.
---@param run boolean press Enter after typing a `$ cmd` target
local function smart_open(run)
	return act.QuickSelectArgs({
		label = run and "open/run" or "open",
		patterns = { OPEN_PREFIX .. "[^" .. OPEN_PREFIX .. OPEN_SUFFIX .. "\\n]*" .. OPEN_SUFFIX .. "?" },
		action = wezterm.action_callback(function(window, pane)
			local selection = trim(window:get_selection_text_for_pane(pane))
			local target
			for _, t in ipairs(collect_targets(pane)) do -- newest first
				if t.fragment == selection then
					target = t
					break
				end
			end
			if not target then -- fall back to just what was selected
				target = parse_target((selection:sub(#OPEN_PREFIX + 1):gsub(OPEN_SUFFIX .. "$", "")))
			end
			if not target then
				toast(window, "Nothing to open in:\n" .. selection)
			elseif target.kind == "cmd" then
				run_command(window, pane, target.value, run)
			else
				open_target(window, pane, target.value)
			end
		end),
	})
end

config.keys = { -- Navigate Splits
	{
		key = "h",
		mods = "CTRL|ALT",
		action = act.ActivatePaneDirection("Left"),
	},
	{
		key = "j",
		mods = "CTRL|ALT",
		action = act.ActivatePaneDirection("Down"),
	},
	{
		key = "k",
		mods = "CTRL|ALT",
		action = act.ActivatePaneDirection("Up"),
	},
	{
		key = "l",
		mods = "CTRL|ALT",
		action = act.ActivatePaneDirection("Right"),
	},
	-- Adjust Split Sizes
	{
		key = "h",
		mods = "CTRL|ALT|SHIFT",
		action = act.AdjustPaneSize({ "Left", 5 }),
	},
	{
		key = "j",
		mods = "CTRL|ALT|SHIFT",
		action = act.AdjustPaneSize({ "Down", 5 }),
	},
	{
		key = "k",
		mods = "CTRL|ALT|SHIFT",
		action = act.AdjustPaneSize({ "Up", 5 }),
	},
	{
		key = "l",
		mods = "CTRL|ALT|SHIFT",
		action = act.AdjustPaneSize({ "Right", 5 }),
	},
	-- Workspace Management
	{
		key = "s",
		mods = "CTRL|ALT|SHIFT",
		action = act.ShowLauncherArgs({
			flags = "FUZZY|WORKSPACES",
		}),
	},
	{
		key = "c",
		mods = "CTRL|ALT",
		action = act.PromptInputLine({
			description = wezterm.format({
				{ Attribute = { Intensity = "Bold" } },
				{ Foreground = { AnsiColor = "Fuchsia" } },
				{ Text = "Enter name for new workspace" },
			}),
			action = wezterm.action_callback(function(window, pane, line)
				-- line will be `nil` if they hit escape without entering anything
				-- An empty string if they just hit enter
				-- Or the actual line of text they wrote
				if line then
					window:perform_action(
						act.SwitchToWorkspace({
							name = line,
						}),
						pane
					)
				end
			end),
		}),
	},
	-- Pane Management
	{
		key = "|",
		mods = "CTRL|ALT",
		action = act.SplitPane({
			direction = "Right",
			size = { Percent = 50 },
		}),
	},
	{
		key = "s",
		mods = "CTRL|ALT",
		action = act.SplitPane({
			direction = "Down",
			size = { Percent = 50 },
		}),
	},
	{
		key = "v",
		mods = "CTRL|ALT",
		action = act.SplitPane({
			direction = "Right",
			size = { Percent = 50 },
		}),
	},
	{
		key = "w",
		mods = "CTRL|ALT",
		action = act.CloseCurrentPane({ confirm = true }),
	},
	-- Tab Management
	{
		key = "N",
		mods = "CTRL|ALT",
		action = act.DisableDefaultAssignment,
	},
	{
		key = "t",
		mods = "CTRL|ALT",
		action = act.SpawnTab("CurrentPaneDomain"),
	},
	{ key = "0", mods = "CTRL|ALT", action = act.ActivateTab(-1) },
	{ key = "1", mods = "CTRL|ALT", action = act.ActivateTab(0) },
	{ key = "2", mods = "CTRL|ALT", action = act.ActivateTab(1) },
	{ key = "3", mods = "CTRL|ALT", action = act.ActivateTab(2) },
	{ key = "4", mods = "CTRL|ALT", action = act.ActivateTab(3) },
	{ key = "5", mods = "CTRL|ALT", action = act.ActivateTab(4) },
	{ key = "6", mods = "CTRL|ALT", action = act.ActivateTab(5) },
	{ key = "7", mods = "CTRL|ALT", action = act.ActivateTab(6) },
	{ key = "8", mods = "CTRL|ALT", action = act.ActivateTab(7) },
	{ key = "9", mods = "CTRL|ALT", action = act.ActivateTab(8) },
	{
		key = "p",
		mods = "CTRL|ALT",
		action = act.ActivateCommandPalette,
	},
	{ -- Rename Current Tab
		key = ",",
		mods = "CTRL|ALT",
		action = act.PromptInputLine({
			description = wezterm.format({
				{ Attribute = { Intensity = "Bold" } },
				{ Foreground = { AnsiColor = "Fuchsia" } },
				{ Text = "Enter name for the current tab" },
			}),
			action = wezterm.action_callback(function(window, _, line)
				-- line will be `nil` if they hit escape without entering anything
				-- An empty string if they just hit enter
				-- Or the actual line of text they wrote
				if line then
					window:active_tab():set_title(line)
				end
			end),
		}),
	},
	{
		key = "q",
		mods = "CTRL|ALT|SHIFT",
		action = act.QuitApplication,
	},
	-- Scroll
	{ key = "PageUp", action = act.DisableDefaultAssignment },
	{ key = "PageDown", action = act.DisableDefaultAssignment },
	{ key = "PageUp", action = act.ScrollByPage(-0.5) },
	{ key = "PageDown", action = act.ScrollByPage(0.5) },
	{ key = "u", mods = "CTRL|ALT", action = act.ScrollByPage(-0.5) },
	{ key = "d", mods = "CTRL|ALT", action = act.ScrollByPage(0.5) },
	{ key = "PageUp", mods = "SHIFT", action = act.ScrollByPage(-1.0) },
	{ key = "PageDown", mods = "SHIFT", action = act.ScrollByPage(1.0) },
	-- Copy Mode
	{ key = "y", mods = "CTRL|ALT", action = act.ActivateCopyMode },
	{
		key = "g",
		mods = "CTRL|ALT",
		action = wezterm.action.QuickSelectArgs({
			label = "open url",
			patterns = {
				"https?://\\S+",
			},
			action = wezterm.action_callback(function(window, pane)
				local url = window:get_selection_text_for_pane(pane)
				wezterm.log_info("opening: " .. url)
				wezterm.open_with(url)
			end),
		}),
	},
	{
		key = "f",
		mods = "CTRL|ALT",
		action = act.QuickSelectArgs({
			label = "open file",
			patterns = {
				[=[[a-zA-Z0-9_.\/~-]+:\d+]=],
			},
			action = wezterm.action_callback(function(window, pane)
				open_target(window, pane, window:get_selection_text_for_pane(pane))
			end),
		}),
	},
	-- Smart open: pick a `⟫ target ⟪` from scrollback (URL -> browser, path[:line] -> nvim, $ cmd -> shell)
	{ key = "e", mods = "CTRL|ALT", action = smart_open(false) },
	-- Same, but `$ cmd` targets are run (Enter pressed) instead of just typed
	{ key = "e", mods = "CTRL|ALT|SHIFT", action = smart_open(true) },
	{ key = "g", mods = "CTRL", action = act.OpenLinkAtMouseCursor },
	-- Find
	{ key = "/", mods = "CTRL|ALT", action = act.Search("CurrentSelectionOrEmptyString") },
	{
		key = "o",
		mods = "CTRL|ALT",
		-- toggling opacity
		action = wezterm.action_callback(function(window, _)
			local overrides = window:get_config_overrides() or {}
			if overrides.window_background_opacity == 1.0 then
				overrides.window_background_opacity = opacity
			else
				overrides.window_background_opacity = 1.0
			end
			window:set_config_overrides(overrides)
		end),
	},
	{
		key = "o",
		mods = "CTRL|ALT|SHIFT",
		-- toggling opacity
		action = wezterm.action_callback(function(window, _)
			local overrides = window:get_config_overrides() or {}
			local o = math.max(0, overrides.window_background_opacity - opacity_inc)
			overrides.window_background_opacity = o
			window:set_config_overrides(overrides)
		end),
	},
	{
		key = "i",
		mods = "CTRL|ALT|SHIFT",
		-- toggling opacity
		action = wezterm.action_callback(function(window, _)
			local overrides = window:get_config_overrides() or {}
			local o = math.min(1, overrides.window_background_opacity + opacity_inc)
			overrides.window_background_opacity = o
			window:set_config_overrides(overrides)
		end),
	},
	-- Sane rebindings
	{
		key = "Backspace",
		mods = CURSOR_MOD,
		action = wezterm.action.SendKey({ key = "w", mods = "CTRL" }),
	},
	{ -- delete word forward
		key = "Delete",
		mods = CURSOR_MOD,
		action = wezterm.action.SendKey({ key = "d", mods = "ALT" }),
	},
	{
		key = "LeftArrow",
		mods = CURSOR_MOD,
		action = act.SendKey({
			key = "b",
			mods = "ALT",
		}),
	},
	{
		key = "RightArrow",
		mods = CURSOR_MOD,
		action = act.SendKey({ key = "f", mods = "ALT" }),
	},
	{
		key = "r",
		mods = "CTRL|ALT|SHIFT",
		action = wezterm.action_callback(function(win, pane)
			local other_pane = find_other_pane(pane)
			if other_pane then
				win:perform_action(act.SendKey({ key = "c", mods = "CTRL" }), other_pane)
				win:perform_action(act.SendKey({ key = "UpArrow" }), other_pane)
				other_pane:activate()
			end
		end),
	},
	{
		key = "r",
		mods = "CTRL|ALT",
		action = wezterm.action_callback(function(win, pane)
			local other_pane = find_other_pane(pane)
			if other_pane then
				win:perform_action(act.SendKey({ key = "c", mods = "CTRL" }), other_pane)
				win:perform_action(act.SendKey({ key = "UpArrow" }), other_pane)
				win:perform_action(act.SendKey({ key = "Enter" }), other_pane)
			end
		end),
	},
}

if wezterm.gui then
	-- local copy_mode = wezterm.gui.default_key_tables().copy_mode
	-- local copy_mode_extensions = {
	-- 	{ key = "g", mods = "CTRL", action = "OpenLinkAtMouseCursor" },
	-- 	{ key = "g", mods = "CTRL|ALT", action = "OpenLinkAtMouseCursor" },
	-- }
	-- for _, key_bind in ipairs(copy_mode_extensions) do
	-- 	table.insert(copy_mode, key_bind)
	-- end
	-- config.key_tables.copy_mode = copy_mode
end

-- For example, changing the color scheme:
config.color_scheme = "Tokyo Night Moon"
config.colors = {
	background = "#181616", -- vague.nvim bg
	-- background = "#080808", -- almost black
	-- background = "#0c0b0f", -- dark purple
	-- background = "#222436", -- tokyonight-moon.nvim bg
	-- background = "#020202", -- dark purple
	-- background = "#17151c", -- brighter purple
	-- background = "#16141a",
	-- background = "#0e0e12", -- bright washed lavendar
	-- background = 'rgba(59, 34, 76, 100%)',
	cursor_border = "#bea3c7",
	-- cursor_fg = "#281733",
	cursor_bg = "#bea3c7",
	-- selection_fg = '#281733',

	tab_bar = {
		background = "#181616",
		-- background = "rgba(0, 0, 0, 0%)",
		active_tab = {
			bg_color = "#0c0b0f",
			fg_color = "#bea3c7",
			intensity = "Normal",
			underline = "None",
			italic = false,
			strikethrough = false,
		},
		inactive_tab = {
			bg_color = "#0c0b0f",
			fg_color = "#f8f2f5",
			intensity = "Normal",
			underline = "None",
			italic = false,
			strikethrough = false,
		},

		new_tab = {
			-- bg_color = "rgba(59, 34, 76, 50%)",
			bg_color = "#0c0b0f",
			fg_color = "white",
		},
	},
}

config.window_frame = {
	font = wezterm.font("JetBrains Mono"),
	active_titlebar_bg = "#0c0b0f",
	-- active_titlebar_bg = "#181616",
}

if wezterm.target_triple:find("windows") then
	config.default_prog = { "powershell.exe", "-NoLogo" }
	config.default_domain = "WSL:Ubuntu"
end

config.initial_cols = 80

-- and finally, return the configuration to wezterm
return config
