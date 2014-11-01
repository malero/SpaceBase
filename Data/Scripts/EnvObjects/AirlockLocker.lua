local Class=require('Class')
local GameRules=require('GameRules')
local Character=require('CharacterConstants')
local EnvObject=require('EnvObjects.EnvObject')
local ObjectList=require('ObjectList')
local Room=require('Room')
local ActivityOptionList=require('Utility.ActivityOptionList')
g_ActivityOption=g_ActivityOption or require('Utility.ActivityOption')

local AirlockLocker = Class.create(EnvObject, MOAIProp.new)

function AirlockLocker:init(sName, wx, wy, bFlipX, bFlipY, bForce, tSaveData, nTeam)
    EnvObject.init(self,sName, wx,wy, bFlipX, bFlipY, bForce, tSaveData, nTeam)
    local tData=
    {
        rTargetObject=self,
        utilityGateFn=function(rChar,rAO)
            if not self.rRoom or self.rRoom.zoneObj.sZoneName ~= 'AIRLOCK' then
                return false, 'non-functional locker'
            end
            return true
        end,
        pathStartOverrideFn=function(rChar,rAO)
            return self:getLoc()
        end,
		bInfinite=true,
    }

    self.rAirlockOption = g_ActivityOption.new('PutOnSuit',tData)
end

-- find a good spot to stand to get your suit.
-- Usually returns the spot right in front of it, but if that's no good,
-- it'll try some other adjacent ones.
function AirlockLocker:getAccessWorldLoc()
    if self.rRoom then
        local tx,ty = self:getTileInFrontOf()
        local bSuccess = false
        if Room.getRoomAtTile(tx,ty,1) == self.rRoom then
            bSuccess = true
        else
            local selfTX,selfTY = self:getTileLoc()
            for i=2,5 do
                tx,ty = g_World._getAdjacentTile(selfTX,selfTY,i)
                if Room.getRoomAtTile(tx,ty,1) == self.rRoom then
                    bSuccess = true
                    break
                end
            end
        end
        if bSuccess then
            local wx,wy = g_World._getWorldFromTile(tx,ty)
            return wx,wy
        end
    end
    return nil
end

function AirlockLocker:getAvailableActivities()
    local tActivities = EnvObject.getAvailableActivities(self)
    if self.rAirlockOption then
        table.insert(tActivities, self.rAirlockOption)
    end
    return tActivities
end

return AirlockLocker

