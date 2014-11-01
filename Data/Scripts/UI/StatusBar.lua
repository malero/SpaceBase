local m = {}

local DFUtil = require("DFCommon.Util")
local DFInput = require('DFCommon.Input')
local UIElement = require('UI.UIElement')
local Renderer = require('Renderer')
local GameRules = require('GameRules')
local CharacterManager = require('CharacterManager')
local SoundManager = require('SoundManager')
local Gui = require('UI.Gui')
local TemplateButton = require('UI.TemplateButton')
local GameScreen=require('GameScreen')
local sUILayoutFileName = 'UILayouts/StatusBarLayout'
local Character = require('Character')

local tMatterCountRateMultiplier = -- needs to be in order of max
{
    { nMax = 500, nCounterMultiplier = 1 },
    { nMax = 1500, nCounterMultiplier = 2 },
    { nMax = 2500, nCounterMultiplier = 4 },
    { nCounterMultiplier = 6 },
}

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())

    function Ob:init()
        Ob.Parent.init(self)
        
        self.sCounterTickSound = 'mattercounter'
        self.nCounterTickIncrement = 2
        self.nCounterTickMult = 1
        
        self.nextCharacter = 1

        self.mix = 1030
        self.cix = 1210
        --self.style = "gothicSmallTitle"
        self.style = "statusBar"

        self.debugText = self:addTextBox("", "nevisSmallTitle",0,0,1000,100,0,-215)
        self.tileTipText = self:addTextBox("", "nevisSmallTitle",0,0,800,100,-240,-115)
        --self.tileTipText:setString("TEST this is a test there might be a thing here")
        --self.debugText:setString("SOME debug text asdfasdf")
        
        -- counter values that lerp up/down to show change in "real" figure
        self.nMatterCount = g_GameRules:getMatter() or 0
        
        self.tileTipRefreshTime = 150
        self.tileTipTimeBeforeClear = self.tileTipRefreshTime

        self:processUIInfo(sUILayoutFileName)

        self.rTimePauseButton = self:getTemplateElement('PauseButton')
        self.rSpeed1Button = self:getTemplateElement('Speed1Button')
        self.rSpeed2Button = self:getTemplateElement('Speed2Button')
        self.rSpeed3Button = self:getTemplateElement('Speed3Button')
        self.rOxygenButton = self:getTemplateElement('OxygenButton')
        assertdev(self.rOxygenButton.clickWhileHidden)
        self.rWallButton = self:getTemplateElement('WallButton')
        self.rZoomoutButton = self:getTemplateElement('ZoomoutButton')
        self.rZoominButton = self:getTemplateElement('ZoominButton')
        self.rFlipButton = TemplateButton.new()
        self.rFlipButton:setLayoutFile('UILayouts/FlipZone')
        self.rFlipButton:setButtonName('FlipButton')
        self:addElement(self.rFlipButton)
        self:setElementHidden(self.rFlipButton,true)

		self.rCapacityText = self:getTemplateElement('CapacityText')
		self.rCapacityIcon = self:getTemplateElement('CapacityIcon')
		self.rCapacityLabel = self:getTemplateElement('CapacityLabel')

        self.rTimePauseButton:addPressedCallback(self.onTimeButtonPressed, self)
        self.rSpeed1Button:addPressedCallback(self.onTimeButtonPressed, self)
        self.rSpeed2Button:addPressedCallback(self.onTimeButtonPressed, self)
        self.rSpeed3Button:addPressedCallback(self.onTimeButtonPressed, self)
        self.rOxygenButton:addPressedCallback(self.onOxygenButtonPressed, self)
        self.rWallButton:addPressedCallback(self.onWallButtonPressed, self)
        self.rZoomoutButton:addPressedCallback(self.onZoomButtonPressed, self)
        self.rZoominButton:addPressedCallback(self.onZoomButtonPressed, self)
        self.rFlipButton:addPressedCallback(self.onFlipButtonPressed, self)

        self:showFlipZone(false)
        g_GameRules.dGameLoaded:register(function() self.nMatterCount = g_GameRules:getMatter() or 0 end)
    end
	
    function Ob:setDebugString(str)
        self.debugText:setString(str)
    end

    function Ob:setTileTipText(str)
        --last clicked
        self.tileTipText:setString(g_LM.line("HUDHUD001TEXT").." "..str)
        self.tileTipTimeBeforeClear = self.tileTipRefreshTime
    end

    function Ob:checkTileTipTime(dt)
        self.tileTipTimeBeforeClear = self.tileTipTimeBeforeClear - dt
        if self.tileTipTimeBeforeClear < 0 then
            self.tileTipText:setString("")
            self.tileTipTimeBeforeClear = self.tileTipRefreshTime
        end
    end

    function Ob:onMatterChanged(nNewMatter)
        if nNewMatter then
            local nDelta = math.abs(self.nMatterCount - nNewMatter)
            if nDelta > 0 then
                for i, tRateInfo in ipairs(tMatterCountRateMultiplier) do
                    if tRateInfo.nMax then
                        if nDelta < tRateInfo.nMax then
                            self.nCounterTickMult = tRateInfo.nCounterMultiplier
                            break
                        end
                    else
                        self.nCounterTickMult = tRateInfo.nCounterMultiplier
                    end
                end
            end
        end
    end

    function Ob:tickMatterCount()
        local nIncrement = self.nCounterTickMult * self.nCounterTickIncrement
        if g_GameRules:getMatter() > self.nMatterCount then
            -- snap if close enough
            if g_GameRules:getMatter() - self.nMatterCount < nIncrement then
                self.nMatterCount = g_GameRules:getMatter()
            else
                self.nMatterCount = self.nMatterCount + nIncrement
            end
            SoundManager.playSfx(self.sCounterTickSound)
            return Gui.GREEN
        elseif g_GameRules:getMatter() < self.nMatterCount then
            if self.nMatterCount - g_GameRules:getMatter() < nIncrement then
                self.nMatterCount = g_GameRules:getMatter()
            else
                self.nMatterCount = self.nMatterCount - nIncrement
            end
            self.nMatterCount = self.nMatterCount - nIncrement
            SoundManager.playSfx(self.sCounterTickSound)
            return Gui.RED
        else
            return Gui.AMBER
        end
    end

    function Ob:onTick(dt)
        -- update matter count
        if g_GameRules and g_GameRules.bRunning then
            if not self.rMatterText then
                self.rMatterText = self:getTemplateElement('MatterText')
            end
            if not self.rMatterLabel then
                self.rMatterLabel = self:getTemplateElement('MatterLabel')
            end
            if self.rMatterText and self.rMatterLabel then
                -- increment # and color over time to clarify change
                local color = self:tickMatterCount()
                self.rMatterText:setString(tostring(self.nMatterCount))
                self.rMatterText:setColor(unpack(color))
                self.rMatterLabel:setColor(unpack(color))
            end
            if self.rCapacityText and self.rCapacityIcon and self.rCapacityLabel then
                local tChars, nNumChars = CharacterManager.getTeamCharacters(Character.TEAM_ID_PLAYER)
				local nCapacity = g_GameRules:getCapacity()
                self.rCapacityText:setString(nNumChars.."/"..nCapacity)
				-- text red if capacity insufficient
				local color = Gui.AMBER
				if nNumChars > nCapacity then
					color = Gui.RED
				end
                self.rCapacityText:setColor(unpack(color))
				self.rCapacityIcon:setColor(unpack(color))
				self.rCapacityLabel:setColor(unpack(color))
            end
            if not self.rStardateText then
                self.rStardateText = self:getTemplateElement('StardateText')
            end
            if self.rStardateText then
                self.rStardateText:setString(g_LM.line("HUDHUD004TEXT").." "..GameRules.sStarDate)
            end
            local nTimeScale = g_GameRules.getTimeScale()
            if nTimeScale ~= self.nTimeScale then
                self.nTimeScale = nTimeScale
                self.rTimePauseButton:setSelected(nTimeScale==0)
                self.rSpeed1Button:setSelected(nTimeScale==1)
                self.rSpeed2Button:setSelected(nTimeScale==2)
                self.rSpeed3Button:setSelected(nTimeScale==4)
            end
            self.rOxygenButton:setSelected(g_GameRules:isOxygenGridEnabled())
            self.rWallButton:setSelected(g_GameRules.isCutawayModeEnabled())
        end
        self:checkTileTipTime(dt)
    end

    function Ob:onTimeButtonPressed(rButton, eventType)
        if eventType == DFInput.TOUCH_UP then
            if not g_GameRules.bInCutscene then
				local bPaused = false
                if rButton == self.rTimePauseButton then
                    g_GameRules.timePause()
					bPaused = true
                elseif rButton == self.rSpeed1Button then
                    g_GameRules.setTimeScale(1)
                elseif rButton == self.rSpeed2Button then
                    g_GameRules.setTimeScale(2)
					if not g_GameRules.bTimeLocked then
						g_GameRules.completeTutorialCondition('SpeedUpTime')
					end
                elseif rButton == self.rSpeed3Button then
                    g_GameRules.setTimeScale(4)
					if not g_GameRules.bTimeLocked then
						g_GameRules.completeTutorialCondition('SpeedUpTime')
					end
                end
				if not bPaused then
					GameRules.completeTutorialCondition('SetTimeSpeed')
				end
                SoundManager.playSfx('select')
            end
        end
    end

    function Ob:showFlipZone(bShow)
        if nil == bShow then bShow = true end
        self.bShowFlipZone = bShow
        self.rFlipButton:setLoc(0,-g_GuiManager.getUIViewportSizeY()+152)
        self:setElementHidden(self.rFlipButton,not bShow)
    end

    function Ob:onFlipButtonPressed(rButton, eventType)
        if self.bShowFlipZone and eventType == DFInput.TOUCH_UP then
            GameScreen.bFlipProp = not GameScreen.bFlipProp
			GameRules.completeTutorialCondition('FlippedObject')
        end
    end

    function Ob:onOxygenButtonPressed(rButton, eventType)
        if eventType == DFInput.TOUCH_UP then
            g_GameRules.cycleVisualizer()
			GameRules.completeTutorialCondition('UsedVizModes')
        end
    end

    function Ob:onWallButtonPressed(rButton, eventType)
        if eventType == DFInput.TOUCH_UP then
            g_GameRules.cycleCutawayMode()
			GameRules.completeTutorialCondition('UsedVizModes')
        end
    end

    function Ob:onZoomButtonPressed(rButton, eventType)
        if eventType == DFInput.TOUCH_UP then
            if rButton == self.rZoomoutButton then
                g_GameRules.AddZoom(GameRules.ZOOM_WHEEL_STEP)
            elseif rButton == self.rZoominButton then
                g_GameRules.AddZoom(-GameRules.ZOOM_WHEEL_STEP)
            end
        end
    end

    function Ob:onAlertsExpanded(bExpanded)
        if bExpanded then
            -- do nothing if alerts won't overlap
            if self.rZoomoutButton and g_GuiManager.alertPane then
                local x, y = self.rZoomoutButton:getLoc()
                local alertY = g_GuiManager.alertPane:getMaxY()
                if alertY > y then -- since negative y
                    return
                end
            end
        end
        if not self.sLastAlertTemplatedApplied then
            self.sLastAlertTemplatedApplied = ''
        end
        local sTemplateToApply = ''
        if bExpanded then
            sTemplateToApply = 'alertsExpandedOverride'
        else
            sTemplateToApply = 'alertsCollapsedOverride'
        end
        if self.sLastAlertTemplatedApplied ~= sTemplateToApply then
            local rInfo = self:getExtraTemplateInfo(sTemplateToApply)
            if rInfo then
                self:applyTemplateInfos(rInfo)
                self.sLastAlertTemplatedApplied = sTemplateToApply
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
