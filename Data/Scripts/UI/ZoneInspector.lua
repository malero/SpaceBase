local m = {}

local DFUtil = require("DFCommon.Util")
local UIElement = require('UI.UIElement')
local DFInput = require('DFCommon.Input')
local TabbedPane = require('UI.TabbedPane')
local TemplateButton = require('UI.TemplateButton')
local ZoneRezoneTab = require('UI.ZoneRezoneTab')
local ZoneStatsTab = require('UI.ZoneStatsTab')
local ZoneSpecificTab = require('UI.ZoneSpecificTab')
local ZoneActionTab = require('UI.ZoneActionTab')
local GameScreen = require('GameScreen')
local Gui = require('UI.Gui')
local Character = require('CharacterConstants')

local sUILayoutFileName = 'UILayouts/ZoneInspectorLayout'

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())
    Ob.rRoom = nil
    Ob.bDoRolloverCheck = true

    function Ob:init()
        Ob.Parent.init(self)

        self:processUIInfo(sUILayoutFileName)

        self.rZoneStatsTab = ZoneStatsTab.new()
        self.rZoneRezoneTab = ZoneRezoneTab.new()
        self.rZoneActionTab = ZoneActionTab.new()
        self.rZoneSpecificTab = ZoneSpecificTab.new()
		self.rZoneActionTab.rZoneInspector = self

        self.rTabbedPane = self:getTemplateElement('TabbedPane')
        local tIcons={'ui_icon_stats','ui_icon_zoning','ui_icon_activity','ui_icon_research'}
        local tButtons = {}
        for i,v in ipairs(tIcons) do
            tButtons[i] = TemplateButton.new()
            tButtons[i]:setReplacements('Icon',{textureName=v})
            tButtons[i]:setLayoutFile('UILayouts/IconTabLayout')
            tButtons[i]:setButtonName('TabButton')
        end
        self.rTabbedPane:addTab(self.rZoneStatsTab, 'ZoneStatsTab', true, tButtons[1])
        self.rTabbedPane:addTab(self.rZoneRezoneTab, 'ZoneRezoneTab', true, tButtons[2])
        self.rTabbedPane:addTab(self.rZoneActionTab, 'ZoneActionTab', true, tButtons[3])
        self.rTabbedPane:addTab(self.rZoneSpecificTab, 'ZoneSpecificTab', true, tButtons[4])

        self.tTabButtons = tButtons

        self.rNameText = self:getTemplateElement('NameLabel')
        self.rNameEditBG = self:getTemplateElement('NameEditBG')
        self.rAlertText = self:getTemplateElement('AlertLabel')
        self.rDescriptionText = self:getTemplateElement('DescriptionText')
        self.rNameEditButton = self:getTemplateElement('NameEditButton')
		
		-- stretch box + line to fill space where tabs could be
		self.rTabSpacer = self:getTemplateElement('TabBGSpacer')
		self.rTabLineSpacer = self:getTemplateElement('TabLineSpacer')
		-- read vars from layout to avoid data duplication
		self.nTabWidth = self:getExtraTemplateInfo('nTabWidth')
		self.nTabHeight = self:getExtraTemplateInfo('nTabHeight')
		self.nTabLineHeight = self:getExtraTemplateInfo('nTabLineHeight')
		
        self.rNameEditButton:addPressedCallback(self.onNameEditButtonPressed, self)
    end

    function Ob:onTick(dt)
		if self.rRoom:getTeam() ~= Character.TEAM_ID_PLAYER then
			self.rTabbedPane:hideTab('ZoneRezoneTab')
			if self.rRoom.zoneObj.sZoneInspector then
				self.rTabbedPane:hideTab('ZoneSpecificTab')
			end
		else
			self.rTabbedPane:revealTab('ZoneRezoneTab')
			if self.rRoom.zoneObj.sZoneInspector then
				self.rTabbedPane:revealTab('ZoneSpecificTab')
			end
		end
        self.rTabbedPane:onTick(dt)
        if not self.rRoom then
			return
		end
		if self.rNameText then
			if not GameScreen.inTextEntry() then
				self.rNameText:setString(self.rRoom.uniqueZoneName)
			end
			local str = self.rRoom:getAlertString()
			self.rAlertText:setString(str or '')
		end
		if self.rRoom.sPortrait then
			self:setTemplateUITexture('Picture', self.rRoom.sPortrait, self.rRoom.sPortraitPath)
		end
    end

    function Ob:onNameEditButtonPressed(rButton, eventType)
        if eventType == DFInput.TOUCH_UP and not GameScreen.inTextEntry() then
            GameScreen.beginTextEntry(self.rNameText, self, self.confirmTextEntry, self.cancelTextEntry)
			self.rNameEditButton:setSelected(true)
        end
    end

    function Ob:confirmTextEntry(text)
        if self.rRoom then
            self.rRoom.uniqueZoneName = text
			self.rNameEditButton:setSelected(false)
        end
    end

	function Ob:cancelTextEntry(text)
		self.rNameEditButton:setSelected(false)
	end

    function Ob:onFinger(touch, x, y, props)
        local bHandled = false
        if Ob.Parent.onFinger(self, touch, x, y, props) then
            bHandled = true
        end
        return bHandled
    end

    function Ob:inside(wx, wy)
        local bHandled = Ob.Parent.inside(self, wx, wy)
        bHandled = self.rTabbedPane:inside(wx, wy) or bHandled
    end

    --[[
    function Ob:show(nPri)
        local nPri = Ob.Parent.show(self, nPri)
		-- if unzoned, show zoning tab first, else show command tab
		if self.rRoom and self.rRoom:getZoneName() == 'PLAIN' then
			self.rTabbedPane:setTabSelectedByKey('ZoneRezoneTab')
		else
			self.rTabbedPane:setTabSelectedByKey('ZoneActionTab')
		end
        return nPri
    end
    ]]--
	
	function Ob:getNumberOfTabs()
		if not self.rRoom then
			return 0
		end
		local nTabs = 2
		-- claimed?
		if self.rRoom:getTeam() == Character.TEAM_ID_PLAYER then
			nTabs = nTabs + 1
		end
		-- zone-specific tab?
		if self.rRoom.zoneObj.sZoneInspector then
			nTabs = nTabs + 1
		end
		return nTabs
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
	
    function Ob:setRoom(rRoom)
        local bChanged = self.rRoom ~= rRoom
        if bChanged then
            if GameScreen.inTextEntry() then
                GameScreen.endTextEntry()
            end
        end
        self.rRoom = rRoom
        self.rZoneStatsTab:setRoom(rRoom)
        self.rZoneRezoneTab:setRoom(rRoom)
		self.rZoneActionTab:setRoom(rRoom)

        if bChanged then
            if self.rRoom and self.rRoom:getZoneName() == 'PLAIN' then
                self.rTabbedPane:setTabSelectedByKey('ZoneRezoneTab')
            else
                self.rTabbedPane:setTabSelectedByKey('ZoneActionTab')
            end         
        end   

        if self.rRoom and self.rRoom.zoneObj.sZoneInspector then
            if not self.rTabbedPane:hasTab('ZoneSpecificTab') then
                self.rTabbedPane:addTab(self.rZoneSpecificTab, 'ZoneSpecificTab', true, self.tTabButtons[4])
            end
            self.rZoneSpecificTab:setRoom(rRoom)
            self.rTabbedPane:setElementHidden(self.rZoneSpecificTab,false)
			self:adjustSpacer()
            if bChanged then
				-- if zone specific tab exists, default to that
				self.rTabbedPane:setTabSelectedByKey('ZoneSpecificTab')
            end
        else
            if self.rTabbedPane:hasTab('ZoneSpecificTab') then
                self.rTabbedPane:removeTab('ZoneSpecificTab')
            end
			self:adjustSpacer()
        end
		if not self.rRoom then
			return
		end
		local rDef = self.rRoom:getZoneDef()
		local sDescription = ""
		if rDef.description then
			sDescription = g_LM.line(rDef.description)
		end
		self.rDescriptionText:setString(sDescription)
    end

    function Ob:onResize()
        Ob.Parent.onResize(self)
        self.rTabbedPane:onResize()
    end

    return Ob
end

function m.new(...)
    local Ob = m.create()
    Ob:init(...)

    return Ob
end

return m
