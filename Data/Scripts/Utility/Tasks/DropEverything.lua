-- Doesn't actually drop everything.
-- Drops activityOption.tData.sObjectKey or currently held item.

local Task=require('Utility.Task')
local ObjectList=require('ObjectList')
local Room=require('Room')
local Class=require('Class')

local DropEverything = Class.create(Task)
--DropEverything.emoticon = 'work'
function DropEverything:init(rChar,tPromisedNeeds,rActivityOption)
    self.super.init(self,rChar,tPromisedNeeds,rActivityOption)
    self.duration = 1.5
    rChar:playAnim("breathe")
    
    self.sObjectKey = rActivityOption.tData.sObjectKey or self.rChar:heldItemName()

    if rActivityOption.tBlackboard.tPath then
        self:setPath(rActivityOption.tBlackboard.tPath)
    elseif not self:_findAdjacentEmptySpace() then
        local tx,ty = self:_findEmptyTile()
        if tx then
            local wx,wy = self.rChar:getLoc()
            local targetX,targetY = g_World._getWorldFromTile(tx,ty)
            self:createPath(wx,wy, targetX,targetY, true)
        end
    end
end

function DropEverything.tileEmptyTestFn(tx,ty)
        if g_World._isPathable(tx,ty) and not ObjectList.getTagAtTile(tx,ty,ObjectList.ENVOBJECT)
                and not ObjectList.getTagAtTile(tx,ty,ObjectList.RESERVATION) then
            return true
        end
        return false
end

function DropEverything:_findAdjacentEmptySpace()
    local wx,wy = self.rChar:getLoc()
    local tx, ty = g_World._getTileFromWorld(wx,wy)
    local targetTX,targetTY = g_World.isAdjacentToFn(tx,ty,DropEverything.tileEmptyTestFn,true,true)
    return targetTX,targetTY
end

function DropEverything:_findEmptyTile()
    local rRoom = Room.getRoomAt(self.rChar:getLoc())
    if rRoom then
        local tx, ty = self:_findEmptyTileInList(rRoom.tTiles)
        if tx then return tx, ty end
        local tRooms = rRoom:getAccessibleByDoor()
        for rAdjoiningRoom,_ in pairs(tRooms) do
            tx, ty = self:_findEmptyTileInList(rAdjoiningRoom.tTiles)
            if tx then return tx, ty end
        end
    end
end

function DropEverything:_findEmptyTileInList(tTiles)
    for addr,coord in pairs(tTiles) do
        local tx,ty = coord.x,coord.y
        if DropEverything.tileEmptyTestFn(tx,ty) then
            return tx,ty
        end
    end
end

function DropEverything:onUpdate(dt)
    if self.tPath then
        self:tickWalk(dt)
    else
        local tx,ty = self:_findAdjacentEmptySpace()
        if tx and ty then
            self.rChar:dropItemOnFloor(self.sObjectKey, nil, g_World._getWorldFromTile(tx,ty))
        else
            self.rChar:dropItemOnFloor(self.sObjectKey)
        end
        return true
    end
end

return DropEverything
