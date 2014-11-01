local m = {}

local DFUtil = require("DFCommon.Util")
local UIElement = require('UI.UIElement')
local DFInput = require('DFCommon.Input')
local CommandObject = require('Utility.CommandObject')
local SoundManager = require('SoundManager')
local Room = require('Room')
local Base = require('Base')
local EnvObject = nil
local GameRules = nil

local sUILayoutFileName = 'UILayouts/SelectObjectSubmenuLayout'

local nButtonWidth, nButtonHeight  = 430, 81
local nButtonStartY = 278
local nIconX, nIconStartY = 20, -280
local nLabelX, nLabelStartY = 105, -288
local nHotkeyX, nHotkeyStartY = nButtonWidth - 112, -330
local nIconScale = .6

local kHOTKEYS = {"1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "A", "B"}

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())
    
    EnvObject = require('EnvObjects/EnvObject')
    GameRules = require('GameRules')
    
    function Ob:init(sZoneId)
        local tLayoutInfo = self:_loadUIInfoFile(sUILayoutFileName)

        -- fill in dynamic buttons
        if sZoneId then
            self:addButtonsForZone(sZoneId, tLayoutInfo)
        end
        
        self:_processUIInfoTable(tLayoutInfo)

        self.rBackButton = self:getTemplateElement('BackButton')
        self.rBackButton:addPressedCallback(self.onBackButtonPressed, self)
        
        self.rCancelButton = self:getTemplateElement('CancelButton')
        self.rCancelButton:addPressedCallback(self.onCancelButtonPressed, self)

        self.rConfirmButton = self:getTemplateElement('ConfirmButton')
        self.rConfirmButton:addPressedCallback(self.onConfirmButtonPressed, self)

        self.tHotkeyButtons = {}
        self:addHotkey(self:getTemplateElement('BackHotkey').sText, self.rBackButton)
        self:addHotkey(self:getTemplateElement('CancelHotkey').sText, self.rCancelButton)
        self:addHotkey(self:getTemplateElement('ConfirmHotkey').sText, self.rConfirmButton)

        for _,tObj in pairs(self.tObjectTypes) do
            local rButton = self:getTemplateElement(tObj.sId)
			assert(rButton ~= nil)
            rButton:addPressedCallback(self.onObjectButtonPressed, self)
            self:addHotkey(self:getTemplateElement(tObj.sId .. 'Hotkey').sText, rButton)
        end

        self.rNoFundsLabel = self:getTemplateElement('NoFundsLabel')
        
        self.rLargeBar = self:getTemplateElement('LargeBar')
        local nBarHeight = nButtonStartY + (nButtonHeight * self.nNumObjects) 
        self.rLargeBar:setScl(nButtonWidth, nBarHeight)   

        self.rEndcap = self:getTemplateElement('SidebarBottomEndcapExpanded')
        local nEndcapY = -(nButtonStartY + (nButtonHeight * self.nNumObjects))
        self.rEndcap:setLoc(0, nEndcapY)

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
    
    function Ob:_getObjectTypesForZone(sZoneId)
        local EnvObjectData = require("EnvObjects.EnvObjectData")
		
        local tTypesForZone = {}
        for sId, tData in pairs(EnvObjectData.tObjects) do
            if false ~= tData.showInObjectMenu then
                local objZoneName = tData.menuZoneName or tData.zoneName or "ALL"
                if objZoneName == sZoneId and (not tData.researchPrereq or Base.hasCompletedResearch(tData.researchPrereq)) then 
					-- remember key
					tData.sId = sId
                    tTypesForZone[sId] = tData
                end
            end
        end
		
        local tSortedTypes = {}
        for i,sType in ipairs(EnvObjectData.tMenus[sZoneId]) do
            table.insert(tSortedTypes, tTypesForZone[sType])
            tTypesForZone[sType] = nil
        end
        for sType,tData in pairs(tTypesForZone) do
            table.insert(tSortedTypes, tData)
        end
        
        return tSortedTypes
    end
    
    function Ob:addButtonsForZone(sZoneId, tLayoutInfo)
        local Gui = require('UI.Gui')

        local AMBER = { Gui.AMBER[1], Gui.AMBER[2], Gui.AMBER[3], 0.95 }
        local BLACK = { Gui.BLACK[1], Gui.BLACK[2], Gui.BLACK[3], 0.95 }
        local BRIGHT_AMBER = { Gui.AMBER[1], Gui.AMBER[2], Gui.AMBER[3], 1 }
        local SELECTION_AMBER = { Gui.AMBER[1], Gui.AMBER[2], Gui.AMBER[3], 0.01 }
        
        self.tObjectTypes = self:_getObjectTypesForZone(sZoneId)
        self.nNumObjects = 0
        
        local i = 0
        for _,tObj in pairs(self.tObjectTypes) do
            local buttonKey = tObj.sId
            local buttonData =
            {
                key = buttonKey,
                type = 'onePixelButton',
                pos = { 0, -(nButtonStartY + i * nButtonHeight) },
                scale = { nButtonWidth, nButtonHeight },
                color = BLACK,
                onPressed =
                {
                    {
                        key = buttonKey,
                        color = BRIGHT_AMBER,
                    },            
                },
                onReleased =
                {
                    {
                        key = buttonKey,
                        color = AMBER,
                    },       
                },
                onHoverOn =
                {
                    {
                        key = buttonKey,
                        color = Gui.AMBER,
                    },
                    {
                        key = buttonKey .. 'Label',
                        color = { 0, 0, 0 },
                    },
                    {
                        key = buttonKey .. 'CostLabel',
                        color = { 0, 0, 0 },
                    },
                    {
                        key = buttonKey .. 'Icon',
                        color = { Gui.AMBER[1],Gui.AMBER[2],Gui.AMBER[3],  1.0},
                    },                
                    {
                        key = buttonKey .. 'Hotkey',
                        color = { 0, 0, 0 },
                    },
                    {
                        playSfx = 'hilight',
                    },
                    
                },
                onHoverOff =
                {
                    {
                        key = buttonKey,
                        color = Gui.BLACK,
                    },
                    {
                        key = buttonKey .. 'Label',
                        color = Gui.AMBER,
                    },
                    {
                        key = buttonKey .. 'CostLabel',
                        color = Gui.AMBER,
                    },
                    {
                        key = buttonKey .. 'Icon',
                        color = Gui.AMBER,
                    },  
                    {
                        key = buttonKey .. 'Hotkey',
                        color = Gui.AMBER,
                    },
                },
            }
            local labelData =
            {
                key = buttonKey .. 'Label',
                type = 'textBox',
                pos = { nLabelX, nLabelStartY - (nButtonHeight * i) },
                linecode = tObj.friendlyNameLinecode,
                style = 'dosisregular40',
                rect = { 0, 300, nButtonWidth, 0 },
                hAlign = MOAITextBox.LEFT_JUSTIFY,
                vAlign = MOAITextBox.LEFT_JUSTIFY,
                color = Gui.AMBER,
            }
            
            local nCost = tObj.matterCost or 0
            local costLableData = 
            {
                key = buttonKey .. 'CostLabel',
                type = 'textBox',
                pos = { nLabelX, nLabelStartY - (nButtonHeight * i) - 42 },
                text = "Cost: " .. tostring(nCost),
                style = 'dosissemibold22',
                rect = { 0, 300, nButtonWidth, 0 },
                hAlign = MOAITextBox.LEFT_JUSTIFY,
                vAlign = MOAITextBox.LEFT_JUSTIFY,
                color = Gui.AMBER,
            }
            
            local iconData =
            {
                key = buttonKey .. 'Icon',
                type = 'uiTexture',
                textureName = 'ui_iconIso_generic',
                sSpritesheetPath = 'UI/Shared',
                pos = { nIconX, nIconStartY - (nButtonHeight * i) },
                color = Gui.AMBER,
                scale = { nIconScale, nIconScale },
            }
            local hotkeyData = 
            {
                key = buttonKey .. 'Hotkey',
                type = 'textBox',
                pos = { nHotkeyX, nHotkeyStartY - (nButtonHeight * i) },
                text = kHOTKEYS[i + 1],
                style = 'dosissemibold22',
                rect = { 0, 100, 100, 0 },
                hAlign = MOAITextBox.RIGHT_JUSTIFY,
                vAlign = MOAITextBox.LEFT_JUSTIFY,
                color = Gui.AMBER,
            }
            
            if tObj.sidebarIcon then iconData.textureName = tObj.sidebarIcon end
            
            table.insert(tLayoutInfo.tElements, buttonData)
            table.insert(tLayoutInfo.tElements, iconData)
            table.insert(tLayoutInfo.tElements, hotkeyData)
            table.insert(tLayoutInfo.tElements, labelData)
            table.insert(tLayoutInfo.tElements, costLableData)
            
            self.nNumObjects = self.nNumObjects + 1
            i = self.nNumObjects
        end
        
        
    end
    
    function Ob:onTick(dt)
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
        local sMatterCostText = self:getMatterCostText()
        if sMatterCostText ~= '' then
            self:setMatterCostVisible(true)
            self.rCostText:setString(sMatterCostText)
        else
            self:setMatterCostVisible(false)
        end
    end
    
    function Ob:onBackButtonPressed(rButton, eventType)
        if eventType == DFInput.TOUCH_UP then
            if g_GuiManager.newSideBar then
                --g_GameRules.cancelBuild()
                g_GameRules.setUIMode(g_GameRules.MODE_INSPECT)
                g_GuiManager.newSideBar:openSubmenu(g_GuiManager.newSideBar.rObjectMenu)
            end
        end
    end

    function Ob:onCancelButtonPressed(rButton, eventType)
        if eventType == DFInput.TOUCH_UP then
            g_GameRules.cancelBuild()
            g_GuiManager.newSideBar:closeConstructMenu()
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
    
    function Ob:onObjectButtonPressed(rButton, eventType)
        if eventType == DFInput.TOUCH_UP then
            self.sObjectId = rButton.sKey
			local tData = EnvObject.getObjectData(self.sObjectId)
			-- slightly special handlin' for doors
			if tData.door then
				g_GameRules.setUIMode(g_GameRules.MODE_BUILD_DOOR, self.sObjectId)
			else
				g_GameRules.setUIMode(g_GameRules.MODE_PLACE_PROP, self.sObjectId)
			end
			if self.sObjectId == 'FoodReplicator' then
				g_GameRules.completeTutorialCondition('SelectedFoodRep')
			end
        end
    end
    
    function Ob:setParams(tParams)
        self.tParams = tParams
    end
    
    function Ob:show(basePri)
        Ob.Parent.show(self, basePri)
        --g_GameRules.cancelBuild()
        --self:setModeSelected(nil)
    end

    function Ob:hide()
        Ob.Parent.hide(self)
        --self:setModeSelected(nil)
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
