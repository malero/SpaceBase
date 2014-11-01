local m = {}

local DFUtil = require("DFCommon.Util")
local UIElement = require('UI.UIElement')
local DFInput = require('DFCommon.Input')
local SoundManager = require('SoundManager')
local EmergencyBeacon = require('Utility.EmergencyBeacon')

local sUILayoutFileName = 'UILayouts/BeaconMenuLayout'

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())
    Ob.rSelectedButton = nil

    function Ob:init()
        Ob.Parent.init(self)
    
        self:processUIInfo(sUILayoutFileName)

        self.rDoneButton = self:getTemplateElement('DoneButton')
        self.rClearBeaconButton = self:getTemplateElement('ClearBeaconButton')
        self.rViolenceLowButton = self:getTemplateElement('ViolenceLowButton')
        self.rViolenceDefaultButton = self:getTemplateElement('ViolenceDefaultButton')
        self.rViolenceHighButton = self:getTemplateElement('ViolenceHighButton')

        self.rDoneButton:addPressedCallback(self.onDoneButtonPressed, self)
        self.rClearBeaconButton:addPressedCallback(self.onClearBeaconButtonPressed, self)

        self.rViolenceLowButton:addPressedCallback(self.onViolenceButtonPressed, self)
        self.rViolenceDefaultButton:addPressedCallback(self.onViolenceButtonPressed, self)
        self.rViolenceHighButton:addPressedCallback(self.onViolenceButtonPressed, self)
        self.rViolenceLowButton.eViolence = EmergencyBeacon.VIOLENCE_NONLETHAL
        self.rViolenceDefaultButton.eViolence = EmergencyBeacon.VIOLENCE_DEFAULT
        self.rViolenceHighButton.eViolence = EmergencyBeacon.VIOLENCE_LETHAL
        local tData=
        {
            buttonStatusFn=function(self)
                return (g_ERBeacon.eViolence == self.eViolence and 'selected') or 'normal'
            end,
        }
        self.rViolenceLowButton:setBehaviorData(tData)
        self.rViolenceDefaultButton:setBehaviorData(tData)
        self.rViolenceHighButton:setBehaviorData(tData)
        
        self.tHotkeyButtons = {}
        self:addHotkey(self:getTemplateElement('DoneHotkey').sText, self.rDoneButton)
        self:addHotkey(self:getTemplateElement('ClearBeaconHotkey').sText, self.rClearBeaconButton)
    end

    function Ob:addHotkey(sKey, rButton)
        sKey = string.lower(sKey)
    
        local keyCode = -1
    
        if sKey == "esc" then
            keyCode = 27
        elseif sKey == "ret" or sKey == "ent" then
            keyCode = 13
        elseif sKey == "spc" then
            keyCode = 32
        else
            keyCode = string.byte(sKey)
            
            -- also store the uppercase version because hey why not
            local uppercaseKeyCode = string.byte(string.upper(sKey))
            self.tHotkeyButtons[uppercaseKeyCode] = rButton
        end
    
        self.tHotkeyButtons[keyCode] = rButton
    end
    
    -- returns true if key was handled
    function Ob:onKeyboard(key, bDown)
        local bHandled = false

        if not self.rSubmenu then
            if bDown and self.tHotkeyButtons[key] then
                local rButton = self.tHotkeyButtons[key]
                rButton:keyboardPressed()
                bHandled = true
            end
        end
        
        if not bHandled and self.rSubmenu and self.rSubmenu.onKeyboard then
            bHandled = self.rSubmenu:onKeyboard(key, bDown)
        end
        
        return bHandled
    end
    
    function Ob:onDoneButtonPressed(rButton, eventType)
        if eventType == DFInput.TOUCH_UP then
            if g_GuiManager.newSideBar then
                g_GuiManager.newSideBar:closeSubmenu()
                SoundManager.playSfx('degauss')
            end
        end
    end
    
    function Ob:onClearBeaconButtonPressed(rButton, eventType)
        if eventType == DFInput.TOUCH_UP then
            -- clear
            g_ERBeacon:remove()
            SoundManager.playSfx('clearbeacon')
        end
    end

    function Ob:onViolenceButtonPressed(rButton, eventType)
        g_ERBeacon.eViolence = rButton.eViolence
    end

    function Ob:show(basePri)
        local nPri = Ob.Parent.show(self, basePri)
        g_GameRules.setUIMode(g_GameRules.MODE_BEACON)
        return nPri
    end

    function Ob:hide()
        Ob.Parent.hide(self)
        g_GameRules.setUIMode(g_GameRules.MODE_INSPECT)
    end

    return Ob
end

function m.new(...)
    local Ob = m.create()
    Ob:init(...)

    return Ob
end

return m
