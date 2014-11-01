local Task=require('Utility.Task')
local Class=require('Class')
local World=require('World')
local Log=require('Log')
local CharacterConstants=require('CharacterConstants')
local DFMath = require("DFCommon.Math")
local Malady = require('Malady')
local Fire = require('Fire')
local GameRules = require('GameRules')
local EnvObject = require('EnvObjects.EnvObject')

local MaintainPlants = Class.create(Task)

MaintainPlants.MAINTAIN_MIN_DURATION = 8
MaintainPlants.MAINTAIN_MAX_DURATION = 10

function MaintainPlants:init(rChar,tPromisedNeeds,rActivityOption)
    self.super.init(self,rChar,tPromisedNeeds,rActivityOption)
    self.duration = MaintainPlants.MAINTAIN_DURATION
    self.rTarget = rActivityOption.tData.rTargetObject
    assert(rActivityOption.tBlackboard.rChar == rChar)
    assert(rActivityOption.tBlackboard.rTargetObject == self.rTarget)
    self:setPath(rActivityOption.tBlackboard.tPath)
end

function MaintainPlants:_tryToMaintain()
    if self.rChar:isElevated() then return false end

    local cx,cy = self.rChar:getLoc()
    local tx,ty = self.rTarget:getLoc()
    -- TODO: port to Task:attemptInteractWithObject
    if World.areWorldCoordsAdjacent(cx,cy,tx,ty,true,true) then
        self.bMaintaining = true
        self.rChar:playAnim('maintain')
        self.rChar:faceWorld(tx,ty)
        self.duration = self:getDuration(MaintainPlants.MAINTAIN_MIN_DURATION, MaintainPlants.MAINTAIN_MAX_DURATION, CharacterConstants.BOTANIST)
        self.startingHealth = self.rTarget:getPlantHealth()
        Malady.interactedWith(self.rChar,self.rTarget)
        return true
    end
end

function MaintainPlants:onUpdate(dt)
    if self.bMaintaining then
        self.duration = self.duration - dt
        if self.duration < 0 then
            self.rChar:alterMorale(CharacterConstants.MORALE_MAINTAIN_PLANT, 'MaintainedPlant')
            -- log event in character's history
            --self.rChar.tStats.tHistory.nTotalMaintainedPlants = 1 + (self.rChar.tStats.tHistory.nTotalMaintainedPlants or 0)
            -- health improved based on botanist competence
            local nHealthImprovement = self.rTarget:maintainPlant(self.startingHealth, self.rChar)
            --self.rChar.tStats.tHistory.nTotalPlantImprovement = nHealthImprovement + (self.rChar.tStats.tHistory.nTotalPlantImprovement or 0)
            self.rTarget.sLastMaintainer = self.rChar.tStats.sUniqueID
            self.rTarget.sLastMaintainTime = require('GameRules').sStarDate

            -- spaceface log            
            local tLogData = {
                sDutyTarget = self.rTarget.sPlantName,
            }
            Log.add(Log.tTypes.DUTY_BOTANIST_MAINTAIN, self.rChar, tLogData)
            
            return true
        end
    elseif self.tPath then
        self:tickWalk(dt)
    else
        if not self:_tryToMaintain() then
            -- We don't handle a moving target right now, because right now no objects move.
            self:interrupt("can't maintain: did the target move?")
        end
    end
end

return MaintainPlants
