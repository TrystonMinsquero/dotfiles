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

-- config.font = wezterm.font("Iosevka Custom")
-- config.font = wezterm.font("Monocraft Nerd Font")
-- config.font = wezterm.font("FiraCode Nerd Font Mono")
config.font = wezterm.font("JetBrains Mono Regular")
config.cell_width = 0.9
-- config.font = wezterm.font("Menlo Regular")
-- config.font = wezterm.font("Hasklig")
-- config.font = wezterm.font("Monoid Retina")
-- config.font = wezterm.font("InputMonoNarrow")
-- config.font = wezterm.font("mononoki Regular")
-- config.font = wezterm.font("Iosevka")
-- config.font = wezterm.font("M+ 1m")
-- config.font = wezterm.font("Hack Regular")
-- config.cell_width = 0.9

local opacity = 0.75 -- Value is also used for toggling
config.window_background_opacity = opacity
config.prefer_egl = true
config.font_size = 14.0

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

-- color scheme toggling
wezterm.on("toggle-colorscheme", function(window, pane)
	local overrides = window:get_config_overrides() or {}
	if overrides.color_scheme == "Zenburn" then
		overrides.color_scheme = "Cloud (terminal.sexy)"
	else
		overrides.color_scheme = "Zenburn"
	end
	window:set_config_overrides(overrides)
end)

-- keymaps

wezterm.global_key_assignments = {
	[{ modifiers = "CTRL|SHIFT", key = "N" }] = act.DisableDefaultAssignment,
}

local tmux_super = { key = "s", mods = "CTRL" }
local tmux_act = function(key)
	-- return act.Multiple({
	-- 	act.SendKey(tmux_super),
	-- 	act.SendKey({ key = key }),
	-- })
	return wezterm.action_callback(function(win, pane)
		win:perform_action(act.SendKey(tmux_super), pane)
		wezterm.sleep_ms(100)
		win:perform_action(act.SendKey({ key = key }), pane)
	end)
end
local tmux_key = function(key, destKey)
	if destKey == nil then
		destKey = key
	end
	return { key = key, mods = "CTRL|ALT", action = tmux_act(destKey) }
end

local tmux_keys = {
	tmux_key("0"),
	tmux_key("1"),
	tmux_key("2"),
	tmux_key("3"),
	tmux_key("4"),
	tmux_key("5"),
	tmux_key("6"),
	tmux_key("7"),
	tmux_key("8"),
	tmux_key("9"),

	tmux_key("LeftArrow"),
	tmux_key("DownArrow"),
	tmux_key("UpArrow"),
	tmux_key("RightArrow"),

	tmux_key("h", "LeftArrow"),
	tmux_key("j", "DownArrow"),
	tmux_key("k", "UpArrow"),
	tmux_key("l", "RightArrow"),

	tmux_key("%"),
	tmux_key("v", "%"), -- vert split
	tmux_key('"'),
	tmux_key("s", "%"),

	tmux_key("$"), -- rename session
	-- tmux_key("n", "$"), -- rename session
	tmux_key(","), -- rename window

	tmux_key("p"),
	tmux_key("n"),
	tmux_key("i", "n"),
	tmux_key("o", "p"),
	tmux_key("x"), -- kill pane

	tmux_key("d"), -- detach
}

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
	-- Pane Management
	-- Commented out in replacement of tmux
	-- {
	-- 	key = "d",
	-- 	mods = "CTRL|ALT",
	-- 	action = act.SplitPane({
	-- 		direction = "Right",
	-- 		size = { Percent = 50 },
	-- 	}),
	-- },
	-- {
	-- 	key = "t",
	-- 	mods = "CTRL|ALT",
	-- 	action = act.SplitPane({
	-- 		direction = "Right",
	-- 		size = { Percent = 50 },
	-- 	}),
	-- },
	-- {
	-- 	key = "w",
	-- 	mods = "CTRL|ALT",
	-- 	action = act.CloseCurrentPane({ confirm = true }),
	-- },
	-- Tab Management
	{
		key = "N",
		mods = "CTRL|SHIFT",
		action = act.DisableDefaultAssignment,
	},
	{
		key = "t",
		mods = "CTRL",
		action = act.SpawnTab("CurrentPaneDomain"),
	},
	{
		key = "q",
		mods = "CTRL|ALT",
		action = act.QuitApplication,
	},
	-- Scroll
	{ key = "PageUp", action = act.DisableDefaultAssignment },
	{ key = "PageDown", action = act.DisableDefaultAssignment },
	{ key = "PageUp", action = act.ScrollByPage(-0.5) },
	{ key = "PageDown", action = act.ScrollByPage(0.5) },
	{ key = "PageUp", mods = "SHIFT", action = act.ScrollByPage(-1.0) },
	{ key = "PageDown", mods = "SHIFT", action = act.ScrollByPage(1.0) },
	{
		key = "s",
		mods = "SHIFT|CTRL|ALT",
		action = wezterm.action_callback(function(window, _)
			local overrides = window:get_config_overrides() or {}
			overrides.scroll_to_bottom_on_input = not overrides.scroll_to_bottom_on_input
			window:set_config_overrides(overrides)
		end),
	},
	-- Copy Mode
	{ key = "y", mods = "CTRL|ALT", action = act.ActivateCopyMode },
	-- Find
	{ key = "/", mods = "CTRL|ALT", action = act.Search("CurrentSelectionOrEmptyString") },
	-- Idk This was here
	{ key = "9", mods = "CTRL", action = act.PaneSelect },
	{ key = "L", mods = "CTRL", action = act.ShowDebugOverlay },
	{
		key = "o",
		mods = "SHIFT|CTRL|ALT",
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
		key = "Backspace",
		mods = wezterm.target_triple:find("apple") and "ALT" or "CTRL",
		action = wezterm.action.SendKey({ key = "w", mods = "CTRL" }),
	},
}

for i = 1, #config.keys do
	table.insert(config.keys, tmux_keys[i])
end

-- For example, changing the color scheme:
config.color_scheme = "Cloud (terminal.sexy)"
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
		background = "#0c0b0f",
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

-- config.window_decorations = "INTEGRATED_BUTTONS | RESIZE"
config.window_decorations = "NONE | RESIZE"
if wezterm.target_triple:find("windows") then
	print("windows!")
	config.default_prog = { "powershell.exe", "-NoLogo" }
	config.default_domain = "WSL:Ubuntu"
end

config.initial_cols = 80
-- config.window_background_image = "C:/dev/misc/berk.png"
-- config.window_background_image_hsb = {
-- 	brightness = 0.1,
-- }

-- wezterm.on("gui-startup", function(cmd)
-- 	local args = {}
-- 	if cmd then
-- 		args = cmd.args
-- 	end
--
-- 	local tab, pane, window = mux.spawn_window(cmd or {})
-- 	-- window:gui_window():maximize()
-- 	-- window:gui_window():set_position(0, 0)
-- end)

-- and finally, return the configuration to wezterm
return config
