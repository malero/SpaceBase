local m = {}

local DFUtil = require("DFCommon.Util")
local UIElement = require('UI.UIElement')
local DFInput = require('DFCommon.Input')
local CommandObject = require('Utility.CommandObject')
local SoundManager = require('SoundManager')

local sUILayoutFileName = 'UILayouts/DoorsSubMenuLayout'

local sCostLabelLC = 'BUILDM023TEXT'

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())

    function Ob:init()
        self:processUIInfo(sUILayoutFileName)
        Ob.Parent.init(self)

        self.rBackButton = self:getTemplateElement('BackButton')
        self.rBackButton:addPressedCallback(self.onBackButtonPressed, self)

        self.rCancelButton = self:getTemplateElement('CancelButton')
        self.rCancelButton:addPressedCallback(self.onCancelButtonPressed, self)

        self.rConfirmButton = self:getTemplateElement('ConfirmButton')
        self.rConfirmButton:addPressedCallback(self.onConfirmButtonPressed, self)

        self.rDoorButton = self:getTemplateElement('DoorButton')
        self.rDoorButton:addPressedCallback(self.onBuildTypeButtonPressed, self)

        self.rAirlockButton = self:getTemplateElement('AirlockButton')
        self.rAirlockButton:addPressedCallback(self.onBuildTypeButtonPressed, self)

		self.rHeavyDoorButton = self:getTemplateElement('HeavyDoorButton')
        self.rHeavyDoorButton:addPressedCallback(self.onBuildTypeButtonPressed, self)

        self.rSelectionHighlight = self:getTemplateElement('SelectionHighlight')

        self.rDoorCostLabel = self:getTemplateElement('DoorCostLabel')
        self.rAirlockDoorCostLabel = self:getTemplateElement('AirlockDoorCostLabel')
        self.rHeavyDoorCostLabel = self:getTemplateElement('HeavyDoorCostLabel')
		
		local sCostLabelText = g_LM.line(sCostLabelLC)
        self.rDoorCostLabel:setString(sCostLabelText..' '..g_GameRules.MAT_BUILD_DOOR)
        self.rAirlockDoorCostLabel:setString(sCostLabelText..' '..g_GameRules.MAT_BUILD_AIRLOCK_DOOR)
        self.rHeavyDoorCostLabel:setString(sCostLabelText..' '..g_GameRules.MAT_BUILD_HEAVY_DOOR)
		
		-- heavy door items for hidin'
        self.rHeavyDoorIcon = self:getTemplateElement('HeavyDoorIcon')
        self.rHeavyDoorLabel = self:getTemplateElement('HeavyDoorLabel')
        self.rHeavyDoorHotkey = self:getTemplateElement('HeavyDoorHotkey')
		self.rBarEncap = self:getTemplateElement('SidebarBottomEndcapExpanded')
		self.rBar = self:getTemplateElement('LargeBar')
		-- these values should match what's in UILayouts\DoorsSubMenuLayout.lua
		-- UGH THIS IS SO GROSS OH WELL ALPHA 4 TOMORROW
		self.nButtonStartY = 278
		self.nButtonWidth = 430
		self.nButtonHeight = 81
		
        self.tHotkeyButtons = {}
        self:addHotkey(self:getTemplateElement('BackHotkey').sText, self.rBackButton)
        self:addHotkey(self:getTemplateElement('CancelHotkey').sText, self.rCancelButton)
        self:addHotkey(self:getTemplateElement('ConfirmHotkey').sText, self.rConfirmButton)
        self:addHotkey(self:getTemplateElement('DoorHotkey').sText, self.rDoorButton)
        self:addHotkey(self:getTemplateElement('AirlockHotkey').sText, self.rAirlockButton)
        self:addHotkey(self:getTemplateElement('HeavyDoorHotkey').sText, self.rHeavyDoorButton)

        self.rNoFundsLabel = self:getTemplateElement('NoFundsLabel')

        self.rCostText = self:getTemplateElement('CostText')
        self.sBuildCostLabel = g_LM.line("BUILDM017TEXT")
        self.sVaporizeLabel = g_LM.line("BUILDM018TEXT")
        self.sUndoLabel = g_LM.line("BUILDM019TEXT")

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

    function Ob:onTick(dt)
