local m = {}

local DFUtil = require("DFCommon.Util")
local DFInput = require("DFCommon.Input")
local DFMath = require('DFCommon.Math')
local UIElement = require('UI.UIElement')
local Renderer = require('Renderer')
local GameRules = require('GameRules')
local EventController = require('EventController')
local Gui = require('UI.Gui')
local NewBaseInspector = require('UI.NewBaseInspector')
local SoundManager = require('SoundManager')
local MiscUtil = require('MiscUtil')

local sUILayoutFileName = 'UILayouts/NewBaseLayout'
local sRenderLayer='UIOverlay'

local NewBaseStates = { 'Initial', 'SelectedLandingZone', 'ConfirmedLandingZone', 'Deploying', 'Deployed' }

local defaultHelpTextCode =     'NEWBAS001TEXT'
local selectedHelpTextCode =    'NEWBAS004TEXT'
local readyTextCode =           'NEWBAS005TEXT'
local deployTextCode =          'NEWBAS006TEXT'
local seedLineCode =            'NEWBAS017TEXT'
local arrivalLineCode =         'NEWBAS018TEXT'
local arrivalUnitsLineCode =    'NEWBAS019TEXT'

local LaunchPanelXDefault = -1324
local LaunchPanelXOffset = -300
local INFO_MAP_SIZE = 64

local END_ANIM_INITIAL_DELAY = 2
local END_ANIM_ZOOM_TIME = 2.5
local END_ANIM_YEARS_DELAY = 0.5
local END_ANIM_BEFORE_COUNTDOWN_DELAY = 2
local END_ANIM_COUNTDOWN_TIME = 2.5
local END_ANIM_FADE_OUT_TIME = 0.5

