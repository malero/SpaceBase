local Task=require('Utility.Task')
local World=require('World')
local Class=require('Class')
local Character=require('Character')

local RunTo = Class.create(Task)

-- Actually covers any activity that moves you to a point, whether, walking, running, or panicking.
function RunTo:init(rChar,tPromisedNeeds,rActivityOption)
    self.super.init(self,rChar,tPromisedNeeds,rActivityOption)
    self.duration = 5
    self.bPanic = rActivityOption.tData.bPanic
    self.bRun = rActivityOption.tData.bRun
	-- panic if this is that kind of party
	-- (do this before setPath, which refers to self.sWalkOverride)
	if self.bPanic then
        if self.rChar:getAnimData('panic_walk') then 
            self.sWalkOverride = 'panic_walk'
        end
        if self.rChar:getAnimData('panic_breathe') then
			self.sBreatheOverride = 'panic_breathe'
        end
	end
    if not self.sWalkOverride and self.bRun then
        self.sWalkOverride = 'run'
    end

    assertdev(rActivityOption.tBlackboard.tPath)
    if rActivityOption.tBlackboard.tPath then
        self:setPath(rActivityOption.tBlackboard.tPath)
    end
	-- startle anim on panic or (lower chance) alarm
	if (self.bPanic and math.random() < require('CharacterConstants').STARTLE_CHANCE) or (self.activityName == 'FleeEmergencyAlarm' and math.random() < require('CharacterConstants').STARTLE_CHANCE / 2) then
        if not self.rChar:retrieveMemory(Character.MEMORY_STARTLED_RECENTLY) then
            self.rChar:playAnim('startle', true)
            self.rChar:storeMemory(Character.MEMORY_STARTLED_RECENTLY, true, Character.MEMORY_STARTLED_RECENTLY_DURATION) 
        end
	end
end

function RunTo:onUpdate(dt)
	if self.rChar:isPlayingAnim('startle') then
		return
    elseif self:tickWalk(dt) then
        return true
    end
end

return RunTo
