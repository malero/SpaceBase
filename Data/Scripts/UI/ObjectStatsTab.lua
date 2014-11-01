local m = {}

local DFUtil = require('DFCommon.Util')
local DFInput = require('DFCommon.Input')
local UIElement = require('UI.UIElement')

local sUILayoutFileName = 'UILayouts/ObjectStatsTabLayout'

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())
    Ob.rObject = nil

    function Ob:init()
        self:processUIInfo(sUILayoutFileName)
        Ob.Parent.init(self)

        self.rPowerLabel = self:getTemplateElement('PowerLabel')
        self.rPowerText = self:getTemplateElement('PowerText')
        self.rBuildTimeText = self:getTemplateElement('BuildTimeText')
        self.rBuilderText = self:getTemplateElement('BuilderText')
        self.rMaintainTimeText = self:getTemplateElement('MaintainTimeText')
        self.rMaintainerText = self:getTemplateElement('MaintainerText')
        self.rContentsIcon = self:getTemplateElement('ContentsIcon')
        self.rContentsLabel = self:getTemplateElement('ContentsLabel')
        self.tContentsText = {}
        for i=1,3 do
            table.insert(self.tContentsText, self:getTemplateElement('ContentsText'..i))
        end
        self.tContentsButton = {}
        for i=1,3 do
            table.insert(self.tContentsButton, self:getTemplateElement('ContentsButton'..i))
            self.tContentsButton[i]:addPressedCallback(function(rButton, eventType) self:onContentsButtonPressed(rButton,eventType,i) end)
        end
		
		-- handles for static elements we just need to show/hide
        self.rBuildTimeIcon = self:getTemplateElement('BuildTimeIcon')
        self.rBuildTimeLabel = self:getTemplateElement('BuildTimeLabel')
        self.rBuilderIcon = self:getTemplateElement('BuilderIcon')
        self.rBuilderLabel = self:getTemplateElement('BuilderLabel')
        self.rMaintainTimeIcon = self:getTemplateElement('MaintainTimeIcon')
        self.rMaintainTimeLabel = self:getTemplateElement('MaintainTimeLabel')
        self.rMaintainerIcon = self:getTemplateElement('MaintainerIcon')
        self.rMaintainerLabel = self:getTemplateElement('MaintainerLabel')
		
		-- clickable buttons
		self.rBuilderButton = self:getTemplateElement('BuilderButton')
		self.rMaintainerButton = self:getTemplateElement('MaintainerButton')
        self.rBuilderButton:addPressedCallback(self.onBuilderButtonPressed, self)
        self.rMaintainerButton:addPressedCallback(self.onMaintainerButtonPressed, self)
		-- get #s from layout data (unused since creation of about tab)
		self.nLineHeight = self:getExtraTemplateInfo('nLineSize')
    end
	
    function Ob:setObject(rObject,tContainedItem)
        self.rObject = rObject
		if not self.rObject then
			return
		end
		-- for things like bodybags, don't show "builder/maintainer" data at all
		if self.rObject.tData and self.rObject.tData.bDontShowBuilderData then
			self.rBuildTimeText:setVisible(false)
			self.rBuilderText:setVisible(false)
			self.rMaintainTimeText:setVisible(false)
			self.rMaintainerText:setVisible(false)
			self.rBuildTimeIcon:setVisible(false)
			self.rBuildTimeLabel:setVisible(false)
			self.rBuilderIcon:setVisible(false)
			self.rBuilderLabel:setVisible(false)
			self.rMaintainTimeIcon:setVisible(false)
			self.rMaintainTimeLabel:setVisible(false)
			self.rMaintainerIcon:setVisible(false)
			self.rMaintainerLabel:setVisible(false)
		else
			self.rBuildTimeText:setVisible(true)
			self.rBuilderText:setVisible(true)
			self.rMaintainTimeText:setVisible(true)
			self.rMaintainerText:setVisible(true)
			self.rBuildTimeIcon:setVisible(true)
			self.rBuildTimeLabel:setVisible(true)
			self.rBuilderIcon:setVisible(true)
			self.rBuilderLabel:setVisible(true)
			self.rMaintainTimeIcon:setVisible(true)
			self.rMaintainTimeLabel:setVisible(true)
			self.rMaintainerIcon:setVisible(true)
			self.rMaintainerLabel:setVisible(true)
		end
    end
	
	function Ob:onBuilderButtonPressed(rButton, eventType)
		if eventType == DFInput.TOUCH_UP then
			g_GuiManager.selectCharByID(self.rObject.sBuilderName)
		end
	end
	
	function Ob:onBuilderButtonPressed(rButton, eventType)
		if eventType == DFInput.TOUCH_UP then
			g_GuiManager.selectCharByID(self.rObject.sBuilderName)
		end
	end
	
	function Ob:onMaintainerButtonPressed(rButton, eventType)
		if eventType == DFInput.TOUCH_UP then
			g_GuiManager.selectCharByID(self.rObject.sLastMaintainer)
		end
	end
    
	function Ob:onContentsButtonPressed(rButton, eventType, idx)
		if eventType == DFInput.TOUCH_UP and self.rObject then
            local tContents = self.rObject.getContentsTextTable and self.rObject:getContentsTextTable()
            local sKey = self.tContentsText[idx].sItemKey
            local tItem = sKey and self.rObject.tInventory and self.rObject.tInventory[sKey] 
            if tItem then
                g_GuiManager.newSideBar.rInspectMenu.rObjectInspector:setSelectedInventoryItem(tItem)
            end
		end
	end
	
    function Ob:onTick(dt)
        if not self.rObject then
			return
		end
		-- disable clickable buttons, re-enable later if applicable
		self.rBuilderButton:setEnabled(false)
		self.rMaintainerButton:setEnabled(false)
		-- power draw/output
		local sLabel = g_LM.line('INSPEC164TEXT')
        local sPower=''
        if self.rObject.tData then
            sPower = tostring(self.rObject.tData.nPowerDraw or 0)
            if self.rObject.tData.nPowerOutput then
                sLabel = g_LM.line('INSPEC165TEXT')
                sPower = tostring(self.rObject.tData.nPowerOutput)
            end
        end
		self.rPowerLabel:setString(sLabel)
		self.rPowerText:setString(sPower..' '..g_LM.line('INSPEC166TEXT'))
		-- builder/build time, maintainer/maintain time
		local CharacterManager = require('CharacterManager')
		if CharacterManager.getCharacterByUniqueID(self.rObject.sBuilderName) then
			self.rBuilderButton:setEnabled(true)
		end
		if CharacterManager.getCharacterByUniqueID(self.rObject.sLastMaintainer) then
			self.rMaintainerButton:setEnabled(true)
		end
		self.rBuildTimeText:setString(self.rObject.sBuildTime or '????.??')
		self.rBuilderText:setString((self.rObject.getBuilderName and self.rObject:getBuilderName()) or '')
		self.rMaintainTimeText:setString(self.rObject.sLastMaintainTime or 'n/a')
		self.rMaintainerText:setString((self.rObject.getMaintainerName and self.rObject:getMaintainerName()) or '')
        local tContents = self.rObject.getContentsTextTable and self.rObject:getContentsTextTable()
		if tContents and #tContents > 0 then
            local i=1
            local n=math.min(#tContents,#self.tContentsText)
            self:setElementHidden(self.rContentsIcon,false)
            self:setElementHidden(self.rContentsLabel,false)
            while i <= n do
                self.tContentsText[i]:setString(tContents[i].str)
                self.tContentsText[i].sItemKey = tContents[i].key
                self:setElementHidden(self.tContentsText[i],false)
                self:setElementHidden(self.tContentsButton[i],false)
                i=i+1
            end
            while i <= #self.tContentsText do
                self.tContentsText[i]:setString('')
                self.tContentsText[i]:setVisible(false)
                self:setElementHidden(self.tContentsText[i],true)
                self:setElementHidden(self.tContentsButton[i],true)
                i=i+1
            end
		else
			-- hide contents label, icon, etc
            for i=1,#self.tContentsText do
                self:setElementHidden(self.tContentsText[i],true)
                self:setElementHidden(self.tContentsButton[i],true)
            end
            self:setElementHidden(self.rContentsIcon,true)
            self:setElementHidden(self.rContentsLabel,true)
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