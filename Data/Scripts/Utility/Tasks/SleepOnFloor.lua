local Task=require('Utility.Task')
local Class=require('Class')
local Log=require('Log')
local CharacterConstants=require('CharacterConstants')

local SleepOnFloor = Class.create(Task)

--SleepOnFloor.emoticon = 'sleep'

function SleepOnFloor:init(rChar,tPromisedNeeds,rActivityOption)
    self.super.init(self,rChar,tPromisedNeeds,rActivityOption)
    self.duration = math.random(10,15)
    self.bInterruptOnPathFailure = true    
    if rActivityOption.tBlackboard.tPath then
        self:setPath(rActivityOption.tBlackboard.tPath)
    else
        self.rChar:playAnim("sleep")
    end
end

function SleepOnFloor:onUpdate(dt)
    if self.tPath then
        if self:tickWalk(dt) then
            self.rChar:playAnim("sleep")
        end
        return
    end

    self.duration = self.duration - dt
    if self.duration < 0 then
		-- starve activity also uses this, but morale penalty + log don't apply
		if self.rChar:getCurrentTaskName() ~= 'Starve' then
			self.rChar:alterMorale(CharacterConstants.MORALE_SLEPT_ON_FLOOR, 'SleptOnFloor')
			Log.add(Log.tTypes.SLEEP_FLOOR, self.rChar)
		end
        return true
    end
end

return SleepOnFloor
