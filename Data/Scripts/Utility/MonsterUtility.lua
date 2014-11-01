local ActivityOption=require('Utility.ActivityOption')
local ActivityOptionList=require('Utility.ActivityOptionList')
local Room=require('Room')
local Character = require('CharacterConstants')
local GlobalObjects = require('Utility.GlobalObjects')

local MonsterUtility = {
}

function MonsterUtility.getGlobalFriendlyUtilityObjects(rChar)
    local tObjects = {}
    table.insert(tObjects, { tUtilityOptions = { ActivityOption.new('Breathe', {bInfinite=true}) } })

    return tObjects
end

function MonsterUtility.getGlobalMonsterUtilityObjects(rChar)
    local tObjects = {}
    --table.insert(tObjects, { tUtilityOptions = { ActivityOption.new('WanderAround', {bInfinite=true}) } })
    table.insert(tObjects, { tUtilityOptions = { ActivityOption.new('Breathe', {bInfinite=true}) } })
    table.insert(tObjects, { tUtilityOptions = { ActivityOption.new('MonsterPatrol', {bInfinite=true,bDestroyDoors=true,bAllowHostilePathing=true}) } })

    return tObjects
end

function MonsterUtility.getGlobalRaiderUtilityObjects(rChar)
    local tObjects = {}
    
    --table.insert(tObjects, { tUtilityOptions = { ActivityOption.new('WanderAround', {bInfinite=true}) } })
    table.insert(tObjects, { tUtilityOptions = { ActivityOption.new('Breathe', {bInfinite=true}) } })
    table.insert(tObjects, { tUtilityOptions = { ActivityOption.new('MonsterPatrol', {bInfinite=true,bDestroyDoors=true,bAllowHostilePathing=true}) } })
    table.insert(tObjects, { tUtilityOptions = { ActivityOption.new('MonsterPatrol', {bInfinite=true,bDestroyDoors=true,bAllowHostilePathing=true}) } })
    table.insert(tObjects, { tUtilityOptions = { ActivityOption.new('MonsterWander', {bInfinite=true,
        targetLocationFn=GlobalObjects.getNearbySafeLoc,
        bAllowHostilePathing=true}) } })
	
	-- break stuff if nobody is around
	local tData = {
		utilityGateFn=function(rChar, rAO)
            if rChar.tStatus.bCuffed or rChar:inPrison() then return false, 'imprisoned' end
			-- targetable objects in room?
			local rRoom = rChar:getRoom() or g_SpaceRoom
			if rRoom.nTeam ~= Character.TEAM_ID_PLAYER then
				return false, 'not in player-controlled room'
			elseif not rRoom or rRoom == Room.rSpaceRoom then
				return false, 'not indoors'
			end
			local rObject = rRoom:getRandomAttackableObject()
			if not rObject then
				return false, 'nothing to attack'
			end
			-- pass object as victim etc
			rAO.tData.rVictim = rObject
			rAO.tData.rTargetObject = rObject
			return true
        end,
		--bInfinite=true
	}
	table.insert(tObjects, { tUtilityOptions = { ActivityOption.new('MonsterAttackEquipment', tData) } } )
	
    return tObjects
end

return MonsterUtility