local MAX_YEARS = 358042
local ZOOM_X = 0.73
local ZOOM_Y = 0.73

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())
    
    Ob.color = { 0/255, 0/255, 0/255, 0/255 }

    function Ob:init()
        Ob.Parent.init(self)
        
        self:setRenderLayer(sRenderLayer)
        
        --self.color = {226/255,178/255,16/255}

        self:processUIInfo(sUILayoutFileName)
        
        self.rMap = self:getTemplateElement('Map')
        self.rCursorLineHorizontal = self:getTemplateElement('CursorLineHorizontal')
        self.rCursorLineVertical = self:getTemplateElement('CursorLineVertical')
        self.rCursor = self:getTemplateElement('Cursor')
        self.rCursorText = self:getTemplateElement('CursorText')
        self.rCursorTutorialText = self:getTemplateElement('CursorTutorialText')
        self.rButtonConfirm = self:getTemplateElement('ButtonConfirm')
        self.rButtonDecline = self:getTemplateElement('ButtonDecline')
        self.rButtonConfirmInactive = self:getTemplateElement('ButtonConfirmInactive')
        self.rButtonConfirmActive = self:getTemplateElement('ButtonConfirmActive')
        self.rButtonConfirmActiveGlow = self:getTemplateElement('ButtonConfirmActiveGlow')        
        self.rButtonDeclineActive = self:getTemplateElement('ButtonDeclineActive')
        self.rButtonDeclineActiveGlow = self:getTemplateElement('ButtonDeclineActiveGlow')        
        self.rButtonDeclineInactive = self:getTemplateElement('ButtonDeclineInactive')
        self.rButtonDeploy = self:getTemplateElement('ButtonDeploy')
        self.rButtonDeployOff = self:getTemplateElement('ButtonDeployOff')
        self.rButtonCancel = self:getTemplateElement('ButtonCancel')
        self.rButtonCancelActive = self:getTemplateElement('ButtonCancelActive')
        self.rButtonDeployInactive = self:getTemplateElement('ButtonDeployInactive')
        self.rButtonDeployActive = self:getTemplateElement('ButtonDeployActive')     
        self.rSelectRegionHelpText = self:getTemplateElement('SelectRegionHelpText')
        self.rSelectRegionHelpTextBG = self:getTemplateElement('SelectRegionHelpTextBG')
        self.rSelectRegionHelpIcon = self:getTemplateElement('SelectRegionHelpIcon')
		self.rTutorialMarker = self:getTemplateElement('TutorialMarker')
		self.rTutorialMarkerLabel = self:getTemplateElement('TutorialMarkerLabelText')

        self.rSelectRegionHelpIcon = self:getTemplateElement('SelectRegionHelpIcon')
		self.rFlavorTextA = self:getTemplateElement('FlavorTextALabel')
		self.rFlavorTextB = self:getTemplateElement('FlavorTextBLabel')
        self.rLabelSeedDeployed = self:getTemplateElement('LabelSeedDeployed')
        self.rLabelEstimatedTime = self:getTemplateElement('LabelEstimatedTime')
        self.rLabelYears = self:getTemplateElement('LabelYears')
        
        self.rTextDensity = self:getTemplateElement('TextDensity')
        self.rTextDistance = self:getTemplateElement('TextDistance')
        self.rTextThreat = self:getTemplateElement('TextThreat')
        self.rTextInterference = self:getTemplateElement('TextInterference')
        self.rLabelDensity = self:getTemplateElement('LabelDensity')
        self.rLabelDistance = self:getTemplateElement('LabelDistance')
        self.rLabelThreat = self:getTemplateElement('LabelThreat')
        self.rLabelInterference = self:getTemplateElement('LabelInterference')
        
        self.rOverlay = self:getTemplateElement('Overlay')
        
        self.uiBG = self:getTemplateElement('Background')
        self:_updateBackground()
        
        self:setMapLoc()
        
        self.rButtonConfirm:addPressedCallback(self.onButtonConfirm, self)      
        self.rButtonDecline:addPressedCallback(self.onButtonDecline, self)
        self.rButtonDeploy:addPressedCallback(self.onButtonDeploy, self)
        self.rButtonCancel:addPressedCallback(self.onButtonCancel, self)
        
        self.inspector = NewBaseInspector.new()
        self.inspector.newBase = self
        
        self.uiCamera = Renderer.getUICamera()
        self.defaultCameraSclX, self.defaultCameraSclY = self.uiCamera:getScl()
        self.defaultCameraX, self.defaultCameraY = self.uiCamera:getLoc()
        
        self.nLabelEstimatedTimeDefaultX, self.nLabelEstimatedTimeDefaultY = self.rLabelEstimatedTime:getLoc()
        self.nLabelSeedDeployedDefaultX, self.nLabelSeedDeployedDefaultY = self.rLabelSeedDeployed:getLoc()
        
        self.bDoneDeploying = false
        self.bStartedFadeOut = false
        self.bPlayedTextWarble1 = false
        self.bPlayedTextWarble2 = false
        
        self.tLandingZone = {}
    end
    
    function Ob:show(basePri)
        Ob.Parent.show(self, basePri)
        g_GuiManager.newBaseActive = true

        -- hide game UIs
        g_GuiManager.statusBar:hide()
		g_GuiManager.tutorialText:hide()
        g_GuiManager.hintPane:hide()
        g_GuiManager.alertPane:hide()

        self:setup()
        self.currentState = 'Initial'
        self:showCursor(false)
        
        self.bDoneDeploying = false
        self.bStartedFadeOut = false
        self.bPlayedTextWarble1 = false
        self.bPlayedTextWarble2 = false
        SoundManager.playSfx('cursorappear')
        -- rProp, startColor, endColor, anim time, delay
        self:colorProp(self.rOverlay, Gui.BLACK, Gui.BLACK_NO_ALPHA, 0.5, 0) -- opening fade
        self.rMap:setColor(unpack(Gui.BLACK))
        
        SoundManager.disablePlayback()
        SoundManager.playMenuMusic()
        
        local function fnCursorCallback()
            self:playWarbleEffect(true)
            self:showCursor(true) 
        end
        
        self:colorProp(self.rMap, Gui.BLACK, Gui.WHITE, 0.5, 0.5, fnCursorCallback) -- map fade
        self:refresh()
        self:onResize()
    end

    function Ob:refresh()
        self:_updateBackground()
    end

    function Ob:playWarbleEffect(bFullscreen)
        local uiX,uiY,uiW,uiH = Renderer.getUIViewportRect() 
        if bFullscreen then                       
            g_GuiManager.createEffectMaskBox(0, 0, uiW, -uiH, 0.6)
        else
            g_GuiManager.createEffectMaskBox(0, 0, uiW, -uiH, 0.25)
        end
    end    


    function Ob:onFinger(touch, x, y, props)
        Ob.Parent.onFinger(self, touch, x, y, props)
        if touch.eventType == DFInput.TOUCH_UP and self.currentState == 'Initial' then
            self:selectedLandingZone(x, y)
        end
    end

    function Ob:inside(wx, wy)
        if self.currentState == 'Initial' then
            self:setCursor(wx,wy)
        end
        
        return Ob.Parent.inside(self, wx, wy)
    end
    
    function Ob:cursorFromWorld()
    end
    
    function Ob:setCursor(wx,wy)
        local rRenderLayer = Renderer.getRenderLayer(sRenderLayer)
        local x,y = self:getLoc()
        local cx,cy = wx-x,wy-y
        self.rCursorLineHorizontal:setLoc(cx,cy)
        self.rCursorLineVertical:setLoc(cx, cy)
        self.rCursor:setLoc(cx-48, cy+48)
        self.rCursorText:setLoc(cx+10, cy-100)
        self.rCursorTutorialText:setLoc(cx-210, cy+100)
        
        local dataMapX,dataMapY = self:worldToMap(wx,wy)
        dataMapX,dataMapY = DFMath.roundDecimal(dataMapX), DFMath.roundDecimal(dataMapY)
        self.rCursorText:setString(dataMapX .. " - " .. dataMapY)
        if dataMapX == 12 and dataMapY == 34 then
            self.rCursorTutorialText:setString("QUICK-START MODE")
			GameRules.bTutorialMode = true
        else
            self.rCursorTutorialText:setString("")
			GameRules.bTutorialMode = false
        end
        self:updateLandingZone({x=dataMapX,y=dataMapY})
    end

    function Ob:onFileChange(path)
        Ob.Parent.onFileChange(self, path)
        self.inspector:onFileChange(path)
        if self.currentState == 'SelectedLandingZone' then
            self:selectedLandingZone(self.tLandingZone.x, self.tLandingZone.y)
        end
        self.rOverlay:setColor(unpack(Gui.BLACK_NO_ALPHA))
        self.rMap:setColor(unpack(Gui.WHITE))
    end
    
    function Ob:setup()
        self:cancelLandingZone()
        self:setCursor(1280,-722)
        self:setVisibilityDeployElements(true)
        self.rButtonConfirm:setEnabled(false)
        self.rButtonDecline:setEnabled(false)
        self.rButtonDeploy:setEnabled(false)
        self.rButtonCancel:setEnabled(false)
        self:setElementHidden(self.rButtonDeployInactive,true)
        self:setElementHidden(self.rButtonDeployActive,true)
        self:setElementHidden(self.rButtonConfirmActive,true)
        self:setElementHidden(self.rButtonConfirmActiveGlow,true)
        self:setElementHidden(self.rLabelSeedDeployed,true)
        self:setElementHidden(self.rLabelEstimatedTime,true)
        self:setElementHidden(self.rLabelYears,true)
        local _,deployY = self.rButtonDeployOff:getLoc()
        if self.rButtonDeployOff.tSavedElementInfo.pos then
            local x = self:_convertLayoutVal(self.rButtonDeployOff.tSavedElementInfo.pos[1])
            local y = self:_convertLayoutVal(self.rButtonDeployOff.tSavedElementInfo.pos[2])
            self.rButtonDeployOff:setLoc(x, y)
        end
    end
    
    function Ob:startNew()
        self.currentState = 'Deployed'
        
        if not self.tLandingZone.x or not self.tLandingZone.y then
            -- to allow rapid creation of bases, if you cheat to create one, let's generate you some seeds
            self.tLandingZone.x, self.tLandingZone.y = DFMath.clamp(DFMath.roundDecimal(math.random() * INFO_MAP_SIZE)+1, 1, INFO_MAP_SIZE),
                                                       DFMath.clamp(DFMath.roundDecimal(math.random() * INFO_MAP_SIZE)+1, 1, INFO_MAP_SIZE)
        end
        GameRules.reset(self.tLandingZone)
