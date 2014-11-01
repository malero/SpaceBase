local m = {}

local DFUtil = require("DFCommon.Util")
local UIElement = require('UI.UIElement')
--local ScrollableUI = require('UI.ScrollableUI')
local HintEntry = require('UI.HintEntry')
local Hint = require('Hint')
local DFInput = require('DFCommon.Input')
local SoundManager = require('SoundManager')

local sUILayoutFileName = 'UILayouts/HintPaneLayout'

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())
    Ob.tEntries = {}
    Ob.kMAX_ENTRIES = 20
    Ob.rEntryClass = require('UI.HintEntry')

    function Ob:init()
        self:processUIInfo(sUILayoutFileName)
        Ob.Parent.init(self)
        self.bZebraColor = true
		self.tAltColor = require('UI.Gui').HINTLOG_BG_ALT
        self.nLastDisplayed = 0

        for i = 1, self.kMAX_ENTRIES do
            local rHintEntry = self.rEntryClass.new(self)
            self:addElement(rHintEntry)
            table.insert(self.tEntries, rHintEntry)
        end

        self.rButton = self:getTemplateElement('Button')
        self.rButton:addPressedCallback(self.onButtonPressed, self)
        self.rButtonLabel = self:getTemplateElement('ButtonLabel')        
        self.nNumEntries = 0
    end

    function Ob:_getAlertsToDisplay()
        return Hint.getAllActiveHints()
    end
    
    function Ob:onTick(dt)
        if not self:isVisible() then
            return
        end

        local tAlerts = self:_getAlertsToDisplay()

        if self.nLastDisplayed < #tAlerts then
            self:setMaximized(true)
        end

        self:setElementHidden(self.rButton,#tAlerts == 0)
        self:setElementHidden(self.rButtonLabel,#tAlerts == 0)
        self.nLastDisplayed = #tAlerts
        local nNumEntries = 0
        local nCurY = 0
        for i, rEntry in ipairs(self.tEntries) do
            if not self.bMaximize or not tAlerts[i] then
                self:setElementHidden(rEntry,true)
                rEntry:setAlert(nil)
            elseif tAlerts[i] then
                if rEntry.onTick then 
                    rEntry:onTick(dt)
                end
                self:setElementHidden(rEntry,false)
                rEntry:setAlert(tAlerts[i])
                nNumEntries = nNumEntries + 1
                local w,h = rEntry:getDims()
                rEntry:setLoc(0,nCurY)
                nCurY = nCurY + h
				-- zebra-color alt entries
				if self.bZebraColor and i % 2 == 0 and self.tAltColor then
					rEntry.rButton:setColor(unpack(self.tAltColor))
					rEntry.bAltColor = true
				elseif i % 2 ~= 0 then
					rEntry.bAltColor = false
				end
            end
        end
        self.nContentMax = nCurY
        if nNumEntries > self.nNumEntries then
            self:setMaximized(true)
        end
        if nNumEntries == 0 and self.bMaximize then
            self:setMaximized(false)
        end
        self.nNumEntries = nNumEntries
        --self:setScrollListPos()
    end

	function Ob:shutdown()
		-- called from GuiManager.shutdown to clear out state
		-- on GameRules.loadGame
		self.nNumEntries = 0
	end
	
    function Ob:getDims()
        local nYSize = -30 -- need to set this as the icon size
        --local w,h = self.rScrollableUI:getDims()
        local w,_ = self.tEntries[1]:getDims()
        if self.bMaximize then
            nYSize = nYSize + (self.nContentMax or 0)
        else
            nYSize = nYSize - 40
        end

        return w,nYSize
    end

    function Ob:show(nMaxPri)
        if g_Config:getConfigValue("low_ui") then
            return nMaxPri
        else
            local nPri = nMaxPri
            nPri = Ob.Parent.show(self, nMaxPri)
            self.bMaximize = true
            self:setMaximized(false)
            self:onTick(0)
            return nPri
        end
    end

    function Ob:isMaximized()
        return self:isVisible() and self.bMaximize
    end

    function Ob:playWarbleEffect()
        local x, y = self:getLoc()
        g_GuiManager.createEffectMaskBox(x-50, -y, 600, 1500, 0.3, 0.3)
    end
    
    function Ob:setMaximized(bMaximize)
        if bMaximize and #self:_getAlertsToDisplay() == 0 then return end
        
        self:playWarbleEffect()        
        if g_GuiManager.bFinishedInit and bMaximize then
            SoundManager.playSfx('inspectorshow')
        end
        if self.bMaximize ~= bMaximize then
            if bMaximize then
                local maximizeOverride = self:getExtraTemplateInfo('maximizedOverride')
                self:applyTemplateInfos(maximizeOverride)
            else
                local minimizeOverride = self:getExtraTemplateInfo('minimizedOverride')
                self:applyTemplateInfos(minimizeOverride)
            end
            self.bMaximize = bMaximize
        end
    end

    function Ob:onButtonPressed(rButton, eventType)
        if eventType == DFInput.TOUCH_UP then
            self:setMaximized(not self.bMaximize)
        end
    end

    function Ob:getMaxY()
        local w, h = self:getDims()
        local x, y = self:getLoc()
        return y + h
    end

    return Ob
end

function m.new(...)
    local Ob = m.create()
    Ob:init(...)

    return Ob
end

return m
