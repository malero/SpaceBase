local Class=require('Class')
local GameRules=require('GameRules')
local Character=require('CharacterConstants')
local EnvObject=require('EnvObjects.EnvObject')
local ObjectList=require('ObjectList')
local ActivityOptionList=require('Utility.ActivityOptionList')
g_ActivityOption=g_ActivityOption or require('Utility.ActivityOption')

local FoodReplicator = Class.create(EnvObject, MOAIProp.new)

function FoodReplicator:canBuyFood(rChar)
    if self:getTeam() ~= Character.TEAM_ID_PLAYER then
        return false, 'replicator not on player team'
    end
    if not self.bActive then
        return false, 'replicator deactivated'
    end
    if g_GameRules.getMatter() < self.nReplicatorPrice then
        return false, 'insufficient matter'
    end
    if self:shouldDestroy() then
        return false, 'replicator queued to be destroyed'
    end
    if not self:isFunctioning() then
        return false, 'replicator not functional'
    end    
    local r = self:getRoom()
    if not r then return false, 'no room' end
    if r:getZoneName() == 'BRIG' then
        if rChar and not rChar:inPrison() then return false, 'character not in prison' end
    end
    return true
end

function FoodReplicator:init(sName, wx, wy, bFlipX, bFlipY, bForce, tSaveData, nTeam)
    self.nReplicatorPrice = EnvObject.getObjectData('FoodReplicator').nFoodPrice
    local tData=
    {
        rTargetObject=self,
        utilityGateSelf=self,
        utilityGateFn=self.canBuyFood,
		bInfinite=true,
    }
    self.rGetFoodOption = g_ActivityOption.new('EatAtFoodReplicator',tData)

    EnvObject.init(self,sName, wx,wy, bFlipX, bFlipY, bForce, tSaveData, nTeam)
end

function FoodReplicator:getAvailableActivities()
    local tActivities = EnvObject.getAvailableActivities(self)
    if self.rGetFoodOption then
        if self.rRoom and not self.rRoom:isDangerous() then
            table.insert(tActivities, self.rGetFoodOption)
        end
    end
    return tActivities
end

return FoodReplicator

