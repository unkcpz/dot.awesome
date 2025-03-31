-- luacheck: globals awesome root

-- If LuaRocks is installed, make sure that packages installed through it are
-- found (e.g. lgi). If LuaRocks is not installed, do nothing.
pcall(require, "luarocks.loader")

-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
local naughty = require("naughty")
-- Notification library
local menubar = require("menubar")
local hotkeys_popup = require("awful.hotkeys_popup")
-- Enable hotkeys help widget for VIM and other apps
-- when client with a matching name is opened:
require("awful.hotkeys_popup.keys")

require("error-handling")
require("binding")

-- {{{ Variable definitions
-- Themes define colours, icons, font and wallpapers.

local themes = {
	"zenburn",
	-- "pastel",
	-- "mirage"
}
-- change this number to use the corresponding theme
local theme_config_dir = gears.filesystem.get_configuration_dir() .. "/themes/" .. themes[1] .. "/"
beautiful.init(theme_config_dir .. "/theme.lua")

-- size of notify
naughty.config.defaults.shape = function(cr, width, height)
	gears.shape.rounded_rect(cr, width, height, 2)
end

naughty.config.defaults.position = "top_right"
naughty.config.defaults.width = 280
naughty.config.defaults.height = 60
naughty.config.defaults.margin = 2
naughty.config.defaults.font = "Monospace 8"
naughty.config.defaults.icon_size = 48

-- define default apps (global variable so other components can access it)
local apps = {
	network_manager = "nm-connection-editor",
	power_manager = "xfce4-power-manager",
	terminal = "alacritty",
	launcher = "rofi -normal-window -modi drun -show drun -theme " .. theme_config_dir .. "rofi.rasi",
	lock = "betterlockscreen -l --off 10",
	screenshot = "xfce4-screenshooter",
	filebrowser = "nautilus",
	editor = "nvim-qt",
}

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
_G.modkey = "Mod4"

-- Run all the apps listed in run_on_start_up
-- List of apps to run on start-up
local run_on_start_up = {
	"unclutter",
	"udiskie",
	"xss-lock -- " .. apps.lock,
	"nm-applet",
	"blueman-applet",
}

for _, app in ipairs(run_on_start_up) do
	local findme = app
	local firstspace = app:find(" ")
	if firstspace then
		findme = app:sub(0, firstspace - 1)
	end
	-- pipe commands to bash to allow command to be shell agnostic
	awful.spawn.with_shell(
		string.format("echo 'pgrep -u $USER -x %s > /dev/null || (%s)' | bash -", findme, app),
		false
	)
end

-- Table of layouts to cover with awful.layout.inc, order matters.
-- Useless gap between windows
awful.layout.layouts = {
	awful.layout.suit.tile,
	awful.layout.suit.fair,
	awful.layout.suit.spiral.dwindle,
	awful.layout.suit.max,
	awful.layout.suit.floating,
}
-- }}}
--
local function set_wallpaper(s)
	-- Wallpaper
	if beautiful.wallpaper then
		local wallpaper = beautiful.wallpaper
		-- If wallpaper is a function, call it with the screen
		if type(wallpaper) == "function" then
			wallpaper = wallpaper(s)
		end
		gears.wallpaper.maximized(wallpaper, s, true)
	end
end

-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", set_wallpaper)

-- Menubar configuration
menubar.utils.terminal = apps.terminal -- Set the terminal for applications that require it
-- }}}

-- Keyboard map indicator and switcher
local mykeyboardlayout = awful.widget.keyboardlayout()

