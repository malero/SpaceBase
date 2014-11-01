local Class=require('Class')
local Room = require('Room')
local GameRules = require('GameRules')
local Renderer=require('Renderer')
local ObjectList=require('ObjectList')
local Character = require('CharacterConstants')
local EnvObject = require('EnvObjects.EnvObject')
local Profile = require('Profile')

local SpaceRoom = Class.create(Room)

-- "space room" concept used to represent exterior space, used for:
-- env objects and env object build ghosts w/o floors

function SpaceRoom:init(tSaveData)
	Room.init(self, -1, {}, tSaveData)
    g_SpaceRoom = self
    Room.rSpaceRoom = self
    self.tOrderedProps={}
    self.tExtraGenerators={}
    self.nTeam = Character.TEAM_ID_NONE
end

function SpaceRoom:_addPersistentActivityOptions()
    -- advertise nothing.
end

function SpaceRoom:setTiles(tTiles)
	self.tTiles = {}
	self.nTiles = 0
    self.bJobsDirty = true
end

function SpaceRoom:tickVisibility() end

function SpaceRoom:getVisibility()
    return g_World.VISIBILITY_FULL
end

function SpaceRoom:getOxygenScore()
    return 0
end

function SpaceRoom:getExtraGeneratorsForRoom(id)
    local tGen = {}
    for propTag,nID in pairs(self.tExtraGenerators) do
        if nID == id then
            local rObj = ObjectList.getObject(propTag)
            if rObj and rObj:getPowerOutput() > 0 then
                table.insert(tGen,rObj)
            else
                self.tExtraGenerators[propTag] = nil
            end
        end
    end
    return tGen
end

function SpaceRoom:_assignSpacePowerGenToZone(rProp)
    local affectedTiles = rProp:getFootprint(true)

    for _,addr in ipairs(affectedTiles) do    
        local tx,ty = g_World.pathGrid:cellAddrToCoord(addr)
        local rRoom = Room.getRoomAtTile(tx,ty,1,true)
        if rRoom then
            self.tExtraGenerators[ObjectList.getTag(rProp)] = rRoom.id
            return
        end
    end

    for _,addr in ipairs(affectedTiles) do    
        if g_World.tWallAddrToBlob[addr] then
            local tBlobRooms = g_World.tWallAddrToBlob[addr].tRooms
            if tBlobRooms then
                local id = next(tBlobRooms)
                local rRoom = id and Room.tRooms[id]
                if rRoom then
                    self.tExtraGenerators[ObjectList.getTag(rProp)] = rRoom.id
                    return
                end
            end
        end
    end
end

function SpaceRoom:tickRoomFast()
    if Room.sbPowerVisEnabled then
        if self.tPowerVisLines then
            for rProp,_ in pairs(self.tPowerVisLines) do
                if not self.tProps[rProp.rTargetEnt] then
                    local rLayer = Renderer.getRenderLayer(Room.POWER_DISPLAY_LAYER)
                    rLayer:removeProp(rProp)
                    self.tPowerVisLines[rProp] = nil
                end
            end
        end
    elseif self.tPowerVisLines then
        self:clearPowerVisLines()
    end
    
    if #self.tOrderedProps == 0 and next(self.tProps) then
        for rProp,_ in pairs(self.tProps) do
            table.insert(self.tOrderedProps, rProp)
        end
    end
    if #self.tOrderedProps > 0 then
        local rNextProp = self.tOrderedProps[#self.tOrderedProps]
        self.tOrderedProps[#self.tOrderedProps] = nil
        if not rNextProp.bDestroyed then
        
            if rNextProp.rPowerRoom then
                if not rNextProp.rPowerRoom.bDestroyed then
                    rNextProp.rPowerRoom.zoneObj:powerUnrequest(rNextProp)
                end
                assertdev(rNextProp.rPowerRoom == nil)
            end
            
            local nPowerDraw = rNextProp:getPowerDraw()
            local nPowerOutput = rNextProp:getPowerOutput()
            rNextProp.bHasPower = false
            if nPowerOutput > 0 then
                rNextProp.bHasPower = true
                self:_assignSpacePowerGenToZone(rNextProp)
            elseif nPowerDraw == 0 then
                rNextProp.bHasPower = true
            else
                -- Look in Room's wall list and in World's wall blob list to see if we can find
                -- a list of contiguous rooms.
                local tx,ty,tw = rNextProp:getWallTile()
                local addr = g_World.pathGrid:getCellAddr(tx,ty)
                local rRoom = Room.getRoomAtTile(tx,ty,tw,true)
                    
                local tContiguousRooms
                if rRoom then
                    tContiguousRooms = rRoom.tContiguousRooms
                else
                    if g_World.tWallAddrToBlob[addr] then
                        local tBlobRooms = g_World.tWallAddrToBlob[addr].tRooms
                        -- We can just use the first room we encounter for its own list of contiguous rooms,
                        -- since it will be contiguous with anything we're contiguous with by definition.
                        local id = next(tBlobRooms)
                        tContiguousRooms = id and Room.tRooms[id] and Room.tRooms[id].tContiguousRooms
                    end
                end
                if tContiguousRooms then
                    for id,_ in pairs(tContiguousRooms) do
                        local rPowerRoom = Room.tPowerZones[id]
                        if rPowerRoom then

                            assertdev(rNextProp.rPowerRoom == nil)

                            local nFilled = rPowerRoom.zoneObj:powerRequest(rNextProp, nPowerDraw, true)
                            if nFilled == nPowerDraw then
                                assertdev(rNextProp.rPowerRoom == rPowerRoom)
                                if Room.sbPowerVisEnabled then
                                    self:addPowerVisLine(true,rNextProp,rPowerRoom)
                                end
                                rNextProp.bHasPower = true
                                break
                            else
                                assertdev(nFilled == 0)
                            end
                            
                            assertdev(rNextProp.rPowerRoom == nil)                            
                        end
                    end
                end
            end
        end
    end
end

function SpaceRoom:tickRoomSlow()
    local dt
    if not self.lastTickTime then
        self.lastTickTime = GameRules.elapsedTime
        dt = 1
    else
        dt = GameRules.elapsedTime - self.lastTickTime
        self.lastTickTime = GameRules.elapsedTime
    end

    Profile.enterScope("Props_Space")
    for rProp,_ in pairs(self.tProps) do
        rProp:onTick(dt)
    end
    Profile.leaveScope("Props_Space")
end

function SpaceRoom:_destroy()
    Room._destroy(self)
    g_SpaceRoom = nil
    Room.rSpaceRoom = nil
end

function SpaceRoom:getSaveTable()
	local tPropPlacements = {}
    for addr,tData in pairs(self.tPropPlacements) do
        tPropPlacements[addr] = {}
        tPropPlacements[addr].sName=tData.sName
        tPropPlacements[addr].bFlipX=tData.bFlipX or tData.bFlipped
        tPropPlacements[addr].bFlipY=tData.bFlipY
        tPropPlacements[addr].tx=tData.tx
        tPropPlacements[addr].ty=tData.ty
    end
	return {
		tTiles = {},
		tPropPlacements = tPropPlacements,
		bSpaceRoom = true,
        tExtraGeneratorsForRoom = self.tExtraGeneratorsForRoom,
	}
end

return SpaceRoom
