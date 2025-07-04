-- Standard awesome library
local awful = require("awful")
require("awful.autofocus")
-- Theme handling library
local beautiful = require("beautiful")

-- define screen height and width
local screen_height = awful.screen.focused().geometry.height
local screen_width = awful.screen.focused().geometry.width

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
	-- All clients will match this rule.
	{
		rule = {},
		properties = {
			border_width = beautiful.border_width,
			border_color = beautiful.border_focus,
			focus = awful.client.focus.filter,
			raise = true,
			keys = clientkeys,
			buttons = clientbuttons,
			screen = awful.screen.preferred,
			placement = awful.placement.no_overlap + awful.placement.no_offscreen,
		},
	},

	-- Floating clients.
	{
		rule_any = {
			instance = {
				"DTA", -- Firefox addon DownThemAll.
				"copyq", -- Includes session name in class.
				"pinentry",
			},
			class = {
				"Arandr",
				"Blueman-manager",
				"Gpick",
				"Kruler",
				"MessageWin", -- kalarm.
				"Sxiv",
				"Tor Browser", -- Needs a fixed window size to avoid fingerprinting by screen size.
				"Wpa_gui",
				"veromix",
				"xtightvncviewer",
				"pavucontrol",
			},

			-- Note that the name property shown in xprop might be set slightly after creation of the client
			-- and the name shown there might not match defined rules here.
			name = {
				"Event Tester", -- xev.
			},
			role = {
				"AlarmWindow", -- Thunderbird's calendar.
				"ConfigManager", -- Thunderbird's about:config.
				"pop-up", -- e.g. Google Chrome's (detached) Developer Tools.
			},
		},
		properties = { floating = true, width = screen_width * 0.55, height = screen_height * 0.45 },
	},

	-- Add titlebars to normal clients and dialogs
	{ rule_any = { type = { "normal", "dialog" } }, properties = { titlebars_enabled = false } },

	-- "Switch to tag"
	-- These clients make you switch to their tag when they appear
	{
		rule_any = {
			class = {
				"firefox",
			},
		},
		properties = { switchtotag = true, maximized = false },
	},

	-- rofi rule
	{
		rule_any = { name = { "rofi" } },
		properties = {
			maximized = true,
			floating = true,
			titlebars_enabled = false,
		},
		callback = function(c)
			local hpadding = 160
			local vpadding = 140
			-- Set geometry with padding (adjust values as needed)
			c:geometry({
				x = hpadding, -- Left padding
				y = vpadding, -- Top padding
				width = c.screen.workarea.width - 2 * hpadding, -- Screen width minus padding
				height = c.screen.workarea.height - 2 * vpadding, -- Screen height minus padding
			})
		end,
	},

	-- File chooser dialog
	{
		rule_any = { role = { "GtkFileChooserDialog" }, class = { "org.gnome.Nautilus" } },
		properties = { floating = true, width = screen_width * 0.55, height = screen_height * 0.65 },
	},
}
-- }}}
