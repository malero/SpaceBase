local m = {}

local DFUtil = require("DFCommon.Util")
local DFInput = require('DFCommon.Input')
local UIElement = require('UI.UIElement')
local Room = require('Room')
local Door = require('EnvObjects.Door')
local SoundManager = require('SoundManager')

local sUILayoutFileName = 'UILayouts/EmergencyAlarmControlsLayout'

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())
    Ob.rObject = nil

    function Ob:init()
        self:processUIInfo(sUILayoutFileName)
        Ob.Parent.init(self)

        self.rOnButton = self:getTemplateElement('OnButton')
        self.rOffButton = self:getTemplateElement('OffButton')

        self.rOnButton:addPressedCallback(self.onButtonPressed, self)
        self.rOffButton:addPressedCallback(self.onButtonPressed, self)
    end

    function Ob:onTick(dt)
        if self.rObject then
            local rRoom = self.rObject:getRoom()
            if rRoom and rRoom ~= Room.getSpaceRoom() then
                self.rOnButton:setSelected(rRoom:isEmergencyAlarmOn())
                self.rOffButton:setSelected(not rRoom:isEmergencyAlarmOn())
                if self.rObject:isFunctioning() then
                    self.rOnButton:setEnabled(true)
                    self.rOffButton:setEnabled(true)                    
                else
                    self.rOnButton:setEnabled(false)
                    self.rOffButton:setEnabled(false)
                end
            end
        end
    end
	
	function Ob:getCustomControlsLabel()
		return g_LM.line('PROPSX091TEXT')
	end
	
    function Ob:onButtonPressed(rButton, eventType)
        if self.rObject and self.rObject:isFunctioning() then
            local rRoom = self.rObject:getRoom()
            if rRoom and rRoom ~= Room.getSpaceRoom() then
                if eventType == DFInput.TOUCH_UP then
                    if rButton == self.rOnButton then
                        rRoom:setEmergencyAlarmOn(true)
                        --SoundManager.playSfx('inspectordoornormal')
                    elseif rButton == self.rOffButton then
                        rRoom:setEmergencyAlarmOn(false)
                        --SoundManager.playSfx('inspectordoorlock')
                    end
                end
            end
        end
    end

    function Ob:setObject(rObject)
        self.rObject = rObject
    end

    return Ob
end

function m.new(...)
    local Ob = m.create()
    Ob:init(...)

    return Ob
end

return m
