local m = {}

local DFUtil = require("DFCommon.Util")
local DFMath = require('DFCommon.Math')
local UIElement = require('UI.UIElement')
local DFInput = require('DFCommon.Input')
local ObjectList = require('ObjectList')
local MiscUtil = require('MiscUtil')
local Gui = require('UI.Gui')

local sUILayoutFileName = 'UILayouts/NewBaseInspectorLayout'

local regionLineCode = "NEWBAS007TEXT"
local regionFormat = "%s %d-%d"

local ageIntroLineCode = "NEWBAS008TEXT"
local ageUnitsLineCode = "NEWBAS009TEXT"
local ageFormat = "%s %d %s"
local distanceIntroLineCode = "NEWBAS010TEXT"
local distanceUnitsLineCode = "NEWBAS011TEXT"
local distanceFormat = "%s %d %s"
local threatLineCode = "NEWBAS015TEXT"
local interferenceLineCode = "NEWBAS016TEXT"
local densityLineCode = "NEWBAS020TEXT"

local tRegionAdjectiveLineCodes = {
	'NEWBAS023TEXT', 'NEWBAS024TEXT', 'NEWBAS025TEXT', 'NEWBAS026TEXT', 'NEWBAS027TEXT', 'NEWBAS028TEXT', 'NEWBAS029TEXT', 'NEWBAS030TEXT', 'NEWBAS031TEXT', 'NEWBAS032TEXT', 'NEWBAS033TEXT', 'NEWBAS034TEXT', 'NEWBAS041TEXT',
}
local tRegionNounLineCodes = {
	'NEWBAS035TEXT', 'NEWBAS036TEXT', 'NEWBAS037TEXT', 'NEWBAS038TEXT', 'NEWBAS039TEXT', 'NEWBAS040TEXT',
}

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())

    function Ob:init()
        Ob.Parent.init(self)

        self:processUIInfo(sUILayoutFileName)
        
        self.tRevealedElements = {}
        for k,v in pairs(self.tTemplateElements) do
            if k ~= "ZoomedMap" then self.tRevealedElements[k] = v end
        end
        
        self.rZoomedMap = self:getTemplateElement('ZoomedMap')
        self.rLabelName = self:getTemplateElement('LabelName')
        self.rLabelAge = self:getTemplateElement('LabelAge')
        self.rTextDensity = self:getTemplateElement('TextDensity')
        self.rTextDistance = self:getTemplateElement('TextDistance')
        self.rTextThreat = self:getTemplateElement('TextThreat')
        self.rTextInterference = self:getTemplateElement('TextInterference')
        self.sRegionName = ''
        
        self.nElapsedTime = 0
        
        self.nZoomedMapTargetX,self.nZoomedMapTargetY = self.rZoomedMap:getLoc()
        self.nZoomedMapStartX,self.nZoomedMapStartY = -600, -722
    end
    
    function Ob:setLandingZone(tLandingZone,x,y)
        self.nZoomedMapStartX,self.nZoomedMapStartY = x-300,y
        local x,y = tLandingZone.x,tLandingZone.y
        local galaxyValues = MiscUtil.getGalaxyMapValues(x, y)
        self.sRegionName = self:getRegionName(x,y)
        self.rLabelName:setString(self.sRegionName)
        self.rLabelAge:setString(string.format(ageFormat, g_LM.line(ageIntroLineCode),  DFMath.roundDecimal(math.abs(math.sin(math.rad(x*15))) * 10 + 5), g_LM.line(ageUnitsLineCode)))
        
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

    function Ob:onFinger(touch, x, y, props)
        if self.rCustomInspector then
            self.rCustomInspector:onFinger(touch, x, y, props)
        end
    end

    function Ob:inside(wx, wy)
    end

    function Ob:hide()
        Ob.Parent.hide(self)
        self.bActive = true
    end

    function Ob:show(nPri)
        Ob.Parent.show(self, nPri)
        
        self.nElapsedTime = 0
        self.bDoneIntro = false
        self.bActive = true
        
        for k,v in pairs(self.tRevealedElements) do 
            self:setElementHidden(v,true)
        end
    end
    
    function Ob:onTick(dt)
        Ob.Parent.onTick(self, dt)
        if not self.bActive then return end
        if not self.bDoneIntro then
            local stepSize = 0.25
            local totalTime = 1.0
            self.nElapsedTime = self.nElapsedTime + dt
            if self.nElapsedTime > totalTime then
                self:setMap(1)
                self.bDoneIntro = true
                self.newBase:playWarbleEffect(true)
                for k,v in pairs(self.tRevealedElements) do 
                    self:setElementHidden(v,false)
                end
            else
                local currentStep = math.floor(self.nElapsedTime / stepSize)
                local totalSteps = math.max(math.floor(totalTime / stepSize), 1)
                self:setMap(currentStep / totalSteps)
            end
        end
    end
	
    function Ob:getRegionName(x,y)
		local adj = g_LM.line(DFUtil.arrayRandom(tRegionAdjectiveLineCodes))
		local noun = g_LM.line(DFUtil.arrayRandom(tRegionNounLineCodes))
        return string.format(regionFormat, adj..' '..noun,  x, y)
    end
    
    function Ob:setMap(t)
        self.rZoomedMap:setLoc(DFMath.lerp(self.nZoomedMapStartX, self.nZoomedMapTargetX, t), DFMath.lerp(self.nZoomedMapStartY, self.nZoomedMapTargetY, t))
        self.rZoomedMap:setRot(0, 0, DFMath.lerp(15, 0, t))
    end

    return Ob
end

function m.new(...)
    local Ob = m.create()
    Ob:init(...)

    return Ob
end

return m