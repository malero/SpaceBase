local m = {}

local DFUtil = require("DFCommon.Util")
local UIElement = require('UI.UIElement')
local DFInput = require('DFCommon.Input')
local ObjectList = require('ObjectList')
local GameRules = require('GameRules')
local Delegate = require('DFMoai.Delegate')
local Gui = require('UI.Gui')

local sUILayoutFileName = 'UILayouts/AlertEntryLayout'

m.dOnClick = Delegate.new()

local kYMARGIN = 16
local kBOTTOM_MARGIN = 28
local kTIME_OFFSET = 10

local kSECOND_SINGULAR_LINE = "HUDHUD028TEXT"
local kSECOND_PLURAL_LINE = "HUDHUD029TEXT"
local kMINUTE_SINGULAR_LINE = "HUDHUD030TEXT"
local kMINUTE_PLURAL_LINE = "HUDHUD031TEXT"
local kSPACEDATE_LINE = "HUDHUD004TEXT"
local kREALTIME_THRESH = 10

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())
    Ob.rAlert = nil

    function Ob:init(rAlertPane)
        self.rAlertPane = rAlertPane

        self:processUIInfo(sUILayoutFileName)
        Ob.Parent.init(self)

        self.rButton = self:getTemplateElement('Button')
        --self.rButtonBG = self:getTemplateElement('ButtonBG')
        self.rAlertText = self:getTemplateElement('AlertText')
        self.rTimeText = self:getTemplateElement('TimeText')

        self.rButton:addPressedCallback(self.onButtonPressed, self)

        self.nOrigButtonScaleX, self.nOrigButtonScaleY = self.rButton:getScl()
--        self.nOrigButtonBGScaleX, self.nOrigButtonBGScaleY = self.rButtonBG:getScl()
        self.nOrigTimeTextX, self.nOrigTimeTextY = self.rTimeText:getLoc()

        self.sSecondSingularLine = g_LM.line("HUDHUD028TEXT")
        self.sSecondPluralLine = g_LM.line("HUDHUD029TEXT")
        self.sMinuteSingularLine = g_LM.line("HUDHUD030TEXT")
        self.sMinutePluralLine = g_LM.line("HUDHUD031TEXT")
        self.sSpaceDateLine = g_LM.line("HUDHUD004TEXT")
    end

    function Ob:setAlert(rAlert)
        if self.rAlert == rAlert and (not rAlert or self.nCachedPriority == rAlert.nPriority) then return end
        self.rAlert = rAlert
        self.nCachedPriority = rAlert and rAlert.nPriority
        if not rAlert then
			return
		end
		if rAlert.sCurrentAlertString then
			self.rAlertText:setString(rAlert.sCurrentAlertString)
			self:resize()
		end
		if rAlert.nPriority > 0 then
			self.rButton.tElementInfo.onHoverOff[1].color = Gui.ALERTLOG_BG
			self.rButton:refresh()
		else
			self.rButton.tElementInfo.onHoverOff[1].color = Gui.ALERTLOG_LOWPRI_BG
			self.rButton:refresh()
		end
    end
	
    function Ob:onTick(dt)
        if not self.rAlert then
			return
		end
		local sString = ""
		local nElapsedTime = GameRules.elapsedTime - self.rAlert.nLastUpdated
		if nElapsedTime > kREALTIME_THRESH then
			sString = self.sSpaceDateLine.." "..tostring(self.rAlert.nLastUpdatedStarDate)
		else
			local nMinutes = math.floor(nElapsedTime / 60)
			local nSeconds = math.floor(nElapsedTime % 60)
			if nMinutes > 1 then
				sString = nMinutes.." "..self.sMinutePluralLine
			elseif nMinutes == 1 then
				sString = nMinutes.." "..self.sMinuteSingularLine
			elseif nSeconds > 1 then
				sString = nSeconds.." "..self.sSecondPluralLine
			else
				sString = nSeconds.." "..self.sSecondSingularLine
			end
		end
		if self.rAlert.sCurrentAlertString then
			self.rAlertText:setString(self.rAlert.sCurrentAlertString)
		end
		self.rTimeText:setString(sString)
		-- if high priority, pulse color
		if self.rAlert.nPriority > 0 then
			local r,g,b = unpack(Gui.ALERTLOG_BG)
			if self.bAltColor then
				r,g,b = unpack(Gui.ALERTLOG_BG_ALT)
			end
			local nPulse = math.abs(math.sin(GameRules.elapsedTime * 1.5)) / 2 + 0.75
			r = r * nPulse
			g = g * nPulse
			b = b * nPulse
			self.rButton:setColor(r,g,b)
		end
    end
	
    function Ob:getDims()
        return self.rButton:getDims()
    end

    function Ob:resize()
        if self.rAlert and self.rAlert.sCurrentAlertString then
            local x0, y0, x1, y1 = self.rAlertText:getStringBounds(1, string.len(self.rAlert.sCurrentAlertString))
            local nYSize,nYScale = 0,0
            if y1 then
                nYSize = math.abs(y1 - y0)
                nYScale = kYMARGIN * 2
                nYScale = nYScale + nYSize
            end
            self.rButton:setScl(self.nOrigButtonScaleX, nYScale + kBOTTOM_MARGIN)
            --self.rButtonBG:setScl(self.nOrigButtonBGScaleX, nYScale + kBOTTOM_MARGIN)
			local nButtonX, nButtonY = self.rButton:getLoc()
            self.rTimeText:setLoc(self.nOrigTimeTextX, nButtonY - nYScale + kTIME_OFFSET)
        end
    end

    function Ob:isActive()
        if self.rAlert then
            return true
        else
            return false
        end
    end

    function Ob:onButtonPressed(rButton, eventType)
        if eventType == DFInput.TOUCH_UP then
            if self.rAlert then
                if self.rAlert.reporterTag and self.rAlert.reporterTag.bInvalid then
                    self.rAlert.reporterTag = nil
                end
                if self.rAlert.reporterTag then
                        local obj = ObjectList.getObject(self.rAlert.reporterTag)
                        if obj then
                            g_GuiManager.setSelected(obj)
                            g_GameRules.setCamTrackEnabled(true)
                        end
                elseif self.rAlert.wx and self.rAlert.wy then
                    g_GameRules.setCamTrackEnabled(false) -- if we're locked on someone, break the lock.  we should do the character lock better : KSC
                    g_GameRules.setCameraLoc(self.rAlert.wx, self.rAlert.wy, nil)
                end

                m.dOnClick:dispatch(self.rAlert)
            end
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