--[[
		if self.sObjectId then
            local nCost = EnvObject.getObjectData(self.sObjectId).matterCost or 0
            local nPendingCost = CommandObject.pendingBuildCost

            if (nCost + nPendingCost) > GameRules.nMatter then
                -- "insufficient funds" text
                self.rNoFundsLabel:setVisible(true)
            else
                self.rNoFundsLabel:setVisible(false)
            end
        end
]]--
        local sMatterCostText = self:getMatterCostText()
        if sMatterCostText ~= '' then
            self:setMatterCostVisible(true)
            self.rCostText:setString(sMatterCostText)
        else
            self:setMatterCostVisible(false)
        end
		-- show/hide heavy door if researched/not
		local bHeavyDoorResearched = require('Base').hasCompletedResearch('DoorLevel2')
		if bHeavyDoorResearched then
			self:setElementHidden(self.rHeavyDoorButton, false)
			self:setElementHidden(self.rHeavyDoorIcon, false)
			self:setElementHidden(self.rHeavyDoorLabel, false)
			self:setElementHidden(self.rHeavyDoorHotkey, false)
			self:setElementHidden(self.rHeavyDoorCostLabel, false)
			self.rBarEncap:setLoc(0, -(self.nButtonStartY + 3*self.nButtonHeight))
			self.rBar:setScl(self.nButtonWidth, self.nButtonStartY + 3*self.nButtonHeight)
			-- enable hotkey
			self:addHotkey(self:getTemplateElement('HeavyDoorHotkey').sText, self.rHeavyDoorButton)
		else
			self:setElementHidden(self.rHeavyDoorButton, true)
			self:setElementHidden(self.rHeavyDoorIcon, true)
			self:setElementHidden(self.rHeavyDoorLabel, true)
			self:setElementHidden(self.rHeavyDoorHotkey, true)
			self:setElementHidden(self.rHeavyDoorCostLabel, true)
			self.rBarEncap:setLoc(0, -(self.nButtonStartY + 2*self.nButtonHeight))
			self.rBar:setScl(self.nButtonWidth, self.nButtonStartY + 2*self.nButtonHeight)
			-- disable hotkey
			self.tHotkeyButtons[string.byte('3')] = nil
		end
    end

    function Ob:onBackButtonPressed(rButton, eventType)
        if eventType == DFInput.TOUCH_UP then
            if g_GuiManager.newSideBar then
                --g_GameRules.cancelBuild()
                g_GuiManager.newSideBar:openSubmenu(g_GuiManager.newSideBar.rObjectMenu)
            end
        end
    end

    function Ob:onCancelButtonPressed(rButton, eventType)
        if eventType == DFInput.TOUCH_UP then
            g_GameRules.cancelBuild()
            g_GuiManager.newSideBar:closeConstructMenu()
            SoundManager.playSfx('degauss')
        end
    end

    function Ob:onConfirmButtonPressed(rButton, eventType)
        if eventType == DFInput.TOUCH_UP then
            if g_GameRules.confirmBuild() then
                g_GuiManager.newSideBar:closeConstructMenu()
                SoundManager.playSfx('confirm')
            end
        end
    end

    function Ob:setModeSelected(rModeButton)
        self.rCurModeButton = rModeButton
        if rModeButton then
            self.rSelectionHighlight:setVisible(true)
            if rModeButton == self.rDoorButton then
                g_GameRules.setUIMode(g_GameRules.MODE_BUILD_DOOR, 'Door')
            elseif rModeButton == self.rAirlockButton then
                g_GameRules.setUIMode(g_GameRules.MODE_BUILD_DOOR, 'Airlock')
            elseif rModeButton == self.rHeavyDoorButton then
                g_GameRules.setUIMode(g_GameRules.MODE_BUILD_DOOR, 'HeavyDoor')
            end
            local x, y = self.rCurModeButton:getLoc()
            self.rSelectionHighlight:setLoc(x, y)
        else
            self.rSelectionHighlight:setVisible(false)
        end
    end

    function Ob:onBuildTypeButtonPressed(rButton, eventType)
        if eventType == DFInput.TOUCH_UP then
            self:setModeSelected(rButton)
            SoundManager.playSfx('select')
        end
    end

    function Ob:show(basePri)
        Ob.Parent.show(self, basePri)
        --g_GameRules.cancelBuild()
        self:setModeSelected(nil)
    end

    function Ob:hide()
        Ob.Parent.hide(self)
        self:setModeSelected(nil)
        --g_GameRules.setUIMode(g_GameRules.MODE_INSPECT)
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
            self.rConfirmButton:setEnabled(true)
        end
    end

	function Ob:getMatterCostText()
		local text = ''
        local sPlus = ''
        local nPendingBuildCost = g_GameRules.getPendingBuildCost()
        if nPendingBuildCost < 0 then sPlus = '+' else sPlus = '-' end
		if nPendingBuildCost ~= 0 then
            text = sPlus..(math.abs(nPendingBuildCost))..' '..self.sBuildCostLabel..'\n'
		end
        if CommandObject.pendingVaporizeCost > 0 then sPlus = '+' else sPlus = '' end
		if CommandObject.pendingVaporizeCost ~= 0 then
            text = text .. sPlus .. CommandObject.pendingVaporizeCost .. ' ' .. self.sVaporizeLabel .. '\n'
		end
        if CommandObject.pendingCancelCost > 0 then sPlus = '+' else sPlus = '' end
		if CommandObject.pendingCancelCost ~= 0 then
            text = text .. sPlus .. CommandObject.pendingCancelCost .. ' ' .. self.sUndoLabel
		end
		return text
	end

    return Ob
end

function m.new(...)
    local Ob = m.create()
    Ob:init(...)

    return Ob
end

return m
