---------------------------------------------------------------------------
-- @author Brian Sobulefsky &lt;brian.sobulefsky@protonmail.com&gt;
-- @copyright 2021 Brian Sobulefsky
-- @copyright 2025 HackIT
-- @classmod awful.selection
---------------------------------------------------------------------------

-- Grab environment we need
local capi = {
    mousegrabber = mousegrabber
}

local gears     = require("gears")
local beautiful = require("beautiful")
local wibox     = require("wibox")
local abutton   = require("awful.button")

-- The module to be returned
local module = { mt = {}, _selection_methods = {} }
local selection_validation = {}

--- The screenshot interactive frame color.
-- @beautiful beautiful.screenshot_frame_color
-- @tparam[opt="#ff0000"] color screenshot_frame_color

--- The screenshot interactive frame shape.
-- @beautiful beautiful.screenshot_frame_shape
-- @tparam[opt=gears.shape.rectangle] shape screenshot_frame_shape

local function show_frame(self)
    local col = self._private.frame_color
          or beautiful.screenshot_frame_color
          or "#ff0000"

    local w, h = root.size()

    self._private.selection_widget = wibox.widget {
        border_width  = 2,
        border_color  = col,
        shape         = gears.shape.rectangle,
        color         = "transparent",
        visible       = false,
        widget        = wibox.widget.separator
    }
    
    self._private.selection_widget.point = {x=0, y=0}
    self._private.selection_widget.fit = function() return 0,0 end

    self._private.canvas_widget = wibox.widget {
        widget = wibox.layout.manual
    }

    self._private.canvas_widget:add(self._private.selection_widget)
    
    self._private.frame = wibox {
        ontop   = true,
        x       = 0,
        y       = 0,
	width   = w,
        height  = h,
	bg      = "transparent",
	widget  = self._private.canvas_widget,
        visible = true,
    }
end

-- The interactive tool is basically a mousegrabber, which takes a single function
-- of one argument, representing the mouse state data.
local function start_snipping(self)
    self._private.mg_first_pnt = {}

    local accept_buttons, reject_buttons = {}, {}

    for _, btn in ipairs(self.accept_buttons) do
        accept_buttons[btn.button] = true
    end
    for _, btn in ipairs(self.reject_buttons) do
        reject_buttons[btn.button] = true
    end

    local pressed = false

    show_frame(self)

    local function ret_mg_callback(mouse_data, accept, reject)
        for btn, status in pairs(mouse_data.buttons) do
            accept = accept or (status and accept_buttons[btn])
            reject = reject or (status and reject_buttons[btn])
        end

        if reject then
            self:reject("mouse_button")
            return false
        elseif pressed then
            local min_x = math.min(self._private.mg_first_pnt[1], mouse_data.x)
            local max_x = math.max(self._private.mg_first_pnt[1], mouse_data.x)
            local min_y = math.min(self._private.mg_first_pnt[2], mouse_data.y)
            local max_y = math.max(self._private.mg_first_pnt[2], mouse_data.y)

            self._private.selected_geometry = {
                x       = min_x,
                y       = min_y,
                width   = max_x - min_x,
                height  = max_y - min_y,
                method  = method,
                surface = surface,
            }
            self:emit_signal("property::selected_geometry", self._private.selected_geometry)

            if not accept then
                -- Released
                return self:accept()
            else
                -- Update position
                self._private.selection_widget.point.x = min_x
                self._private.selection_widget.point.y = min_y
                self._private.selection_widget.fit = function()
                    return self._private.selected_geometry.width, self._private.selected_geometry.height
                end
                self._private.selection_widget:emit_signal("widget::layout_changed")
                self._private.canvas_widget:emit_signal("widget::redraw_needed")
            end
        elseif accept then
            pressed = true
            self._private.selection_widget.visible = true
            self._private.selection_widget.point.x = mouse_data.x
            self._private.selection_widget.point.y = mouse_data.y
            self._private.mg_first_pnt[1] = mouse_data.x
            self._private.mg_first_pnt[2] = mouse_data.y
        end

        return true
    end

    capi.mousegrabber.run(ret_mg_callback, self.cursor)
    self:emit_signal("selection::start")
end

local defaults = {
    cursor                  = "crosshair",
    reject_buttons          = {abutton({}, 3)},
    accept_buttons          = {abutton({}, 1)},
    minimum_size            = {width = 3, height = 3}
}

-- Create the standard properties.
for _, prop in ipairs { "frame_color", "reject_buttons", 
                        "accept_buttons", "cursor",
                        "minimum_size" } do
    module["set_"..prop] = function(self, value)
        self._private[prop] = selection_validation[prop]
            and selection_validation[prop](value) or value
        self:emit_signal("property::"..prop, value)
    end

    module["get_"..prop] = function(self)
        return self._private[prop] or defaults[prop]
    end
end

function module:get_selected_geometry()
    return self._private.selected_geometry
end

function module:set_minimum_size(size)
    if size and type(size) ~= "table" then
        size = {width = math.ceil(size), height = math.ceil(size)}
    end
    self._private.minimum_size = size
    self:emit_signal("property::minimum_size", size)
end

function module:refresh()
    start_snipping(self)
end

function module:accept()
    local new_geo = self._private.selected_geometry
    local min_size = self.minimum_size

    if not new_geo then
        self:reject("no_selection")
        return false
    end

    -- This may fail gracefully anyway but require a minimum 3x3 of pixels
    if min_size and new_geo.width < min_size.width or  new_geo.height < min_size.height then
        self:reject("too_small")
        return false
    end
    
    self:emit_signal("selection::success")

    self._private.selection_widget.visible = false
    self._private.frame.visible = false
    self._private.frame, self._private.mg_first_pnt = nil, nil
    
    capi.mousegrabber.stop()

    return true
end

function module:reject(reason)
    if self._private.frame then
        self._private.frame.visible = false
        self._private.frame = nil
    end
    self._private.mg_first_pnt = nil
    self:emit_signal("selection::cancelled", reason or "reject_called")
    capi.mousegrabber.stop()
end

-- @constructorfct awful.selection
-- @tparam[opt={}] table args

local function new(_, args)
    args = (type(args) == "table" and args) or {}
    local self = gears.object({
        enable_auto_signals = true,
        enable_properties   = true
    })

    self._private = {}
    gears.table.crush(self, module, true)
    gears.table.crush(self, args)

    self:refresh()

    return self
end

return setmetatable(module, {__call = new})
-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
