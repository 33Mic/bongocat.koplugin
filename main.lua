local Dispatcher = require("dispatcher")  -- luacheck:ignore
local Device = require("device")
local Geom = require("ui/geometry")
local InfoMessage = require("ui/widget/infomessage")
local UIManager = require("ui/uimanager")
local InputContainer = require("ui/widget/container/inputcontainer")
local Input = Device.input
local Screen = Device.screen
local GestureRange = require("ui/gesturerange")
local logger = require("logger")
local TextWidget = require("ui/widget/textwidget")
local Font = require("ui/font")
local VerticalSpan = require("ui/widget/verticalspan")
local ImageWidget = require("ui/widget/imagewidget")
local Blitbuffer = require("ffi/blitbuffer")
local Button = require("ui/widget/button")
local CenterContainer = require("ui/widget/container/centercontainer")
local FrameContainer = require("ui/widget/container/framecontainer")
local VerticalGroup = require("ui/widget/verticalgroup")

local _ = require("gettext")

local PLUGIN_IMAGES = "plugins/bongocat.koplugin/images/"

local BongoCat = InputContainer:new{
    name = "BongoCat",
    is_doc_only = false,
    dimen = Screen:getSize(),
}

function BongoCat:onDispatcherRegisterActions()
    Dispatcher:registerAction("bongocat_action", {category="none", event="BongoCat", title=_("BongoCat"), general=true,})
end

function BongoCat:init()
    self:onDispatcherRegisterActions()
    self.ui.menu:registerToMainMenu(self)

    if Device:hasKeys() then
        self.key_events.AnyKeyPressed = { { Input.group.Any } }
    end
    if Device:isTouchDevice() then
        self.ges_events.Hold = {
            GestureRange:new{
                ges = "touch",
                range = Geom:new{ x = 0, y = 0, w = Screen:getWidth(), h = Screen:getHeight() }
            }
        }
        self.ges_events.HoldRelease = {
            GestureRange:new{
                ges = "tap",
                range = Geom:new{ x = 0, y = 0, w = Screen:getWidth(), h = Screen:getHeight() }
            }
        }
    end
end

--
function BongoCat:addToMainMenu(menu_items)
    menu_items.BongoCat_plugin = {
        text = _("BongoCat Plugin"),
        -- in which menu this should be appended
        sorting_hint = "tools",
        -- a callback when tapping
        callback = function()
            -- BongoCat:onBongoCatPlugin()
            BongoCat:showBongoCat()
        end,
    }
end

function BongoCat:onBongoCatPlugin()
    local popup = InfoMessage:new{
        text = _("BongoCatPlugin"),
    }
    UIManager:show(popup)
end

function BongoCat:_getFileName()
    local supported_files = {"png", "svg", "jpg", "jpeg"}
    local img_names = {"bongo", "bongolr"}
    local track = 0
    self.file_names = {}

    for _, extension in ipairs(supported_files) do
        for _, img in ipairs(img_names) do
            local filename = PLUGIN_IMAGES .. img .. "." .. extension

            logger.dbg("trying to open " .. filename)

            local f=io.open(filename,"r")
            if f~=nil then io.close(f)
                self.file_names[track] = filename
                track = track + 1
                -- return filename
            end
        end
        if track == 2 then
            return self.file_names
        end
    end

    return "resources/koreader.svg"
end

function BongoCat:showBongoCat()
    logger.dbg("Showing cat")

    BongoCat:_getFileName()

    self.exit_button = Button:new {
        text = _("Exit"),
        callback = function()
            BongoCat:onTapClose()
        end,
    }

    self.image_widget = ImageWidget:new{
        file = self.file_names[0],
        alpha = true,
        width = self.dimen.w,
        height = self.dimen.h - 80,   -- reserve space for Exit button
        scale_factor = 0,             -- fit while keeping aspect ratio
    }

    self.vertical_container = VerticalGroup:new{
        self.exit_button,
        self.image_widget
    }

    self.centered_container = CenterContainer:new{
        self.vertical_container,
        dimen = self.dimen
    }

    self[1] = FrameContainer:new{
        background = Blitbuffer.COLOR_WHITE,
        self.centered_container
    }

    UIManager:show(self, "full")
end

function BongoCat:onHold()
    -- finger is down: keep paws down
    self.image_widget.file = self.file_names[1]
    self.image_widget:free()
    UIManager:setDirty(self, "fast")
    return true
end

function BongoCat:onHoldRelease()
    -- finger released: paws back up
    self.image_widget.file = self.file_names[0]
    self.image_widget:free()
    UIManager:setDirty(self, "fast")
    return true
end

function BongoCat:onTapClose()
    UIManager:close(self, "full")
end
BongoCat.onAnyKeyPressed = BongoCat.onTapClose



return BongoCat
