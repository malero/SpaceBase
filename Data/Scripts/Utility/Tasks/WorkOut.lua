local Task=require('Utility.Task')
local Class=require('Class')
local Log=require('Log')
local Character=require('CharacterConstants')
local AnimateAtPoint=require('Utility.Tasks.AnimateAtPoint')

local WorkOut = Class.create(AnimateAtPoint)

WorkOut.tAnims = {
	{sAnimName = 'pushups'},
	{sAnimName = 'jumping_jacks'},
	{sAnimName = 'situps'},
}

function WorkOut:onComplete(bSuccess)
	AnimateAtPoint.onComplete(self, bSuccess)
	if not bSuccess then
		return
	end
	self.rChar:alterMorale(Character.MORALE_DID_HOBBY, self.activityName)
	local nWorkoutCooldown = math.random(Character.WORKOUT_COOLDOWN - 15, Character.WORKOUT_COOLDOWN + 15)
	self.rChar:storeMemory('bWorkedOutRecently', true, nWorkoutCooldown)
    -- likelihood to log = how much of a jock you are
    local nJockitude = self.rChar:getAffinity('Exercise') / Character.STARTING_AFFINITY
    if math.random() < math.max(0.2, nJockitude) then
        Log.add(Log.tTypes.WORK_OUT, self.rChar)
    end
end

return WorkOut