-- {{{ Wibar
-- Create a textclock widget
local mytextclock = wibox.widget.textclock()

-- Create a wibox for each screen and add it
local taglist_buttons = gears.table.join(
	awful.button({}, 1, function(t)
		t:view_only()
	end),
	awful.button({ modkey }, 1, function(t)
		if client.focus then
			client.focus:move_to_tag(t)
		end
	end),
	awful.button({}, 3, awful.tag.viewtoggle),
	awful.button({ modkey }, 3, function(t)
		if client.focus then
			client.focus:toggle_tag(t)
		end
	end),
	awful.button({}, 4, function(t)
		awful.tag.viewnext(t.screen)
	end),
	awful.button({}, 5, function(t)
		awful.tag.viewprev(t.screen)
	end)
)

local tasklist_buttons = gears.table.join(
	awful.button({}, 1, function(c)
		if c == client.focus then
			c.minimized = true
		else
			c:emit_signal("request::activate", "tasklist", { raise = true })
		end
	end),
	awful.button({}, 3, function()
		awful.menu.client_list({ theme = { width = 250 } })
	end),
	awful.button({}, 4, function()
		awful.client.focus.byidx(1)
	end),
	awful.button({}, 5, function()
		awful.client.focus.byidx(-1)
	end)
)

-- awesome-wm-widgets
local pacman_widget = require("widgets.pacman-widget.pacman")
local battery_widget = require("widgets.battery-widget.battery")
local ram_widget = require("widgets.ram-widget.ram-widget")
local cpu_widget = require("widgets.cpu-widget.cpu-widget")
local logout_menu_widget = require("widgets.logout-menu-widget.logout-menu")
local brightness_widget = require("widgets.brightness-widget.brightness")
local volume_widget = require("widgets.pactl-widget.volume")
local todo_widget = require("widgets.todo-widget.todo")

awful.screen.connect_for_each_screen(function(s)
	-- Wallpaper
	set_wallpaper(s)

	-- Each screen has its own tag table.
	awful.tag({ "1", "2", "3", "4", "5", "6", "7", "8", "9" }, s, awful.layout.layouts[1])

	-- Create a promptbox for each screen
	s.mypromptbox = awful.widget.prompt()
	-- Create an imagebox widget which will contain an icon indicating which layout we're using.
	-- We need one layoutbox per screen.
	s.mylayoutbox = awful.widget.layoutbox(s)
	s.mylayoutbox:buttons(gears.table.join(
		awful.button({}, 1, function()
			awful.layout.inc(1)
		end),
		awful.button({}, 3, function()
			awful.layout.inc(-1)
		end),
		awful.button({}, 4, function()
			awful.layout.inc(1)
		end),
		awful.button({}, 5, function()
			awful.layout.inc(-1)
		end)
	))
	-- Create a taglist widget
	s.mytaglist = awful.widget.taglist({
		screen = s,
		filter = awful.widget.taglist.filter.all,
		buttons = taglist_buttons,
	})

	-- Create a tasklist widget
	s.mytasklist = wibox.container.constraint(
		awful.widget.tasklist({
			screen = s,
			filter = awful.widget.tasklist.filter.currenttags,
			buttons = tasklist_buttons,
		}),
		"exact",
		1000 -- Set desired width
	)

	-- Create the wibox
	-- Set wibar height and custom width
	local bar_height = 24
	local bar_width = 1960
	s.mywibox = awful.wibar({ position = "top", screen = s, stretch = false, height = bar_height, width = bar_width })

	-- Add widgets to the wibox
	s.mywibox:setup({
		layout = wibox.layout.align.horizontal,
		{ -- Left widgets
			layout = wibox.layout.fixed.horizontal,
			-- mylauncher,
			s.mylayoutbox,
			s.mytaglist,
			s.mypromptbox,
			cpu_widget(),
			ram_widget(),
		},
		{
			layout = wibox.layout.fixed.horizontal,
			spacing = 10,
			brightness_widget({
				type = "arc",
				program = "xbacklight",
				step = 2,
				timeout = 1,
				tooltip = true,
			}),
			volume_widget({
				widget_type = "arc",
				tooltip = true,
				refresh_rate = 1,
			}),
			mykeyboardlayout,
			wibox.widget.systray(),
			battery_widget({
				show_current_level = true,
				path_to_icons = "/home/jyu/.config/awesome/icons/Arc/stats/symbolic/",
				warning_msg_icon = "/home/jyu/.config/awesome/widgets/battery-widget/spaceman.jpg",
			}),
			logout_menu_widget({
				onlock = function()
					awful.spawn.with_shell(apps.lock)
				end,
			}),
			mytextclock,
			todo_widget(),
			pacman_widget({
				interval = 600, -- Refresh every 10 minutes
				popup_bg_color = "#222222",
				popup_border_width = 1,
				popup_border_color = "#7e7e7e",
				popup_height = 10, -- 10 packages shown in scrollable window
				popup_width = 300,
				polkit_agent_path = "/usr/bin/lxpolkit",
			}),
		},
		{
			layout = wibox.layout.fixed.horizontal,
			wibox.widget.textbox(" "), -- Spacer (optional)
			s.mytasklist,
		},
	})
end)
-- }}}

