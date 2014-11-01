local Class=require('Class')
local Door = require('EnvObjects.Door')

local HeavyDoor = Class.create(Door, MOAIProp.new)

HeavyDoor.doorSprites=
{
	[Door.doorStates.OPEN] = 'door_open',
	[Door.doorStates.CLOSED] = 'door_heavy_closed',
	[Door.doorStates.LOCKED] = 'door_heavy_locked',
	[Door.doorStates.BROKEN_CLOSED] = 'door_broken',
	[Door.doorStates.BROKEN_OPEN] = 'door_open',
}

function HeavyDoor:takeDamage(rSource, tDamage)
	tDamage.nDamage = tDamage.nDamage / 10
	Door.takeDamage(self, rSource, tDamage)
end

return HeavyDoor
