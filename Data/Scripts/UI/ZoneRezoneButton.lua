local m = {}

local DFUtil = require("DFCommon.Util")
local UIElement = require('UI.UIElement')
local DFInput = require('DFCommon.Input')
local Room = require('Room')
local Character = require('Character')
local SoundManager = require('SoundManager')

local sUILayoutFileName = 'UILayouts/ZoneRezoneButtonLayout'

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())
    Ob.rZoneInfo = nil

    function Ob:init(rZoneInfo)
        self:setRenderLayer('UIScrollLayerLeft')

        Ob.Parent.init(self)
        self:processUIInfo(sUILayoutFileName)        

        self.rButtonLabel = self:getTemplateElement('ButtonLabel')
        self.rButtonDescription = self:getTemplateElement('ButtonDescription')
        self.rPropDescription = self:getTemplateElement('PropDescription')
        self.rNumText = self:getTemplateElement('NumText')
        self.rButton = self:getTemplateElement('Button')
        self.rButton:addPressedCallback(self.onZoneButtonPressed, self)
        
        self.rZoneInfo = rZoneInfo
        if rZoneInfo then
            if rZoneInfo.name then
                self.rButtonLabel:setString(g_LM.line(rZoneInfo.name))
            end
            if rZoneInfo.desc then
                self.rButtonDescription:setString(g_LM.line(rZoneInfo.desc))
            end
            if rZoneInfo.propdesc then
                self.rPropDescription:setString(g_LM.line(rZoneInfo.propdesc))
            end
        end
    end

    function Ob:onTick(dt)
        if self.rRoom and self.rZoneInfo then
            self.rButton:setSelected(self.rRoom:getZoneName() == self.rZoneInfo.zoneName)
            local _, nNumRooms = Room.getRoomsOfTeam(Character.TEAM_ID_PLAYER, nil, self.rZoneInfo.zoneName)
            self.rNumText:setString(tostring(nNumRooms))
        end
    end

    function Ob:setRoom(rRoom)
        self.rRoom = rRoom
    end

    function Ob:getDims()
        return 250,-76
    end

    function Ob:onZoneButtonPressed(rButton, eventType)
        if eventType == DFInput.TOUCH_UP then
            -- change zone type
            if self.rRoom and self.rZoneInfo then
                self.rRoom:setZone(self.rZoneInfo.zoneName)
                SoundManager.playSfx('inspectorduty')
            end
        end
    end

    return Ob
end

function m.new(...)
    local Ob = m.create()
    Ob:init(...)

    return Ob
end

return m