local Task=require('Utility.Task')
local Class=require('Class')
local DFMath = require("DFCommon.Math")
local Log=require('Log')
local Base=require('Base')
local Character=require('CharacterConstants')
local ResearchData=require('ResearchData')
local Malady=require('Malady')

local ResearchInLab = Class.create(Task)

ResearchInLab.nSessionDuration = 20
ResearchInLab.nMinAmountPerResearch = 5
ResearchInLab.nMaxAmountPerResearch = 20
-- seconds
ResearchInLab.nLogFrequency = 300
-- science = expert labor!
ResearchInLab.MAX_CHANCE_TO_FAIL = 0.25
ResearchInLab.NO_FAIL_COMPETENCY_THRESHOLD = 0.75
ResearchInLab.FAIL_DAMAGE = 10
ResearchInLab.nFireCheckFrequency = 10

function ResearchInLab:init(rChar, tPromisedNeeds, rActivityOption)
    Task.init(self, rChar, tPromisedNeeds, rActivityOption)
    self.rTarget = rActivityOption.tData.rTargetObject
    self.duration = self.nSessionDuration
    self.nFireTimer = 0
	if rActivityOption.tBlackboard.tPath then
		self:setPath(rActivityOption.tBlackboard.tPath)
	end
    assert(rActivityOption.tBlackboard.rChar == rChar)
    assert(rActivityOption.tBlackboard.rTargetObject == self.rTarget)
end

function ResearchInLab:_doResearch()
    local bSuccess = self:attemptInteractWithObject('maintain', self.rTarget, self.nSessionDuration)
    return bSuccess
end

function ResearchInLab:getCurrentResearch()
    local rRoom = self.rChar:getRoom()
    local zoneObj = rRoom and rRoom:getZoneObj()
    return zoneObj and zoneObj.getResearchStatus and zoneObj:getResearchStatus()
end

function ResearchInLab:getCurrentResearchName()
    local sResearch = self:getCurrentResearch()
    if sResearch then
        if ResearchData[sResearch] then
            return g_LM.line(ResearchData[sResearch].sName)
        else
            return Malady.getFriendlyName(sResearch)
        end
    end
end

function ResearchInLab:_completeResearch()
    local sResearch = self:getCurrentResearch()
    if sResearch then
        local nAmount = DFMath.lerp(ResearchInLab.nMinAmountPerResearch, ResearchInLab.nMaxAmountPerResearch, self.rChar:getJobCompetency(Character.SCIENTIST))
        Base.addResearch(sResearch,nAmount)
        return true
    end
    return false
end

function ResearchInLab:onUpdate(dt)
	if self:interacting() then
		self.duration = self.duration - dt
        -- fire check for less competent scientists
        self.nFireTimer = self.nFireTimer + dt
        local sResearchName = self:getCurrentResearchName()
        local tLogData = { sResearchData = sResearchName }
        if self.nFireTimer > ResearchInLab.nFireCheckFrequency then
            self.nFireTimer = self.nFireTimer - ResearchInLab.nFireCheckFrequency
            if not self:getJobSuccess(Character.SCIENTIST) then
                self.rChar:angerEvent(Character.ANGER_JOB_FAIL_TINY)
                -- damage console, with possible chance of fire
				if self.rTarget:damageCondition(ResearchInLab.FAIL_DAMAGE) then
					Log.add(Log.tTypes.DUTY_SCIENTIST_RESEARCH_FIRE, self.rChar, tLogData)
				end
            end
        end
        -- log if we haven't in a while
        if sResearchName and not self.rChar:retrieveMemory(Character.MEMORY_LOGGED_RESEARCH_RECENTLY) and math.random() < 0.3 then
            Log.add(Log.tTypes.DUTY_SCIENTIST_DO_RESEARCH, self.rChar, tLogData)
            self.rChar:storeMemory(Character.MEMORY_LOGGED_RESEARCH_RECENTLY, true, ResearchInLab.nLogFrequency)
        end
        if self:tickInteraction(dt) then
            local bResearched = self:_completeResearch()
            if bResearched then
                return true
            else
                Print(TT_Warning, "Research failed, because it was already complete, or incorrect zone.")
                self:interrupt()
                return false
            end
        end
	elseif self:tickWalk(dt) and not self:interacting() then
		if not self:_doResearch() then
            self:interrupt("failed to interact with research object")
            return false
        end
	end
end

return ResearchInLab