-- {{{ Key bindings
globalkeys = gears.table.join(
	awful.key({ modkey }, "s", hotkeys_popup.show_help, { description = "show help", group = "awesome" }),
	awful.key({ modkey }, "Left", awful.tag.viewprev, { description = "view previous", group = "tag" }),
	awful.key({ modkey }, "Right", awful.tag.viewnext, { description = "view next", group = "tag" }),
	awful.key({ modkey }, "Escape", awful.tag.history.restore, { description = "go back", group = "tag" }),

	awful.key({ modkey }, "h", function()
		awful.client.focus.byidx(1)
	end, { description = "focus next by index", group = "client" }),
	awful.key({ modkey }, "l", function()
		awful.client.focus.byidx(-1)
	end, { description = "focus previous by index", group = "client" }),
	awful.key({ modkey }, "w", function()
		mymainmenu:show()
	end, { description = "show main menu", group = "awesome" }),

	-- =========================================
	-- FUNCTION KEYS
	-- =========================================

	-- Brightness
	awful.key({}, "XF86MonBrightnessUp", function()
		awful.spawn("xbacklight -inc 10", false)
	end, { description = "+10%", group = "hotkeys" }),
	awful.key({}, "XF86MonBrightnessDown", function()
		awful.spawn("xbacklight -dec 10", false)
	end, { description = "-10%", group = "hotkeys" }),

	-- volume
	awful.key({}, "XF86AudioLowerVolume", function()
		awful.util.spawn("amixer -q -D pulse sset Master 5%-", false)
	end),
	awful.key({}, "XF86AudioRaiseVolume", function()
		awful.util.spawn("amixer -q -D pulse sset Master 5%+", false)
	end),
	awful.key({}, "XF86AudioMute", function()
		awful.util.spawn("amixer -D pulse set Master 1+ toggle", false)
	end),

	-- toggle touchpad
	awful.key({ modkey }, "F11", function()
		awful.util.spawn(os.getenv("HOME") .. "/.config/awesome/scripts/toggle-touchpad.sh", false)
	end),

	-- Layout manipulation
	awful.key({ modkey, "Shift" }, "h", function()
		awful.client.swap.byidx(1)
	end, { description = "swap with next client by index", group = "client" }),
	awful.key({ modkey, "Shift" }, "l", function()
		awful.client.swap.byidx(-1)
	end, { description = "swap with previous client by index", group = "client" }),
	awful.key({ modkey, "Control" }, "j", function()
		awful.screen.focus_relative(1)
	end, { description = "focus the next screen", group = "screen" }),
	awful.key({ modkey, "Control" }, "k", function()
		awful.screen.focus_relative(-1)
	end, { description = "focus the previous screen", group = "screen" }),
	awful.key({ modkey }, "u", awful.client.urgent.jumpto, { description = "jump to urgent client", group = "client" }),
	awful.key({ modkey }, "Tab", function()
		awful.client.focus.history.previous()
		if client.focus then
			client.focus:raise()
		end
	end, { description = "go back", group = "client" }),

	awful.key({ modkey }, "space", function()
		awful.layout.inc(1)
	end, { description = "select next", group = "layout" }),
	awful.key({ modkey, "Shift" }, "space", function()
		awful.layout.inc(-1)
	end, { description = "select previous", group = "layout" }),

	-- =========================================
	-- RELOAD / QUIT AWESOME
	-- =========================================

	-- Reload Awesome
	awful.key({ modkey, "Shift" }, "r", awesome.restart, { description = "reload awesome", group = "awesome" }),
	-- Quit
	awful.key({ modkey, "Shift" }, "Delete", awesome.quit, { description = "quite awesome", group = "awesome" }),

	-- Quit Awesome
	awful.key({ modkey }, "Escape", function()
		-- emit signal to show the exit screen
		awesome.quit()
	end, { description = "toggle exit screen", group = "hotkeys" }),
	--
	-- awful.key({}, "XF86PowerOff", function()
	-- 	-- emit signal to show the exit screen
	-- 	awesome.emit_signal("show_exit_screen")
	-- end, { description = "toggle exit screen", group = "hotkeys" }),

	-- =========================================
	-- WINDOWS RESIZE AND REARRANGE
	-- =========================================

	-- Window scale and rearrange
	awful.key({ modkey }, "j", function()
		awful.tag.incmwfact(-0.05)
	end, { description = "decrease master width factor", group = "layout" }),
	awful.key({ modkey }, "k", function()
		awful.tag.incmwfact(0.05)
	end, { description = "increase master width factor", group = "layout" }),
	awful.key({ modkey, "Shift" }, "j", function()
		awful.client.incwfact(-0.05)
	end, { description = "increase master height factor", group = "layout" }),
	awful.key({ modkey, "Shift" }, "k", function()
		awful.client.incwfact(0.05)
	end, { description = "decrease master height factor", group = "layout" }),
	awful.key({ modkey, "Control" }, "j", function()
		awful.tag.incncol(1, nil, true)
	end, { description = "increase the number of columns", group = "layout" }),
	awful.key({ modkey, "Control" }, "k", function()
		awful.tag.incncol(-1, nil, true)
	end, { description = "decrease the number of columns", group = "layout" }),

	awful.key({ modkey, "Control" }, "n", function()
		local c = awful.client.restore()
		-- Focus restored client
		if c then
			c:emit_signal("request::activate", "key.unminimize", { raise = true })
		end
	end, { description = "restore minimized", group = "client" }),

	-- Prompt
	awful.key({ modkey }, "r", function()
		awful.screen.focused().mypromptbox:run()
	end, { description = "run prompt", group = "launcher" }),

	awful.key({ modkey }, "x", function()
		awful.prompt.run({
			prompt = "Run Lua code: ",
			textbox = awful.screen.focused().mypromptbox.widget,
			exe_callback = awful.util.eval,
			history_path = awful.util.get_cache_dir() .. "/history_eval",
		})
	end, { description = "lua execute prompt", group = "awesome" }),

	awful.key({ modkey }, "'", function()
		awful.spawn.easy_async_with_shell("xclip -o -selection clipboard", function(stdout)
			local yy = stdout:gsub("\n", "")
			naughty.notify({ text = yy, timeout = 2 })
		end)
	end, { description = "Inspect xclip", group = "custom" }),

	-- Menubar
	awful.key({ modkey }, "p", function()
		menubar.show()
	end, { description = "show the menubar", group = "launcher" }),

	-- =========================================
	-- SPAWN APPLICATION KEY BINDINGS
	-- =========================================

	-- Spawn terminal
	awful.key({ modkey }, "Return", function()
		awful.spawn(apps.terminal)
	end, { description = "open a terminal", group = "launcher" }),
	awful.key({ modkey, "Shift" }, "Return", function()
		-- Ensure the layout is set to "tabbed"
		local t = awful.screen.focused().selected_tag
		if t and t.layout ~= awful.layout.suit.tabbed then
			awful.layout.set(awful.layout.suit.tabbed)
		end
		-- Spawn the terminal
		awful.spawn(apps.terminal)
	end, { description = "open a terminal in tabbed mode", group = "launcher" }),

	-- launch rofi
	awful.key({ modkey }, "d", function()
		awful.spawn(apps.launcher)
	end, { description = "application launcher", group = "launcher" }),

	-- Screenshot on prtscn using scrot
	awful.key({}, "Print", function()
		awful.util.spawn(apps.screenshot, false)
	end)
)

clientkeys = gears.table.join(
	awful.key({ modkey }, "f", function(c)
		c.fullscreen = not c.fullscreen
		c:raise()
	end, { description = "toggle fullscreen", group = "client" }),

	awful.key({ modkey, "Shift" }, "y", function()
		awful.spawn.easy_async_with_shell("xclip -o -selection clipboard", function(stdout)
			local url = stdout:gsub("\n", "")
			if url:match("^https?://") then
				naughty.notify({ text = "rendering " .. url .. "to mpv", timeout = 4 })
				awful.spawn("mpv --geometry=1280x720 --no-border '" .. url .. "'")
			else
				naughty.notify({ text = "No valid URL found!", timeout = 2 })
			end
		end)
	end, { description = "Open clipboard URL in mpv", group = "custom" }),

	awful.key({ modkey, "Shift" }, "c", function(c)
		c:kill()
	end, { description = "close", group = "client" }),
	awful.key(
		{ modkey, "Shift" },
		"t",
		awful.client.floating.toggle,
		{ description = "toggle floating", group = "client" }
	),
	awful.key({ modkey, "Shift" }, "Return", function(c)
		c:swap(awful.client.getmaster())
	end, { description = "move to master", group = "client" }),
	awful.key({ modkey }, "period", function(c)
		c:move_to_screen()
	end, { description = "move to screen", group = "client" }),
	awful.key({ modkey }, "t", function(c)
		c.ontop = not c.ontop
	end, { description = "toggle keep on top", group = "client" }),
	awful.key({ modkey }, "n", function(c)
		-- The client currently has the input focus, so it cannot be
		-- minimized, since minimized clients can't have the focus.
		c.minimized = true
	end, { description = "minimize", group = "client" }),
	awful.key({ modkey }, "m", function(c)
		c.maximized = not c.maximized
		c:raise()
	end, { description = "(un)maximize", group = "client" }),
	awful.key({ modkey, "Control" }, "m", function(c)
		c.maximized_vertical = not c.maximized_vertical
		c:raise()
	end, { description = "(un)maximize vertically", group = "client" }),
	awful.key({ modkey, "Shift" }, "m", function(c)
		c.maximized_horizontal = not c.maximized_horizontal
		c:raise()
	end, { description = "(un)maximize horizontally", group = "client" })
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it work on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
	globalkeys = gears.table.join(
		globalkeys,
		-- View tag only.
		awful.key({ modkey }, "#" .. i + 9, function()
			local screen = awful.screen.focused()
			local tag = screen.tags[i]
			if tag then
				tag:view_only()
			end
		end, { description = "view tag #" .. i, group = "tag" }),
		-- Toggle tag display.
		awful.key({ modkey, "Control" }, "#" .. i + 9, function()
			local screen = awful.screen.focused()
			local tag = screen.tags[i]
			if tag then
				awful.tag.viewtoggle(tag)
			end
		end, { description = "toggle tag #" .. i, group = "tag" }),
		-- Move client to tag.
		awful.key({ modkey, "Shift" }, "#" .. i + 9, function()
			if client.focus then
				local tag = client.focus.screen.tags[i]
				if tag then
					client.focus:move_to_tag(tag)
				end
			end
		end, { description = "move focused client to tag #" .. i, group = "tag" }),
		-- Toggle tag on focused client.
		awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9, function()
			if client.focus then
				local tag = client.focus.screen.tags[i]
				if tag then
					client.focus:toggle_tag(tag)
				end
			end
		end, { description = "toggle focused client on tag #" .. i, group = "tag" })
	)
end

-- Set keys
root.keys(globalkeys)
-- }}}

clientbuttons = gears.table.join(
	awful.button({}, 1, function(c)
		c:emit_signal("request::activate", "mouse_click", { raise = true })
	end),
	awful.button({ modkey }, 1, function(c)
		c:emit_signal("request::activate", "mouse_click", { raise = true })
		awful.mouse.client.move(c)
	end),
	awful.button({ modkey }, 3, function(c)
		c:emit_signal("request::activate", "mouse_click", { raise = true })
		awful.mouse.client.resize(c)
	end)
)

require("rules")
require("signals")
