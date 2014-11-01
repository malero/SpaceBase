local m = {}

local DFUtil = require("DFCommon.Util")
local UIElement = require('UI.UIElement')
local DFInput = require('DFCommon.Input')
local ObjectStatsTab = require('UI.ObjectStatsTab')
local ObjectActionTab = require('UI.ObjectActionTab')
local ObjectAboutTab = require('UI.ObjectAboutTab')
local ObjectList = require('ObjectList')
local GameScreen = require('GameScreen')
local EnvObject = require('EnvObjects.EnvObject')
local SoundManager = require('SoundManager')
local Gui = require('UI.Gui')
local Inventory = require('Inventory')
local TemplateButton = require('UI.TemplateButton')
local ResearchData = require('ResearchData')
local ObjectActionTab = require('UI.ObjectActionTab')

local sUILayoutFileName = 'UILayouts/ObjectInspectorLayout'

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())
    Ob.rObject = nil

    function Ob:init()
        Ob.Parent.init(self)
        self:processUIInfo(sUILayoutFileName)
        self.rObjectStatsTab = ObjectStatsTab.new()
		self.rObjectActionTab = ObjectActionTab.new()
		self.rObjectAboutTab = ObjectAboutTab.new()
		self.rObjectActionTab.rObjectInspector = self
        self.rTabbedPane = self:getTemplateElement('TabbedPane')
        local tIcons={'ui_icon_stats','ui_icon_activity','ui_icon_about'}
        local tButtons = {}
        for i,v in ipairs(tIcons) do
            tButtons[i] = TemplateButton.new()
            tButtons[i]:setReplacements('Icon',{textureName=v})
            tButtons[i]:setLayoutFile('UILayouts/IconTabLayout')
            tButtons[i]:setButtonName('TabButton')
        end
        self.rTabbedPane:addTab(self.rObjectStatsTab, 'ObjectStatsTab', true, tButtons[1])
        self.rTabbedPane:addTab(self.rObjectActionTab, 'ObjectActionTab', true, tButtons[2])
        self.rTabbedPane:addTab(self.rObjectAboutTab, 'ObjectAboutTab', true, tButtons[3])
        self.tTabButtons = tButtons
		
        self.rNameText = self:getTemplateElement('NameLabel')
        self.rPicture = self:getTemplateElement('Picture')
        self.rPictureTint = self:getTemplateElement('PictureTint')
        self.rNameEditBG = self:getTemplateElement('NameEditBG')
        self.rDescriptionText = self:getTemplateElement('DescriptionText')
        self.rConditionBG = self:getTemplateElement('ConditionBG')
        self.rConditionLabel = self:getTemplateElement('ConditionLabel')
        self.rConditionText = self:getTemplateElement('ConditionText')
        self.rEmergencyStatusBG = self:getTemplateElement('EmergencyStatusBG')
        self.rEmergencyStatusText = self:getTemplateElement('EmergencyStatusText')
        self.rNameEditButton = self:getTemplateElement('NameEditButton')
        self.rNameEditTexture = self:getTemplateElement('NameEditTexture')

        self.rNameEditButton:addPressedCallback(self.onNameEditButtonPressed, self)

		-- stretch box + line to fill space where tabs could be
		self.rTabSpacer = self:getTemplateElement('TabBGSpacer')
		self.rTabLineSpacer = self:getTemplateElement('TabLineSpacer')
		-- read vars from layout to avoid data duplication
		self.nTabWidth = self:getExtraTemplateInfo('nTabWidth')
		self.nTabHeight = self:getExtraTemplateInfo('nTabHeight')
		self.nTabLineHeight = self:getExtraTemplateInfo('nTabLineHeight')

		self.rDoorStatusLabel = self:getTemplateElement('DoorStatusLabel')
		self.rDoorStatusText = self:getTemplateElement('DoorStatusText')

    end
	
	function Ob:getNumberOfTabs()
		if self.rObject and ObjectList.getObjType(self.rObject) == ObjectList.INVENTORYITEM then
            return 0
        end
        return 3
	end
    
    function Ob:refresh()
        if Ob.Parent.refresh then Ob.Parent.refresh(self) end
        self:setObject(self.rObject)
    end
	
	function Ob:adjustSpacer()
		local nTabs = self:getNumberOfTabs()
		-- shaded background
		self.rTabSpacer:setLoc(self.nTabWidth * nTabs, -420)
		self.rTabSpacer:setScl(self.nTabWidth * (5 - nTabs) + 3, self.nTabHeight)
		-- line that completes tab row
		self.rTabLineSpacer:setLoc(self.nTabWidth * nTabs, -420 - self.nTabHeight)
		self.rTabLineSpacer:setScl(self.nTabWidth * (5 - nTabs) + 3, self.nTabLineHeight)
	end

    function Ob:onTick(dt)
        self.rDescriptionText:setVisible(true)
        if not self.rObject then
			return
		end
        local bInvItem = ObjectList.getObjType(self.rObject) == ObjectList.INVENTORYITEM
        local rObject = self.rObject
		-- dynamically adjust spacer, tho right now this inspector's # of
		-- tabs is constant
		self:adjustSpacer()
		if rObject.bDestroyed then
			if g_GuiManager.newSideBar then
				g_GuiManager.newSideBar:closeSubmenu()
				--g_GuiManager.clearSelectionProp()
				g_GuiManager.setSelected(nil)
				SoundManager.playSfx('degauss')
			end
			return
		end
		if self.rNameText and not GameScreen.inTextEntry() then
            if bInvItem then
                self.rNameText:setString(rObject.sName)
			elseif rObject.tParams and rObject.tParams.spawnerName then
				self.rNameText:setString(rObject.tParams.spawnerName)
			elseif rObject.sFriendlyName then
				self.rNameText:setString(rObject.sFriendlyName)
			else
				self.rNameText:setString("")
			end
		end
        local sPortrait,sPortraitPath,nPortraitOffX,nPortraitOffY,nPortraitScl,sTintSprite,tTintColor
        if bInvItem then
            sPortrait,sPortraitPath,sTintSprite,tTintColor,nPortraitScl = Inventory.getPortrait(rObject)
        else
            sPortrait,sPortraitPath,sTintSprite,tTintColor,nPortraitScl = rObject.sPortrait,rObject.sPortraitPath,rObject.sPortraitTintSprite,rObject.sPortraitTintColor,rObject.nPortraitScl
            nPortraitOffX,nPortraitOffY = rObject.nPortraitOffX,rObject.nPortraitOffY
        end
        if sPortraitPath == 'Environments/Objects' then
            nPortraitOffX,nPortraitOffY = nPortraitOffX or -200, nPortraitOffY or -240
            nPortraitScl = nPortraitScl or 2
        end
        
		if sPortrait then
            -- MTF HACK: UI does TERRIBLE things do our sprite alignment if we let it screw with 
            -- the spritesheet, so we add it with some override params.
            if sPortraitPath == 'Environments/Objects' then
                self:addToUISpriteSheets(sPortrait, sPortraitPath, "left", "bottom")
            end
			self:setTemplateUITexture('Picture', sPortrait, sPortraitPath)
            
            local xOff,yOff = nPortraitOffX or 0, nPortraitOffY or 0
            local nPosX = self:_convertLayoutVal(self.rPicture.tElementInfo.pos[1])
            local nPosY = self:_convertLayoutVal(self.rPicture.tElementInfo.pos[2])
            self.rPicture:setLoc(nPosX+xOff, nPosY+yOff)
            self.rPicture:setScl(nPortraitScl or self.rPicture.tElementInfo.scale[1])
            
            if sTintSprite and tTintColor then
                self:setElementHidden(self.rPictureTint,false)
                self:setTemplateUITexture('PictureTint', sTintSprite, sPortraitPath)
                self.rPictureTint:setLoc(nPosX+xOff, nPosY+yOff)
                self.rPictureTint:setScl(nPortraitScl or self.rPicture.tElementInfo.scale[1])
                local r,g,b = unpack(tTintColor)
                self.rPictureTint:setColor(r,g,b,1)
            else
                self:setElementHidden(self.rPictureTint,true)
            end
        else
            self:setElementHidden(self.rPictureTint,true)
		end

		local sEmergency = not bInvItem and self.rObject:getEmergencyString()
        self:setElementHidden(self.rEmergencyStatusBG, not sEmergency)
        self:setElementHidden(self.rEmergencyStatusText, not sEmergency)
        self.rEmergencyStatusText:setString(sEmergency or '')

		local sString, tBarColor = EnvObject.getConditionUIString(rObject.nCondition)
		if sString and tBarColor then
            self.rConditionBG:setColor(unpack(tBarColor))
            self.rConditionText:setString(sString)
        else
            self.rConditionBG:setColor(unpack(Gui.AMBER))
            local rOwner = Inventory.getOwner(self.rObject)
            self.rConditionText:setString((rOwner and rOwner:getNiceName()) or '')
        end
		-- door status
		if rObject.isDoor and rObject:isDoor() then
			local Door = require('EnvObjects.Door')
			local lc
			if rObject.doorState == Door.doorStates.OPEN then
				lc = 'PROPSX056TEXT'
			elseif rObject.doorState == Door.doorStates.CLOSED then
				lc = 'PROPSX057TEXT'
			elseif rObject.doorState == Door.doorStates.LOCKED then
				-- vacuum-locked
				if rObject.bTouchesVacuum then
					lc = 'PROPSX052TEXT'
				else
					lc = 'PROPSX059TEXT'
				end
				-- "(Broken)" in parentheses if stuck open or closed
			elseif rObject.doorState == Door.doorStates.BROKEN_OPEN then
				lc = 'PROPSX052TEXT'
			elseif rObject.doorState == Door.doorStates.BROKEN_CLOSED then
				lc = 'PROPSX056TEXT'
			end
			self.rDoorStatusText:setString(rObject:getStatusString())
			self.rDoorStatusLabel:setVisible(true)
			self.rDoorStatusText:setVisible(true)
		else
			self.rDoorStatusLabel:setVisible(false)
			self.rDoorStatusText:setVisible(false)
		end
		self.rTabbedPane:onTick(dt)
	end

    function Ob:onFinger(touch, x, y, props)
        local bHandled = false
        if Ob.Parent.onFinger(self, touch, x, y, props) then
            bHandled = true
        end
        return bHandled
    end

    function Ob:inside(wx, wy)
        local bHandled = false
        if Ob.Parent.inside(self, wx, wy) then
            bHandled = true
        end
        bHandled = self.rTabbedPane:inside(wx, wy) or bHandled
        return bHandled
    end
	
    function Ob:show(nPri)
        local n = Ob.Parent.show(self, nPri)
		self.rTabbedPane:setTabSelectedByKey('ObjectActionTab')
        return n
    end
    
    function Ob:setSelectedInventoryItem(tItem)
        self:setObject(self.rObject, tItem)
    end
	
    function Ob:setObject(rObject, tContainedItem)
        if tContainedItem then
            self.rContainingObject = rObject
            self.rObject = tContainedItem
            rObject = self.rObject
        else
            self.rContainingObject = nil
        end
        
        if self.rObject ~= rObject then
            if GameScreen.inTextEntry() then
                GameScreen.endTextEntry()
            end
        end
        if ObjectList.getObjType(rObject) == ObjectList.INVENTORYITEM then
            self.rObjectStatsTab:setObject(nil)
            self.rObjectActionTab:setObject(nil)
            self.rObjectAboutTab:setObject(nil)
            self.rTabbedPane:hideTab('ObjectStatsTab')
            self.rTabbedPane:hideTab('ObjectActionTab')
            self.rTabbedPane:hideTab('ObjectAboutTab')
            self.rTabbedPane:setTabSelected(-1)
            --self:setElementHidden(self.rNameEditButton,true)
            self:setElementHidden(self.rNameEditTexture,true)
            self.rConditionLabel:setString(g_LM.line('INSPEC199TEXT'))
        else
            self.rObjectStatsTab:setObject(rObject)
            self.rObjectActionTab:setObject(rObject)
            self.rObjectAboutTab:setObject(rObject)
            self.rTabbedPane:revealTab('ObjectStatsTab')
            self.rTabbedPane:revealTab('ObjectActionTab')
            self.rTabbedPane:revealTab('ObjectAboutTab')
            --self:setElementHidden(self.rNameEditButton,false)
            self:setElementHidden(self.rNameEditTexture,false)
            self.rConditionLabel:setString(g_LM.line('INSPEC054TEXT'))
        end
		if not rObject then
			return
		end
        self.rObject = rObject
        if ObjectList.getObjType(rObject) == ObjectList.INVENTORYITEM then
            self.rDescriptionText:setString(Inventory.getDesc(rObject))
        else
            self.rDescriptionText:setString(rObject:getDescription())
        end
	end

    function Ob:onNameEditButtonPressed(rButton, eventType)
        if eventType == DFInput.TOUCH_UP and not GameScreen.inTextEntry() and self.rObject and ObjectList.getObjType(self.rObject) ~= ObjectList.INVENTORYITEM then
            GameScreen.beginTextEntry(self.rNameText, self, self.confirmTextEntry, self.cancelTextEntry)
			self.rNameEditButton:setSelected(true)
        end
    end
	
    function Ob:confirmTextEntry(text)
        if self.rObject and ObjectList.getObjType(self.rObject) ~= ObjectList.INVENTORYITEM then
            if self.rObject.tParams and self.rObject.tParams.spawnerName then
                self.rObject.tParams.spawnerName = text
            elseif self.rObject.sFriendlyName then
                self.rObject.sFriendlyName = text
            end
			self.rNameEditButton:setSelected(false)
        end
    end

	function Ob:cancelTextEntry(text)
		self.rNameEditButton:setSelected(false)
	end

    return Ob
end

function m.new(...)
    local Ob = m.create()
    Ob:init(...)

    return Ob
end

return m
