local Task=require('Utility.Task')
local Class=require('Class')
local WorkOut=require('Utility.Tasks.WorkOut')

local WorkOutInGym = Class.create(WorkOut)

-- identical to WorkOut, but with dumbbells (only available in fitness zones)

WorkOutInGym.tAnims = {
	{sAnimName = 'pushups'},
	{sAnimName = 'jumping_jacks'},
	{sAnimName = 'situps'},
	{sAnimName = 'workout_dumbell'},
}

return WorkOutInGym