--        EventController.fromSaveData({})
        self.tLandingZone = {}
        
        self:resume()
    end
    
    function Ob:resume()
        self.uiCamera:setScl(self.defaultCameraSclX, self.defaultCameraSclY)
        self.uiCamera:setLoc(self.defaultCameraX, self.defaultCameraY)
        Gui.setActivePane(nil)
        g_GuiManager.newBaseActive = false
        local nPri = g_GuiManager.basePri
        nPri = g_GuiManager.statusBar:show(nPri)
        nPri = g_GuiManager.newSideBar:show(nPri)
		nPri = g_GuiManager.tutorialText:show(nPri)
        nPri = g_GuiManager.hintPane:show(nPri)
        nPri = g_GuiManager.alertPane:show(nPri)
        g_GuiManager.snapAlertPos()
		-- pause game
		GameRules.timePause()
        self.inspector:hide(true)
		-- 2nd argument: leave game paused (weird)
        g_GuiManager.removeFromPopupQueue(self, false)
        g_GuiManager.refresh()
    end
    
    function Ob:onButtonConfirm(rButton, eventType)
        SoundManager.playSfx('accept')
        SoundManager.playSfx('launchopen')
        self:confirmedLandingZone()
    end
    
    function Ob:onButtonDecline(rButton, eventType)
        SoundManager.playSfx('accept')
        SoundManager.playSfx('previewdissappear')
        self:cancelLandingZone()
    end
    
    function Ob:onButtonDeploy(rButton, eventType)
        self:deploy()
    end
    
    function Ob:onButtonCancel(rButton, eventType)
        SoundManager.playSfx('cancel')
        SoundManager.playSfx('launchclose')
        SoundManager.playSfx('previewdissappear')
        self:cancelLandingZone()
    end
    
    function Ob:selectedLandingZone(x, y)
        if self:isOnMap(x, y) then
            self.currentState = 'SelectedLandingZone'
            SoundManager.playSfx('previewappear')
            -- move x,y to be relative to the map, upper left of the map = 0,0
            local newX,newY = self:worldToMap(x,y)
            self.tLandingZone.x, self.tLandingZone.y = DFMath.roundDecimal(newX), DFMath.roundDecimal(newY)
            self.rButtonConfirm:setEnabled(true)
            self.rButtonDecline:setEnabled(true)
            self:setElementHidden(self.rButtonConfirmInactive,false)
            self:setElementHidden(self.rButtonDeclineInactive,false)
            self:showCursor(false)
            self.inspector:setLandingZone(self.tLandingZone, x, y)
            self.inspector:show(self.maxPri)
            self:setVisibilityInspectorElements(false)
            g_GuiManager.setCursorVisible(true)
            self.rSelectRegionHelpText:setString(g_LM.line(selectedHelpTextCode))
            local uiX,uiY,uiW,uiH = Renderer.getUIViewportRect() 
            g_GuiManager.createEffectMaskBox(uiX,uiY,uiW,-uiH,1.2,0.5)
        end
    end
    
    function Ob:updateLandingZone(tLandingZone)
        local x,y = tLandingZone.x,tLandingZone.y
        local galaxyValues = MiscUtil.getGalaxyMapValues(x, y)
        
        local densityText, densityColor = MiscUtil.getSeverityFromValue(galaxyValues.asteroids)
        if densityColor == 'low' then densityColor = Gui.RED
        elseif densityColor == 'high' then densityColor = Gui.GREEN
        else densityColor = Gui.AMBER end
        self.rTextDensity:setString(string.format("%s %s", "", densityText))
        self.rTextDensity:setColor(densityColor[1], densityColor[2], densityColor[3], 1)
        local distanceText, distanceColor = MiscUtil.getDistanceFromValue(galaxyValues.population)
        self.rTextDistance:setString(string.format("%s %s", "", distanceText))
        --self.rTextDistance:setColor(distanceColor[1], distanceColor[2], distanceColor[3], 1)
        local threatText, threatColor = MiscUtil.getSeverityFromValue(galaxyValues.hostility)
        if threatColor == 'low' then threatColor = Gui.GREEN
        elseif threatColor == 'high' then threatColor = Gui.RED
        else threatColor = Gui.AMBER end
        self.rTextThreat:setString(string.format("%s %s", "", threatText))
        self.rTextThreat:setColor(threatColor[1], threatColor[2], threatColor[3], 1)
        local interferenceText, interferenceColor = MiscUtil.getSeverityFromValue(galaxyValues.derelict)   
        self.rTextInterference:setString(string.format("%s %s", "", interferenceText))
        --self.rTextInterference:setColor(interferenceColor[1], interferenceColor[2], interferenceColor[3], 1)
    end
    
    function Ob:cancelLandingZone()
        self.currentState = 'Initial'
        self.tLandingZone = {}
        self.rButtonConfirm:setEnabled(false)
        self.rButtonDecline:setEnabled(false)
        self.rButtonDeploy:setEnabled(false)
        self.rButtonCancel:setEnabled(false)
        self:setElementHidden(self.rButtonConfirmInactive,true)
        self:setElementHidden(self.rButtonConfirmActive,true)
        self:setElementHidden(self.rButtonConfirmActiveGlow,true)
        self:setElementHidden(self.rButtonDeclineInactive,true)
        self:setElementHidden(self.rButtonDeclineActive,true)
        self:setElementHidden(self.rButtonDeclineActiveGlow,true)
        self:showCursor(true)
        self:setElementHidden(self.rButtonCancelActive,true)
        self.rSelectRegionHelpText:setString(g_LM.line(defaultHelpTextCode))
        self.inspector:hide()
        self:setVisibilityInspectorElements(true)
        g_GuiManager.setCursorVisible(false)
        if self.rButtonDeployOff.tSavedElementInfo.pos then
            local x = self:_convertLayoutVal(self.rButtonDeployOff.tSavedElementInfo.pos[1])
            local y = self:_convertLayoutVal(self.rButtonDeployOff.tSavedElementInfo.pos[2])
            self:moveProp(self.rButtonDeployOff, x, y, 0.25)
        end
    end
    
    function Ob:confirmedLandingZone()
        self.currentState = 'ConfirmedLandingZone'
        self.rButtonDecline:setEnabled(false)
        self:setElementHidden(self.rButtonDeclineInactive,true)
        self.rButtonConfirm:setEnabled(false)
        self.rButtonConfirm:setEnabled(false)
        self.rButtonDeploy:setEnabled(true)
        self.rButtonCancel:setEnabled(true)
        self:setElementHidden(self.rButtonDeployInactive,false)
        self:setElementHidden(self.rButtonCancelActive,false)
        --self.rButtonDeployOff:seekLoc(0, 0, 5.0 )
        --self.rButtonDeployOff:moveLoc ( -300, 0, 5.0 ) --, MOAIEaseType.LINEAR
        local _,deployY = self.rButtonDeployOff:getLoc()
        if self.rButtonDeployOff.tSavedElementInfo.pos then
            local x = self:_convertLayoutVal(self.rButtonDeployOff.tSavedElementInfo.pos[1])
            local y = self:_convertLayoutVal(self.rButtonDeployOff.tSavedElementInfo.pos[2])
            self:moveProp(self.rButtonDeployOff, x + LaunchPanelXOffset, y, 0.75)
        end
    end
    
    function Ob:deploy()
        self.currentState = 'Deploying'
        SoundManager.playSfx('launchbutton')
        SoundManager.stopMusic()
        self:setVisibilityDeployElements(false)
        self.nDeployTime = 0
        self.rLabelSeedDeployed:setString(g_LM.line(seedLineCode)..self.inspector.sRegionName)
        self.rButtonDeploy:setEnabled(false)
        self.rButtonCancel:setEnabled(false)
    end
    
    function Ob:isOnMap(x, y)
        x, y = x - 1280, y + 722 --offset the parent positions of the cursors
        local mapX, mapY = self.rMap:getLoc()
        local mapWidth, mapHeight = self.rMap:getDims()
        local mapScaleX, mapScaleY = self.rMap:getScl()
        
        return x >= mapX and x <= mapX + (mapWidth * mapScaleX) and y <= mapY and y >= mapY - (mapHeight * mapScaleY)
    end
    
    
    function Ob:worldToMap(x,y)
        -- x' = INFO_MAP_SIZE * (x-280)/2160
        x,y = DFMath.lerp(1, INFO_MAP_SIZE, DFMath.clamp((x-280)/2160, 0, 1)), DFMath.lerp(1, INFO_MAP_SIZE, DFMath.clamp(math.abs(y)/1444, 0, 1))
        return x,y
    end
    
    function Ob:mapToWorld(x,y)
        -- x' = 2160 * x /INFO_MAP_SIZE + 280
        x = (2160*x) / INFO_MAP_SIZE + 280
        y = (1444*y) / INFO_MAP_SIZE
        return x,y
    end
    
    function Ob:showCursor(bToShow)
        if bToShow and self.currentState and self.currentState ~= 'Initial' then            
            return
        end
        self:setElementHidden(self.rCursorLineHorizontal,not bToShow)
        self:setElementHidden(self.rCursorLineVertical,not bToShow)
        self:setElementHidden(self.rCursor,not bToShow)
        self:setElementHidden(self.rCursorText,not bToShow)
        self:setElementHidden(self.rCursorTutorialText,not bToShow)
    end

    function Ob:setMapLoc()
        local mapWidth, mapHeight = self.rMap:getDims()
        local mapScale = 2190 / mapWidth
        self.rMap:setLoc((mapWidth * -0.5) * mapScale + 75, (mapHeight * 0.5) * mapScale) -- center the map
        self.rMap:setScl(mapScale,mapScale)        
    end
    
    function Ob:onResize()
        Ob.Parent.onResize(self)        
        self.inspector:onResize()
        self:refresh()
        self:setMapLoc()
        
        local x,y = self:getLoc()
        local tutX,tutY = self:mapToWorld(12,34)
        self.rTutorialMarker:setLoc(tutX-x-45,-tutY-y+25)
        tutX,tutY = self:mapToWorld(12,34)
        self.rTutorialMarkerLabel:setLoc(tutX-x-15,-tutY-y-30)
        if self.currentState == 'ConfirmedLandingZone' then
            if self.rButtonDeployOff.tSavedElementInfo.pos then
                local x = self:_convertLayoutVal(self.rButtonDeployOff.tSavedElementInfo.pos[1])
                local y = self:_convertLayoutVal(self.rButtonDeployOff.tSavedElementInfo.pos[2])
                self.rButtonDeployOff:setLoc(x + LaunchPanelXOffset, y)
            end            
        end
    end
    
    function Ob:onTick(dt)
        Ob.Parent.onTick(self, dt)
        if self.inspector then self.inspector:onTick(dt) end     
        if self.currentState == 'Deploying' then
            if self.bDoneDeploying then
                self:startNew()
                -- show gameplay UI
                g_GuiManager.statusBar:show()
                g_GuiManager.hintPane:show()
                g_GuiManager.alertPane:show()
            else
                self.nDeployTime = self.nDeployTime + dt
                if self.nDeployTime > END_ANIM_INITIAL_DELAY then
                    local t = DFMath.clamp((self.nDeployTime-END_ANIM_INITIAL_DELAY) / END_ANIM_ZOOM_TIME, 0, 1)

                    self.rMap:setColor(1-t,1-t,1-t,1)
                    local r,g,b = unpack(Gui.AMBER)
                    r,g,b=r*(1-t),g*(1-t),b*(1-t)
                    self.rCursorLineHorizontal:setColor(r,g,b,1)
                    self.rCursorLineVertical:setColor(r,g,b,1)
                    self.rCursor:setColor(r,g,b,1)
                    self.rCursorText:setColor(r,g,b,1)
                    self.rCursorTutorialText:setColor(r,g,b,1)
                    self.rTutorialMarker:setColor(r,g,b,1)
                    self.rTutorialMarkerLabel:setColor(r,g,b,1)
                    
                    self.uiCamera:setScl(DFMath.lerp(self.defaultCameraSclX, ZOOM_X, t), DFMath.lerp(self.defaultCameraSclY, ZOOM_Y, t))
                    local offsetX = DFMath.lerp(self.defaultCameraX, self.defaultCameraX+400, t)
                    self.uiCamera:setLoc(offsetX, self.defaultCameraSclY)
                    --self.rLabelEstimatedTime:setLoc(self.nLabelEstimatedTimeDefaultX + offsetX, self.nLabelEstimatedTimeDefaultY)
                    --self.rLabelSeedDeployed:setLoc(self.nLabelSeedDeployedDefaultX + offsetX, self.nLabelSeedDeployedDefaultY)
                end
                if not self.bPlayedTextWarble1 then
                    self:setElementHidden(self.rLabelSeedDeployed,false)
                    self:playWarbleEffect(false)
                    self.bPlayedTextWarble1 = true
                end

                if self.nDeployTime > END_ANIM_INITIAL_DELAY + END_ANIM_ZOOM_TIME + END_ANIM_YEARS_DELAY then
                    if not self.bPlayedTextWarble2 then 
                        self:setElementHidden(self.rLabelEstimatedTime,false)
                        self:setElementHidden(self.rLabelYears,false)
                        self.rLabelEstimatedTime:setString(g_LM.line(arrivalLineCode))
                        self.rLabelYears:setString(MAX_YEARS .. g_LM.line('NEWBAS019TEXT'))
                        self:playWarbleEffect(false)
                        self.bPlayedTextWarble2 = true
                    end
                end
                if self.nDeployTime > END_ANIM_INITIAL_DELAY + END_ANIM_ZOOM_TIME + END_ANIM_YEARS_DELAY + END_ANIM_BEFORE_COUNTDOWN_DELAY then
                    local t = (self.nDeployTime-(END_ANIM_INITIAL_DELAY + END_ANIM_ZOOM_TIME + END_ANIM_YEARS_DELAY + END_ANIM_BEFORE_COUNTDOWN_DELAY)) / END_ANIM_COUNTDOWN_TIME
                    self.rLabelYears:setString(DFMath.roundDecimal(DFMath.lerp(MAX_YEARS, 0, t)) .. g_LM.line('NEWBAS019TEXT'))
                end
                if self.nDeployTime > END_ANIM_INITIAL_DELAY + END_ANIM_ZOOM_TIME + END_ANIM_YEARS_DELAY + END_ANIM_BEFORE_COUNTDOWN_DELAY + END_ANIM_COUNTDOWN_TIME then
                    self.rLabelYears:setString("0" .. g_LM.line('NEWBAS019TEXT'))
                end
                if self.nDeployTime > END_ANIM_INITIAL_DELAY + END_ANIM_ZOOM_TIME + END_ANIM_YEARS_DELAY + END_ANIM_BEFORE_COUNTDOWN_DELAY + END_ANIM_COUNTDOWN_TIME + 2 then
                    if not self.bStartedFadeOut then
                        self:colorProp(self.rOverlay, Gui.BLACK_NO_ALPHA, Gui.BLACK, END_ANIM_FADE_OUT_TIME)
                        self.bStartedFadeOut = true
                    end
                end                
                if self.nDeployTime > END_ANIM_INITIAL_DELAY + END_ANIM_ZOOM_TIME + END_ANIM_YEARS_DELAY + END_ANIM_BEFORE_COUNTDOWN_DELAY + END_ANIM_COUNTDOWN_TIME + END_ANIM_FADE_OUT_TIME + 4 then
                    self.bDoneDeploying = true
                end
            end
        end
    end
    
    function Ob:_updateBackground()
        local sclX, sclY = Renderer.getViewport().sizeX*2,Renderer.getViewport().sizeY*2
        local x,y = -Renderer.getViewport().sizeX*.5,Renderer.getViewport().sizeY*.5
        self.uiBG:setScl(sclX, sclY)
        self.uiBG:setLoc(x,y)
        self.rOverlay:setScl(sclX, sclY)
        self.rOverlay:setLoc(x,y)
    end
    
    function Ob:setVisibilityDeployElements(bVisibility)
        self:setElementHidden(self.rMap,not bVisibility)
        self:setElementHidden(self.rSelectRegionHelpText,not bVisibility)
        self:setElementHidden(self.rSelectRegionHelpTextBG,not bVisibility)
        self:setElementHidden(self.rSelectRegionHelpIcon,not bVisibility)
		self:setElementHidden(self.rFlavorTextA,not bVisibility)
		self:setElementHidden(self.rFlavorTextB,not bVisibility)
		self:setElementHidden(self.rTutorialMarker,not bVisibility)
		self:setElementHidden(self.rTutorialMarkerLabel,not bVisibility)
        if not bVisibility then
            g_GuiManager.setCursorVisible(true)
            self.inspector:hide()
            self:setElementHidden(self.rLabelSeedDeployed,not bVisibility)
            self:setElementHidden(self.rLabelEstimatedTime,not bVisibility)
            self:setElementHidden(self.rLabelYears,not bVisibility)
        end
    end
    
    function Ob:setVisibilityInspectorElements(bVisibility)
        self:setElementHidden(self.rTextDensity,not bVisibility)
        self:setElementHidden(self.rTextDistance,not bVisibility)
        self:setElementHidden(self.rTextInterference,not bVisibility)
        self:setElementHidden(self.rTextThreat,not bVisibility)
        self:setElementHidden(self.rLabelDensity,not bVisibility)
        self:setElementHidden(self.rLabelDistance,not bVisibility)
        self:setElementHidden(self.rLabelInterference,not bVisibility)
        self:setElementHidden(self.rLabelThreat,not bVisibility)
    end
    
    return Ob
end

function m.new(...)
    local Ob = m.create()
    Ob:init(...)

    return Ob
end

return m
