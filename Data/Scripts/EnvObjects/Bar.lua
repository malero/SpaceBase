local Class=require('Class')
local DFUtil = require("DFCommon.Util")
local EnvObject=require('EnvObjects.EnvObject')
local Character=require('CharacterConstants')

local Bar = Class.create(EnvObject, MOAIProp.new)

function Bar:init(sName, wx, wy, bFlipX, bFlipY, bForce, tSaveData, nTeam)
    EnvObject.init(self,sName, wx, wy, bFlipX, bFlipY, bForce, tSaveData, nTeam)
    
    self.tSlots={}
    local tData
    local tTiles = self:getFootprint()
    local facing = self:getFacing()
    local frontDir = facing
    local backDir = g_World.oppositeDirections[frontDir]
    for i,addr in ipairs(tTiles) do
        self.tSlots[i] = {}
        local tx,ty = g_World.pathGrid:cellAddrToCoord(addr)
        local pathX,pathY = g_World._getWorldFromTile( g_World._getAdjacentTile(tx,ty,frontDir) )
        tData=
        {
            pathX=pathX, pathY=pathY,
            barTX=tx, barTY=ty,
            utilityGateFn=function(rChar) return self:_drinkGate(rChar) end,
            rBar=self,
            nBarSlot=i,
        }
        self.tSlots[i].rGetDrinkOption = g_ActivityOption.new('GetDrink',tData)

        pathX,pathY = g_World._getWorldFromTile( g_World._getAdjacentTile(tx,ty,backDir) )
        tData=
        {
            pathX=pathX, pathY=pathY,
            barTX=tx, barTY=ty,
            utilityGateFn=function() return self:_serveGate(i) end,
            bOpening=true,
            rBar=self,
            nBarSlot=i,
        }
        self.tSlots[i].rServeDrinkOption = g_ActivityOption.new('ServeDrink',tData)
    end
end

function Bar:waitingForDrink(rTask,nSlot,bWaiting)
    if bWaiting then
        self.tSlots[nSlot].rWaitingTask = rTask
    else
        if self.tSlots[nSlot].rWaitingTask == rTask then
            self.tSlots[nSlot].rWaitingTask = nil
        end
    end
end

function Bar:getWaiter(nSlot)
    return self.tSlots[nSlot].rWaitingTask
end

function Bar:drinkServed(nSlot)
    if self.tSlots[nSlot].rWaitingTask then
        self.tSlots[nSlot].rWaitingTask:drinkServed()
        self.tSlots[nSlot].rWaitingTask = nil
    end
end

function Bar:_drinkGate(rChar)
    if not self:isActive(rChar) then
        return false, 'no bartender or wrong zone'
    end
    if rChar:getJob() == Character.BARTENDER and rChar:isPerformingWorkShiftTask() then
        return false
    end
    return true
end

function Bar:isActive(rNotThisDude)
    if self.bDestroyed or self.nCondition < 1 then
        return false
    end

    local r = self:getRoom()
    local z = r and r.zoneObj
    if r and z and r:getTeam() == Character.TEAM_ID_PLAYER and z.hasBarTender and z:hasBarTender(rNotThisDude) then
        return true
    end
end

function Bar:_serveGate(i)
    if self.tSlots[i].rWaitingTask then
        return true
    end
    return false, 'nobody waiting for drink'
end

function Bar:getAvailableActivities()    
    local tActivities = EnvObject.getAvailableActivities(self)
    
    if not self.tSlots then return tActivities end
    
    for i,t in ipairs(self.tSlots) do
        table.insert(tActivities, t.rGetDrinkOption)
        table.insert(tActivities, t.rServeDrinkOption)
    end
    return tActivities
end

return Bar

