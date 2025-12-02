# awesomeWM.lib

Storage offshore 😸 and to share, naturally 🙂

## This works with awesome devel version

#### selection.lua => /usr/share/awesome/lib/awful/selection.lua => awful.selection()

#### screenrecorder.lua => ~/.config/awesome/screenrecorder.lua

rc.lua
```lua
local screenrecorder = require("screenrecorder")
myscreenrecorder = screenrecorder()
-- now put the widget inside the taskbar...
```

I need find a way to grab display from lua instead using default

I need find a way to select soundcard instead using default

It works but I want a better interface and hide abstraction into a new module with everything embedded ```/usr/share/awesome/lib/awful/screencast.lua```

Also I want to move this ```/usr/share/awesome/lib/awful/selection.lua``` that I scrapped from ```/usr/share/awesome/lib/awful/screenshot.lua``` into ```/usr/share/awesome/lib/awful/mouse/selection.lua``` and swap all selection need to that last 😸

# I never record my screen though

Should I? 😙
