local Task=require('Utility.Task')
local Class=require('Class')
local Log=require('Log')
local Character=require('CharacterConstants')

local LiftAtWeightBench = Class.create(Task)

LiftAtWeightBench.nLiftDuration = 10
LiftAtWeightBench.sLiftAnim = 'workout_benchpress'

function LiftAtWeightBench:init(rChar, tPromisedNeeds, rActivityOption)
    Task.init(self, rChar, tPromisedNeeds, rActivityOption)
    self.rTarget = rActivityOption.tData.rTargetObject
    self.duration = self.nLiftDuration
    self.bInterruptOnPathFailure = true
	if rActivityOption.tBlackboard.tPath then
		self:setPath(rActivityOption.tBlackboard.tPath)
	end
    assert(rActivityOption.tBlackboard.rChar == rChar)
    assert(rActivityOption.tBlackboard.rTargetObject == self.rTarget)
end

function LiftAtWeightBench:onComplete(bSuccess)
	Task.onComplete(self, bSuccess)
	-- restore character to their pre-lift position
	--self.rChar:setLoc(self.rCharInitialX,self.rCharInitialY,self.rCharInitialZ)
	if not bSuccess then
		return
	end
	self.rChar:alterMorale(Character.MORALE_DID_HOBBY, self.activityName)
	local nWorkoutCooldown = math.random(Character.WORKOUT_COOLDOWN - 15, Character.WORKOUT_COOLDOWN + 15)
	self.rChar:storeMemory('bWorkedOutRecently', true, nWorkoutCooldown)
    -- likelihood to log = how much of a jock you are
    local nJockitude = self.rChar:getAffinity('Exercise') / Character.STARTING_AFFINITY
    if math.random() < math.max(0.2, nJockitude) then
        Log.add(Log.tTypes.LIFT_WEIGHTS, self.rChar, {})
    end
end

function LiftAtWeightBench:onUpdate(dt)
	if self:interacting() then
        if self:tickInteraction(dt) then
            return true
        end
	elseif self:tickWalk(dt) then
        if not self:attemptInteractOnObject(self.sLiftAnim, self.rTarget, self.nLiftDuration) then
            self:interrupt('Failed to reach weight bench.')
        end
	end
end

return LiftAtWeightBench
