local Class=require('Class')
local Oxygen=require('Oxygen')
local DFGraphics = require('DFCommon.Graphics')
local EnvObject=require('EnvObjects.EnvObject')
local ObjectList=require('ObjectList')
local Door=require('EnvObjects.Door')
local Room=require('Room')
local Pathfinder=require('Pathfinder')

local Airlock = Class.create(Door, MOAIProp.new)

Airlock.monitorStates = 
{
    LOCKED=1,
    OXYNONE=2,
    OXYLOW=3,
    OXYMED=4,
    OXYFULL=5,
}

Airlock.doorSprites=
{
        [Door.doorStates.OPEN] = 'airlock_door_open',
        [Door.doorStates.CLOSED] = 'airlock_door_closed',
        [Door.doorStates.LOCKED] = 'airlock_door_closed',
        [Door.doorStates.BROKEN_CLOSED] = 'AirlockDoor_broken',
        [Door.doorStates.BROKEN_OPEN] = 'airlock_door_open',
}

Airlock.monitorSprites=
{
    [Airlock.monitorStates.OXYNONE] = 'airlock_door_meter1',
    [Airlock.monitorStates.OXYLOW] = 'airlock_door_meter2',
    [Airlock.monitorStates.OXYMED] = 'airlock_door_meter3',
    [Airlock.monitorStates.OXYFULL] = 'airlock_door_meter4',
    [Airlock.monitorStates.LOCKED] =  'airlock_door_lockicon',
}

function Airlock:init(sName, wx, wy, bFlipX, bFlipY, bForce, tSaveData, nTeam)
    Door.init(self,sName, wx,wy, bFlipX, bFlipY, bForce, tSaveData, nTeam)
    self.sPortrait = 'Env_Airlock_Door'
    if self.bDestroyed then return end
    
    self.bCanBlockOxygen = true

    self:testAirlock()
    self.MonitorSprite = MOAIProp.new()
    self.monitorState = Airlock.monitorStates.OXYNONE
       
    for k,v in pairs(Airlock.monitorSprites) do
        DFGraphics.alignSprite(self.spriteSheet, v, "left", "bottom")
    end
    local monitorSpriteName = Airlock.monitorSprites[self.monitorState]
    
    self.MonitorSprite:setDeck(self.spriteSheet)
    self.MonitorSprite:setIndex( self.spriteSheet.names[ monitorSpriteName ])
    require('Renderer').getRenderLayer(self.layer):insertProp(self.MonitorSprite)

    self.MonitorSprite:setLoc( EnvObject.getSpriteLoc(sName, wx, wy,self.bFlipX) )
    if bFlipX then self.MonitorSprite:setScl(-1, 1) end
end

function Airlock:_updateDoorState(bForceToOperation, bForceUpdate)
    if bForceUpdate or not self:getScriptController() then
        Door._updateDoorState(self, bForceToOperation)
	end
           
    if self.MonitorSprite then
        if self.operation == Door.operations.LOCKED then 
 --           self.monitorState = Airlock.monitorStates.LOCKED 
        end
        
        if self.nCondition == 0 then
            self.monitorState = Airlock.monitorStates.OXYNONE
        end
        self.MonitorSprite:setVisible( self.doorState ~= Door.doorStates.OPEN and self.nVisibility == g_World.VISIBILITY_FULL ) --hide the monitor if the door is open since the 'screen' is hidden in the open graphic.
        self.MonitorSprite:setIndex( self.spriteSheet.names[ Airlock.monitorSprites[ self.monitorState ] ] )
    end
end

function Airlock:remove()
    self.bValidAirlock = false
    require('Renderer').getRenderLayer(self.layer):removeProp(self.MonitorSprite)
    --self:_updatePathTags()
    Door.remove(self)
end

function Airlock:_setDoorState(nState)
    Door._setDoorState(self,nState)
    self:_updatePathTags()
end

function Airlock:_getFunctionalAirlockZone()
    local tTest = {self.tWestSideTiles[1],self.tEastSideTiles[1]}
    for i=1,2 do
        local tx,ty = g_World.pathGrid:cellAddrToCoord(tTest[i])
        local rRoom = Room.getRoomAtTile(tx,ty,self.nLevel)
        if rRoom and rRoom:getZoneName() == 'AIRLOCK' and rRoom.zoneObj and rRoom.zoneObj.bFunctional then
            return rRoom.zoneObj
        end
    end
end

-- special-case hacky function for pathfinding.
function Airlock:functioningAsOuterAirlockDoor()
    if self.bValidAirlock then
        local rZone = self:_getFunctionalAirlockZone()
        if rZone then return rZone.bFunctional end
    end
    return false
end

function Airlock:setOwnedByZone(rZoneObj,bOwned)
    self:_setDoorState(self.doorState)
end

function Airlock:testAirlock()
    -- MTF: already done in tick, by door.
    --self:_updateSpaceStatus()

    self.bValidAirlock = not self:_isSabotaged() and self.bEastSideVacuum ~= self.bWestSideVacuum and self.nCondition > 0

    if self.bEastSideVacuum then
        self.airlockSpaceDir = self.eastDir
        self.airlockInsideDir = self.westDir
    else
        self.airlockSpaceDir = self.westDir
        self.airlockInsideDir = self.eastDir
    end
    self:_updatePathTags()
end

function Airlock:getValidTileOnSide(bInside)
    if self.bValidAirlock then
        local dir = (bInside and self.airlockInsideDir) or self.airlockSpaceDir
        local tx,ty = g_World._getTileFromWorld(self:getLoc())
        tx,ty = g_World._getAdjacentTile(tx,ty,dir)
        local wx,wy = g_World._getWorldFromTile(tx,ty)
        return wx,wy,tx,ty
    end
end

return Airlock
