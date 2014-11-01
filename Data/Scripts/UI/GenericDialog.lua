local m = {}

local DFUtil = require("DFCommon.Util")
local DFInput = require("DFCommon.Input")
local UIElement = require('UI.UIElement')
local SoundManager = require('SoundManager')

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())
    Ob.tEventData = nil
    Ob.sRenderLayerName = 'UIForeground'

    function Ob:init(sLayoutFile, cb, sAcceptButton, sDeclineButton, sAcceptHotkey, sDeclineHotkey)
        self:processUIInfo(sLayoutFile)
        self.cb = cb

        local rAcceptButton = self:getTemplateElement(sAcceptButton or 'AcceptButton')
        local rDeclineButton = self:getTemplateElement(sDeclineButton or 'DeclineButton')

        if rAcceptButton then rAcceptButton:addPressedCallback(function(rButton,eventType) self:pressed(true,eventType) end) end
        if rDeclineButton then rDeclineButton:addPressedCallback(function(rButton,eventType) self:pressed(false,eventType) end) end        
        
        self.tHotkeyButtons = {}

        local rAcceptHotkey = self:getTemplateElement(sAcceptHotkey or 'AcceptHotkey')
        local rDeclineHotkey = self:getTemplateElement(sDeclineHotkey or 'DeclineHotkey')
        if rAcceptHotkey then
            self:addHotkey(rAcceptHotkey.sText, rAcceptButton)
        end
        if rDeclineHotkey then
            self:addHotkey(rDeclineHotkey.sText, rDeclineButton)
        end
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
        elseif sKey == "bksp" then
            keyCode = 8
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

    function Ob:replaceText(tReplacements)
        for k,v in pairs(tReplacements) do
            local r = self:getTemplateElement(k)
            if r then
                r:setString(g_LM.line(v))
            end
        end
    end

    function Ob:pressed(bAccept,eventType)
        if eventType == DFInput.TOUCH_UP then
            self.cb(bAccept)
            g_GuiManager.removeFromPopupQueue(self, true)
            SoundManager.playSfx('confirm')
        end
    end

    function Ob:show(nPri)
        local nPri = Ob.Parent.show(self, nPri)
        g_GuiManager.createEffectMaskBox(500, 0, 850, 800, 0.3, 2)
        SoundManager.playSfx('inspectorshow')
        return nPri
    end

    return Ob
end

function m.new(...)
    local Ob = m.create()
    Ob:init(...)

    return Ob
end

return m
