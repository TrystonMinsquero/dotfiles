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
config.font = wezterm.font("Iosevka Term Medium")
-- config.font = wezterm.font("JetBrains Mono Regular")
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

local function find_other_pane(pane)
	for _, other_pane in ipairs(pane:tab():panes()) do
		if other_pane:pane_id() ~= pane:pane_id() then
			return other_pane
		end
	end
	return nil
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
		mods = "CTRL|ALT",
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
		key = "v",
		mods = "CTRL|ALT",
		action = act.SplitPane({
			direction = "Right",
			size = { Percent = 50 },
		}),
	},
	{
		key = "%",
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

-- config.window_decorations = "INTEGRATED_BUTTONS | RESIZE"
config.window_decorations = "NONE | RESIZE"
if wezterm.target_triple:find("windows") then
	config.default_prog = { "powershell.exe", "-NoLogo" }
	config.default_domain = "WSL:Ubuntu"
end

config.initial_cols = 80

-- and finally, return the configuration to wezterm
return config
