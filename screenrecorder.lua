
-- theme for awful.menu
local beautiful = require("beautiful")
beautiful.init("~/.config/awesome/themes/default/theme.lua")

local awful = require("awful")
local naughty = require("naughty")
local wibox = require("wibox")
local string = require("string")

local icon_path = os.getenv("HOME") .. "/pngs/camera-photo-symbolic.png"

local function select()
    local selection = awful.selection()

    local function cb_notify(self)
        local win = selection:get_selected_geometry()
	with_alsa = '-f alsa -ac 2 -i hw:1,1'
	fps = 30
	display = ':0'
	preset = 'ultrafast'
	crf = 10
	file_record = '~/record-session.mkv'
	transcode = false
	file_type = 'webm'

	cmd =   'ffmpeg -f x11grab'..
		' -s '..win.width..'x'..win.height..
		' -r '..fps..
		' -i '..display..'+'..win.x..','..win.y..
		' -c:v libx264'..
		' -preset '..preset..' -crf '..crf..
		' -y '..file_record..'&>/dev/null'
	
	awful.spawn.with_shell(cmd, false)

        -- awful.spawn.with_shell('ffmpeg -f x11grab -s "$W"x"$H" -r 60 -i :0 -c:v libx264 -preset ultrafast -crf 10 -y ~/.record-session.mkv', false)
        naughty.notification {
            font      = "Ubuntu Mono 8",
	    title     = "Recording to ~/.record-session.mkv",
            message   = "(Dx:"..win.x.." Dy:"..win.y.." - Wh:"..win.height.." Ww:"..win.width..")",
            icon      = self.surface,
            icon_size = 128,
        }
    end

    selection:connect_signal("selection::success", cb_notify)
end

local x11grab = 'ffmpeg -f x11grab -s "$W"x"$H" -r 60 -i :0+$Wx,$Wy -c:v libx264 -preset ultrafast -crf 10 -y ~/.record-session.mkv'

local mode = ""

local pmenu = awful.menu({ items = { 
                { "record mode", function() mode="screen" end },
		{ "stop record", function() awful.spawn.with_shell('pkill ffmpeg', false) end, beautiful.awesome_icon },
                { "record window", function() select() end }
        }
})

-- This is the correct way
-- local command = "sleep 1; echo foo > /tmp/foo.txt"

-- awful.spawn.easy_async_with_shell(command, function()
--    awful.spawn.easy_async_with_shell("cat /tmp/foo.txt", function(out)
--        mylabel.text = out
--    end)
-- end)

function new()
    local w = wibox.widget.imagebox(icon_path, true, nil)
    w:buttons(awful.util.table.join(
        awful.button({ }, 1, function()
	  pmenu:show()
	end)
    ))
    return w
end

return new
