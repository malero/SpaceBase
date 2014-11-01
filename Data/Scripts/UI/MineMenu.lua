local m = {}

local DFUtil = require("DFCommon.Util")
local UIElement = require('UI.UIElement')
local DFInput = require('DFCommon.Input')
local CommandObject = require('Utility.CommandObject')
local SoundManager = require('SoundManager')

local sUILayoutFileName = 'UILayouts/MineMenuLayout'

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())
    Ob.rSelectedButton = nil

    function Ob:init()
        Ob.Parent.init(self)
    
        self:processUIInfo(sUILayoutFileName)

        self.rMineButton = self:getTemplateElement('MineButton')
        self.rEraseButton = self:getTemplateElement('EraseButton')
        self.rDoneButton = self:getTemplateElement('DoneButton')
        self.rSelectionHighlight = self:getTemplateElement('SelectionHighlight')
        self.rCostText = self:getTemplateElement('CostText')

        self.rMineButton:addPressedCallback(self.onMineButtonPressed, self)
        self.rEraseButton:addPressedCallback(self.onEraseButtonPressed, self)
        self.rDoneButton:addPressedCallback(self.onDoneButtonPressed, self)
        
        self.tHotkeyButtons = {}
        self:addHotkey(self:getTemplateElement('EraseHotkey').sText, self.rEraseButton)
        self:addHotkey(self:getTemplateElement('MineHotkey').sText, self.rMineButton)
        self:addHotkey(self:getTemplateElement('DoneHotkey').sText, self.rDoneButton)

        self.sMineLabel = g_LM.line("BUILDM020TEXT")

        self:setMatterCostVisible(false)
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
    
    function Ob:onMineButtonPressed(rButton, eventType)
        if eventType == DFInput.TOUCH_UP then
            self:setModeSelected(self.rMineButton)
            SoundManager.playSfx('select')
        end
    end

    function Ob:onEraseButtonPressed(rButton, eventType)
        if eventType == DFInput.TOUCH_UP then
            self:setModeSelected(self.rEraseButton)            
            SoundManager.playSfx('select')
        end
    end

    function Ob:onDoneButtonPressed(rButton, eventType)
        if eventType == DFInput.TOUCH_UP then
			g_GameRules.completeTutorialCondition('MineConfirm')
            g_GameRules.confirmBuild(true)
            g_GuiManager.newSideBar:closeSubmenu()
            SoundManager.playSfx('confirm')
        end
    end

    function Ob:setModeSelected(rModeButton)
        if rModeButton then
            self.rCurModeButton = rModeButton
            if rModeButton == self.rMineButton then
                g_GameRules.setUIMode(g_GameRules.MODE_MINE)
            elseif rModeButton == self.rEraseButton then
                g_GameRules.setUIMode(g_GameRules.MODE_CANCEL_COMMAND, CommandObject.CANCEL_PARAM_MINE)
            end
            local x, y = self.rCurModeButton:getLoc()
            self.rSelectionHighlight:setLoc(x, y)
        end
    end

    function Ob:setMatterCostVisible(bVisible)
        if self.bMatterCostVisible ~= bVisible then
            local sTemplateInfoToApply = nil
            if bVisible then
                sTemplateInfoToApply = 'onShowMatterCost'
            else
                sTemplateInfoToApply = 'onHideMatterCost'
            end
            local tInfo = self:getExtraTemplateInfo(sTemplateInfoToApply)
            if tInfo then
                self:applyTemplateInfos(tInfo)
            end
            self.bMatterCostVisible = bVisible
            self.rDoneButton:setEnabled(true)
        end
    end

	function Ob:getMatterCostText()
		local text = ''
        local sPlus = ''
        if CommandObject.pendingMineCost > 0 then sPlus = '+' else sPlus = '' end
		if CommandObject.pendingMineCost ~= 0 then
			text = text .. sPlus .. CommandObject.pendingMineCost .. self.sMineLabel
		end
		return text
	end	

    function Ob:onTick(dt)
        local sMatterCostText = self:getMatterCostText()
        if sMatterCostText ~= '' then
            self:setMatterCostVisible(true)
            self.rCostText:setString(sMatterCostText)
        else
            self:setMatterCostVisible(false)
        end
    end

    function Ob:show(basePri)
        local nPri = Ob.Parent.show(self, basePri)
        self:setModeSelected(self.rMineButton)
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
