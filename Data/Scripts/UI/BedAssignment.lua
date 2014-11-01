local m = {}

local DFUtil = require("DFCommon.Util")
local UIElement = require('UI.UIElement')
local DFInput = require('DFCommon.Input')
local ScrollableUI = require('UI.ScrollableUI')
local TemplateButton = require('UI.TemplateButton')
local SoundManager = require('SoundManager')
local Room = require('Room')
local Character = require('CharacterConstants')
local EnvObject = require('EnvObjects.EnvObject')

local sUILayoutFileName = 'UILayouts/BedAssignmentLayout'

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())

    function Ob:init()
        Ob.Parent.init(self)
        self.tBedEntries = {}
        self:processUIInfo(sUILayoutFileName)
        self.rCancelButton = self:getTemplateElement('CancelButton')
        self.rCancelButton:addPressedCallback(self.onCancelButtonPressed, self)
        self.tHotkeyButtons = {}
		self.tResearchZoneEntries = {}
        self.rZoneScrollableUI = self:getTemplateElement('ZoneScrollPane')
		self.rZoneScrollableUI:setRenderLayer('UIScrollLayerLeft')
        
        self.rZoneScrollableUI:setScissorLayer('UIScrollLayerLeft')
    end
    
    function Ob:show(basePri)
        if g_GameRules.getTimeScale() ~= 0 then
            self.bWasPaused = false
            g_GameRules.togglePause()
        else
            self.bWasPaused = true
        end
        local w = g_GuiManager.getUIViewportSizeY()
        g_GuiManager.createEffectMaskBox(0, 0, 1800, w, 0.3, 0.3)

        local nPri = Ob.Parent.show(self, basePri)
        self.rZoneScrollableUI:reset()
		-- hide status bar behind us
		g_GuiManager.statusBar:hide()
		g_GuiManager.hintPane:hide()
		g_GuiManager.alertPane:hide()
        return nPri
    end

    function Ob:hide(bKeepAlive)
        if g_GameRules.getTimeScale() == 0 and not self.bWasPaused then
            g_GameRules.togglePause()
        end
        Ob.Parent.hide(self, bKeepAlive)
		-- show status bar etc
		g_GuiManager.statusBar:show()
		g_GuiManager.hintPane:show()
		g_GuiManager.alertPane:show()
    end

    -- returns true if key was handled
    function Ob:onKeyboard(key, bDown)
        local bHandled = false
        if bDown then
            if key == 27 then -- esc
                self:cancel()
                bHandled=true
            end
        end
        return bHandled
    end
    
    function Ob:cancel()
        g_GuiManager.newSideBar:closeSubmenu()
    end
    
    function Ob:onCancelButtonPressed(rButton, eventType)
        if eventType == DFInput.TOUCH_UP then
            self:cancel()
        end
    end
    
    --[[
    function Ob:show(basePri)
        if g_GameRules.getTimeScale() ~= 0 then
            self.bWasPaused = false
            g_GameRules.togglePause()
        else
            self.bWasPaused = true
        end
        local w,h = g_GuiManager.getUIViewportSizeX(), g_GuiManager.getUIViewportSizeY()
        g_GuiManager.createEffectMaskBox(0, 0, 1800, w, 0.3, 0.3)
        local nPri = Ob.Parent.show(self, basePri)
        self.rProjectScrollableUI:reset()
        self.rZoneScrollableUI:reset()
        
		-- hide status bar behind us
		g_GuiManager.statusBar:hide()
		g_GuiManager.hintPane:hide()
		g_GuiManager.alertPane:hide()
        return nPri
    end
    ]]--
	
    --[[
    function Ob:hide(bKeepAlive)
        if g_GameRules.getTimeScale() == 0 and not self.bWasPaused then
            g_GameRules.togglePause()
        end
        Ob.Parent.hide(self, bKeepAlive)
        self.rProjectScrollableUI:hide()
        for i, rEntry in ipairs(self.tResearchZoneEntries) do
            rEntry:hide(bKeepAlive)
        end
		-- show status bar etc
		g_GuiManager.statusBar:show()
		g_GuiManager.hintPane:show()
		g_GuiManager.alertPane:show()
    end
    ]]--
	
    function Ob:onTick(dt)
        --local rChar = g_GuiManager.getSelectedCharacter()
        local tRooms = Room.getRoomsOfTeam(Character.TEAM_ID_PLAYER, false, 'RESIDENCE', true)
        local i=1
        for nRoom,rRoom in ipairs(tRooms) do
            local bFirst=true
            local tProps = rRoom:getPropsOfName('Bed')
            for rProp,_ in pairs(tProps) do
                self:setBedEntry(i,rRoom,rProp,bFirst)
                bFirst=false
                i=i+1
            end
        end
        local n = #self.tBedEntries
        while i<n do
            self:setBedEntry(i,nil,nil,false)
            i=i+1
        end
        
        self.rZoneScrollableUI:refresh()
    end
	
	function Ob:addBedEntry()
        local rButton = TemplateButton.new()
        rButton:setLayoutFile('UILayouts/ResearchZoneButtonLayout')
		rButton:setButtonName('Button')
		self.rZoneScrollableUI:addScrollingItem(rButton)
        table.insert(self.tBedEntries,rButton)
        
        rButton:addPressedCallback(self.onBedButtonPressed, self)
        --self:_calcDimsFromElements()
	end

    function Ob:setBedEntry(nIdx, rRoom,rObj,bBig)
        local h = 90
		local y = -h * (nIdx - 1)
        local rButton = self.tBedEntries[nIdx]
        if not rButton then
            self:addBedEntry()
            rButton = self.tBedEntries[nIdx]
        end
        self:setElementHidden(rButton, rRoom == nil)
        rButton.rObj = rObj
        rButton.rRoom = rRoom
        if not rRoom then return end

        local rOwner = rObj:getOwner()
        local rChar = g_GuiManager.getSelectedCharacter()
        rButton:setSelected(rChar and rOwner == rChar)
        rButton:setElementHidden(rButton:getTemplateElement('ZoneNameBubbleLeft'), not bBig)
        rButton:setElementHidden(rButton:getTemplateElement('ZoneNameBubbleMid'), not bBig)
        --rButton:getTemplateElement('ProjectName'):setString(rObj.sName)
        rButton:getTemplateElement('ProjectName'):setString((rOwner and rOwner:getNiceName()) or g_LM.line('INSPEC160TEXT'))

        if bBig then
            rButton:getTemplateElement('ZoneName'):setString(rRoom.uniqueZoneName)
        end
        rButton:setLoc(0,y)
    end

    function Ob:onBedButtonPressed(rButton)
        local rChar = g_GuiManager.getSelectedCharacter()
        if rChar and rButton.rObj then
            rButton.rObj:setOwner(rChar)
            self:cancel()
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
