local Task=require('Utility.Task')
local Class=require('Class')
local World=require('World')
local Log=require('Log')
local GameRules=require('GameRules')
local Character=require('CharacterConstants')
local GameRules = require('GameRules')
local EnvObject = require('EnvObjects.EnvObject')
local DFMath = require('DFCommon.Math')
local InventoryData=require('InventoryData')

local DropOffRocks = Class.create(Task)

DropOffRocks.DROP_MIN_DURATION = 8
DropOffRocks.DROP_MAX_DURATION = 12
DropOffRocks.HELMET_REQUIRED = true

function DropOffRocks:init(rChar,tPromisedNeeds,rActivityOption)
    self.super.init(self,rChar,tPromisedNeeds,rActivityOption)
    self.nDuration = self:getDuration(DropOffRocks.DROP_MIN_DURATION, DropOffRocks.DROP_MAX_DURATION, Character.MINER)
    self.rTarget = rActivityOption.tData.rTargetObject
    self:setPath(rActivityOption.tBlackboard.tPath)

    assertdev(self.rTarget)
    if not self.rTarget then
        self:interrupt()
    end
end

function DropOffRocks:onUpdate(dt)
    if self:interacting() then
        if self:tickInteraction(dt) then
            local tItemData = self.rChar:destroyItem(self.rChar:heldItemName())
            if not tItemData then
                self:interrupt('character lost held item')
                return
            end
            assertdev(tItemData.sTemplate == InventoryData.MINE_PICKUP_NAME)
            if self:getJobSuccess(Character.MINER) then
                self.rChar:alterMorale(Character.MORALE_MINE_ASTEROID, 'Mined')
                --log mine
                local tLogData={}
                Log.add(Log.tTypes.DUTY_MINE, self.rChar, tLogData)
                self.rChar:addRoomAffinity(Character.AFFINITY_CHANGE_MINOR)
            else
                self.rTarget:damageCondition(EnvObject.MAINTAIN_FAILURE_DAMAGE, true)
                self.rChar:angerEvent(Character.ANGER_JOB_FAIL_MAJOR)
            end
			-- get matter even if you fail
			local nMatterYield
            if self.rTarget.sName == 'RefineryDropoff' then
                nMatterYield = DFMath.lerp(GameRules.MAT_MINE_ROCK_MIN, GameRules.MAT_MINE_ROCK_MAX, self.rChar:getJobCompetency(Character.MINER))
            else
                nMatterYield = DFMath.lerp(GameRules.MAT_MINE_ROCK_MIN_LVL2, GameRules.MAT_MINE_ROCK_MAX_LVL2, self.rChar:getJobCompetency(Character.MINER))
            end
            
            if self.rChar:getInventoryItemOfTemplate('SuperBuilder') then
                nMatterYield = nMatterYield * 2
            end

			GameRules.addMatter(tItemData.nCount * nMatterYield)

            return true
        end
    elseif self.tPath then
        self:tickWalk(dt)
    else
        if self:attemptInteractWithObject('maintain',self.rTarget,self.nDuration) then
            -- wait until completion
        else
            self:interrupt('Unable to reach dropoff point.')
        end
    end
end

return DropOffRocks
