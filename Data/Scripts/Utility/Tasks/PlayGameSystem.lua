local Task=require('Utility.Task')
local Class=require('Class')
local Log=require('Log')
local Character=require('CharacterConstants')
local AnimateAtPoint=require('Utility.Tasks.AnimateAtPoint')

local PlayGameSystem = Class.create(AnimateAtPoint)

PlayGameSystem.tAnims = {
	{sAnimName = 'gaming_idle'},
	{sAnimName = 'gaming_frustration', bPlayOnce = true},
}

function PlayGameSystem:onComplete(bSuccess)
	AnimateAtPoint.onComplete(self, bSuccess)
	if not bSuccess then
		return
	end
	self.rChar:alterMorale(Character.MORALE_DID_HOBBY, self.activityName)
	local nGamingCooldown = math.random(Character.GAMING_COOLDOWN - 15, Character.GAMING_COOLDOWN + 15)
	self.rChar:storeMemory('bPlayedGameRecently', true, nGamingCooldown)
	-- different logs for gaming while unassigned
	local tLogData = { nPlayTime = tostring(math.random(2,5))} --future things to log
	if self.rChar.tStats.nJob == Character.UNEMPLOYED then
		Log.add(Log.tTypes.PLAY_GAME_SYSTEM_UNEMPLOYED, self.rChar, tLogData)
	else
		Log.add(Log.tTypes.PLAY_GAME_SYSTEM, self.rChar, tLogData)
	end
end

return PlayGameSystem
