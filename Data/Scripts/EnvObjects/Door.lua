local Class=require('Class')
local DFGraphics = require('DFCommon.Graphics')
local EnvObject=require('EnvObjects.EnvObject')
local ObjectList=require('ObjectList')
local Room=require('Room')
local Character=require('CharacterConstants')
local Oxygen=require('Oxygen')
local BrigZone=require('Zones.BrigZone')
local DFUtil = require('DFCommon.Util')
local SoundManager = require('SoundManager')
local Profile = require('Profile')

local Door = Class.create(EnvObject, MOAIProp.new)

Door.spriteSheetPath='Environments/Tiles/Wall'

Door.STAY_OPEN_DURATION = 2

Door.doorStates={
    OPEN=1,
    CLOSED=2,
    LOCKED=3,
    BROKEN_OPEN=4,
    BROKEN_CLOSED=5,
}

Door.operations={
    FORCED_OPEN=1,
    NORMAL=2,
    LOCKED=3,
}

Door.doorSprites=
{
        [Door.doorStates.OPEN] = 'door_open',
        [Door.doorStates.CLOSED] = 'door_closed',
        [Door.doorStates.BROKEN_CLOSED] = 'door_broken',
        [Door.doorStates.BROKEN_OPEN] = 'door_open',
        [Door.doorStates.LOCKED] = 'door_locked',        
    --[[
    [g_World.wallDirections.NWSE] =
    {
        [Door.doorStates.OPEN] = 'door_open_flip',
        [Door.doorStates.CLOSED] = 'door_closed_flip',
        [Door.doorStates.LOCKED] = 'door_locked_flip',
        [Door.doorStates.BROKEN_CLOSED] = 'door_broken_flip',
        [Door.doorStates.BROKEN_OPEN] = 'door_open_flip',
    },
    [g_World.wallDirections.NESW] =
    {
        [Door.doorStates.OPEN] = 'door_open',
        [Door.doorStates.CLOSED] = 'door_closed',
        [Door.doorStates.BROKEN_CLOSED] = 'door_broken',
        [Door.doorStates.BROKEN_OPEN] = 'door_open',
        [Door.doorStates.LOCKED] = 'door_locked',        
    },
    ]]--
}

function Door.reset()
    Door.tDoorsByAddr = {}
end

function Door:init(sName, wx, wy, bFlipX, bFlipY, bForce, tSaveData, nTeam)
    self.dir = g_World.getWallDirection(wx,wy)
    if self.dir == g_World.wallDirections.NWSE then
        bFlipX = true
    end
    EnvObject.init(self,sName, wx, wy, bFlipX, bFlipY, bForce, tSaveData, nTeam)
    self.tWestSideTiles,self.tEastSideTiles = {},{}
    self.sprites = self.doorSprites
    
    if not self.sprites then
        Print(TT_Warning, "Failed to place door. Wrong wall direction.", wx,wy,self.dir)
        self:remove()
        return
    end
    
    for _,v in pairs(self.sprites) do
        DFGraphics.alignSprite(self.spriteSheet, v, "left", "bottom")
    end
    
    self.sPortrait = 'Env_Door'
    self.sPortraitPath = 'UI/Portraits'
    
    self.bCanBlockOxygen = true

    self.operation = (tSaveData and tSaveData.operation) or Door.operations.NORMAL
    self:_updateDoorState(true)
end

function Door:isDoor()
    return true
end

function Door:open()
	if self.operation == Door.operations.NORMAL then
		self:_updateDoorState()
	end
end

function Door:sabotagePowerLoss()
    EnvObject.sabotagePowerLoss(self)
    -- immediately update door state, in case the saboteur needs updated pathing info this frame.
	self:_updateDoorState()
end

function Door:refreshLockdown(bLockdownInitiated)
    local bShouldLockdown
    
    if self:_isSabotaged() then
        bShouldLockdown = true
    elseif bLockdownInitiated then
        -- this case is easy. Did the room just get locked down? Lock the door! Yay!
        bShouldLockdown = true
    else
        local rEastRoom,rWestRoom = self:getRooms()
        -- If a lockdown was just removed, unlock the door if there isn't another pending lockdown.
        if (rWestRoom and rWestRoom.bUserBlockOxygen) or (rEastRoom and rEastRoom.bUserBlockOxygen) then
            bShouldLockdown = true
        else
            bShouldLockdown = false
        end
    end

    if bShouldLockdown then
        self:setOperation(Door.operations.LOCKED)
    else
        self:setOperation(Door.operations.NORMAL)
    end
end

function Door:hasPower()
	local rEastRoom,rWestRoom = self:getRooms()
	return g_PowerHoliday or ((rEastRoom and rEastRoom:hasPower()) or (rWestRoom and rWestRoom:hasPower()))
end

function Door:touchesRoom(rRoom)
    local rE,rW = self:getRooms()
    return rRoom == rE or rRoom == rW
end

function Door:getRooms()
--[[
    local testTile = self:_getInteriorTiles()[1]
    local x,y = g_World.pathGrid:cellAddrToCoord(testTile)
    local westTileX,westTileY = g_World._getAdjacentTile(x,y,self.westDir)
    local eastTileX,eastTileY = g_World._getAdjacentTile(x,y,self.eastDir)
    local rWestRoom = Room.getRoomAtTile(westTileX,westTileY,self.nLevel)
    local rEastRoom = Room.getRoomAtTile(eastTileX,eastTileY,self.nLevel)

    return rEastRoom,rWestRoom
    ]]--
    --[[
    local tx,ty,tw = self:getTileLoc()
    local addr = g_World.pathGrid:getCellAddr(tx, ty)
    local t = Room.tWallsByAddr[addr]
    if t then
        local nE,nW = t.tDirs[self.eastDir], t.tDirs[self.westDir]
        return (nE and Room.tRooms[nE]), (nW and Room.tRooms[nW])
    end
    ]]--
    local nE,nW = self:getRoomIDs()
    return Room.tRooms[nE], Room.tRooms[nW]
end

function Door:getRoomIDs()
    local tx,ty,tw = self:getTileLoc()
    local addr = g_World.pathGrid:getCellAddr(tx, ty)
    local t = Room.tWallsByAddr[addr]
    if t then
        local nE,nW = t.tDirs[self.eastDir], t.tDirs[self.westDir]
        return nE or 1, nW or 1
    end
    -- this can happen if a door has no adjacent room, e.g. it's hanging out in space.
    return 1,1
end

function Door:getVisibility()
    local rE,rW = self:getRooms()
    if not rE and not rW then return g_World.VISIBILITY_FULL end
    if rE and rW then 
        return math.max(rE:getVisibility(),rW:getVisibility())
    end
    if rE then return rE:getVisibility() end
    return rW:getVisibility()
end

function Door:close()
	self:_updateDoorState()
end

function Door:isOpen()
    return self.doorState == Door.doorStates.BROKEN_OPEN or self.doorState == Door.doorStates.OPEN
end

function Door:locked(rChar)
    if rChar and self.bBrigDoor and self.operation == Door.operations.NORMAL then
        if self.doorState == Door.doorStates.BROKEN_OPEN then return false end
        if self.doorState == Door.doorStates.LOCKED or self.doorState == Door.doorStates.BROKEN_CLOSED then return true end
        if not self:hasPower() then return false end

        local rBrigRoom = BrigZone.getBrigRoomForChar(rChar)
        local rCharRoom = rChar:getRoom()
        if rBrigRoom then
            return rBrigRoom == rChar:getRoom()
        end
        -- The correct approach hre is to change locked state based on whether the character has official business in the room.
        -- But our pathing system caches on character, not task or anything like that, so for now we do this somewhat incorrect task.
        if rChar:getJob() == Character.EMERGENCY or rChar:getJob() == Character.DOCTOR or rChar:getJob() == Character.TECHNICIAN or rChar:getJob() == Character.BUILDER then
            return false
        end
        if rCharRoom and rCharRoom:getZoneName() == 'BRIG' then return false end
        -- prevent non-doctors, non-security from wandering into brigs.
        return true
    end
	return self.doorState == Door.doorStates.LOCKED or self.doorState == Door.doorStates.BROKEN_CLOSED
end

function Door:cycle()
    local operation
    if self.operation == Door.operations.NORMAL then
        operation = Door.operations.LOCKED
    elseif self.operation == Door.operations.LOCKED then
        operation = Door.operations.FORCED_OPEN
    else
        operation = Door.operations.NORMAL
    end
    self:setOperation(operation)
end

function Door:getSaveTable(xShift,yShift)
    local t = EnvObject.getSaveTable(self,xShift,yShift)
    t.operation = self.operation
    return t
end

function Door:setLoc(x,y)
    if self.bLocSet then
        Print(TT_Warning, "Don't move doors.")
        return
    end

    local tTiles

    EnvObject.setLoc(self,x,y)
    self.bLocSet = true

    tTiles = self:_getInteriorTiles()
    self.tInteriorTilesCache = tTiles
    for _,addr in ipairs(tTiles) do
        local tx,ty = g_World.pathGrid:cellAddrToCoord(addr)
        Door.tDoorsByAddr[addr] = self
        g_World._setTile(tx,ty, g_World.logicalTiles.DOOR)
        --g_World._cheatOxygen(tx,ty)
    end
    self:_updatePathTags()
    self:_updateOxygenBlocking()
end

function Door:_updatePathTags()
    local bBlock = self.doorState == Door.doorStates.LOCKED or self.doorState == Door.doorStates.BROKEN_CLOSED
    ObjectList.setBlocksPathing(self.tag,bBlock)
end

function Door:setScriptController(rController)
    self.rScriptController = rController
end

function Door:getScriptController()
    return self.rScriptController
end

function Door:setOperation(operation)
    if self.operation == operation then return end

    self.operation = operation

    self:_updateDoorState()
end

function Door:getOperation()
    return self.operation
end

function Door:_getInteriorTiles()
    if self.tInteriorTilesCache then return self.tInteriorTilesCache end
    local tx, ty = g_World._getTileFromWorld(self:getLoc())
    local tTiles = g_World._getPropFootprint(tx, ty, self.sName, false, self.bFlipX)
    return tTiles
end

-- MTF TODO PERFORMANCE:
-- This function is expensive, and called frequently.
-- It probably wouldn't be slow if cellAddrToCoord and getCellAddr didn't go to C.
function Door:_getAdjacentTiles(bIncludeInterior)
    local tx, ty = g_World._getTileFromWorld(self:getLoc())
    local tTiles = g_World._getPropFootprint(tx, ty, self.sName, false, self.bFlipX)
    local tAdjacent = {}
    for _,addr in ipairs(tTiles) do
		-- directions to consider
        local x,y = g_World.pathGrid:cellAddrToCoord(addr)
		local dirs = {g_World.directions.N, g_World.directions.S, g_World.directions.E, g_World.directions.W}
        if self.dir == g_World.wallDirections.NWSE then
			table.insert(dirs, g_World.directions.SW)
			table.insert(dirs, g_World.directions.NE)
        else
			table.insert(dirs, g_World.directions.SE)
			table.insert(dirs, g_World.directions.NW)
        end
		-- get tile addresses
		for _,dir in pairs(dirs) do
			local tx, ty = g_World._getAdjacentTile(x,y,dir)
			local addr = g_World.pathGrid:getCellAddr(tx, ty)
			tAdjacent[addr] = {x=tx, y=ty}
		end
    end
    if bIncludeInterior then
        for _,addr in ipairs(tTiles) do
			local tx,ty = g_World.pathGrid:cellAddrToCoord(addr)
			tAdjacent[addr] = {x=tx, y=ty}
        end
    end
    return tAdjacent
end

function Door:vaporize()
    if self.bDestroyed then return end

    EnvObject.remove(self)

    local tTiles = self:_getInteriorTiles()
    for _,addr in ipairs(tTiles) do
        local tx,ty = g_World.pathGrid:cellAddrToCoord(addr)
        g_World._setTile(tx,ty, g_World.logicalTiles.SPACE)
        Door.tDoorsByAddr[addr] = nil
    end
end

function Door:remove()
    if self.bDestroyed then return end

    EnvObject.remove(self)
    local tTiles = self:_getInteriorTiles()
    for _,addr in ipairs(tTiles) do
        local tx,ty = g_World.pathGrid:cellAddrToCoord(addr)
        g_World._setTile(tx,ty, g_World.logicalTiles.WALL)
        Door.tDoorsByAddr[addr] = nil
    end
end

function Door:_updateOxygenBlocking()
    if self.bCanBlockOxygen then
        local bBlock = self.doorState == Door.doorStates.CLOSED or self.doorState == Door.doorStates.LOCKED or self.doorState == Door.doorStates.BROKEN_CLOSED
        if self.tag.bBlocksOxygen ~= bBlock then
            ObjectList.setBlocksOxygen(self.tag,bBlock)
            if not bBlock then
                local tTiles = self:_getInteriorTiles()
                for _,addr in ipairs(tTiles) do
                    local tx,ty = g_World.pathGrid:cellAddrToCoord(addr)
                    g_World._cheatOxygen(tx,ty)
                end
            end
        end
    end
end

function Door:_testLowOxygen(tx,ty)
    local tileValue = g_World._getTileValue(tx,ty)
	if tileValue == g_World.logicalTiles.SPACE then return true end

    if Room.getWallAtTile(tx,ty) then return false end
    
    local rRoom = Room.getRoomAtTile(tx,ty,self.nLevel)
	--if not rRoom or rRoom:isBreached() or g_World.oxygenGrid:getOxygen(tx,ty) < Oxygen.VACUUM_THRESHOLD then
	if not rRoom then return true end
    local o2 = g_World.oxygenGrid:getOxygen(tx,ty)
    if o2 < Character.OXYGEN_SUFFOCATING then
		return true
	end
	return false
end

function Door:_updateSpaceStatus()
    local tDoorTiles = self:_getInteriorTiles()
    if self.dir == g_World.wallDirections.NWSE then
        self.westDir,self.eastDir = g_World.directions.SW,g_World.directions.NE
    else
        self.westDir,self.eastDir = g_World.directions.NW,g_World.directions.SE
    end
   
    self.tWestSideTiles,self.tEastSideTiles = {},{}
    for _,addr in ipairs(tDoorTiles) do
        local x,y = g_World.pathGrid:cellAddrToCoord(addr)
        table.insert(self.tWestSideTiles, g_World.pathGrid:getCellAddr(g_World._getAdjacentTile(x,y,self.westDir)))
        table.insert(self.tEastSideTiles, g_World.pathGrid:getCellAddr(g_World._getAdjacentTile(x,y,self.eastDir)))
    end

    self.bWestSideVacuum,self.bEastSideVacuum=false,false
    self.bTouchesSpace = false
    self.bTouchesVacuum = false
    --self.rEastRoom,self.rWestRoom = self:getRooms()
    --self.nEastRoom = self.rEastRoom and self.rEastRoom.id
    --self.nWestRoom = self.rWestRoom and self.rWestRoom.id
    local nE,nW = self:getRoomIDs()
    
    self.bBrigDoor=false
    if nE == 1 or nW == 1 then
        local tx,ty,tw = self:getTileLoc()
        if nE == 1 and g_World._getTileValue(g_World._getAdjacentTile(tx,ty,self.eastDir)) == g_World.logicalTiles.SPACE then
            self.bTouchesSpace=1
        end
        if not self.bTouchesSpace and nW == 1 and g_World._getTileValue(g_World._getAdjacentTile(tx,ty,self.westDir)) == g_World.logicalTiles.SPACE then
            self.bTouchesSpace=1
        end
    else
        local rTestRoom = nE and Room.tRooms[nE]
        if rTestRoom and rTestRoom:getZoneName() == 'BRIG' then
            self.bBrigDoor = true
        else
            rTestRoom = nW and Room.tRooms[nW]
            if rTestRoom and rTestRoom:getZoneName() == 'BRIG' then
                self.bBrigDoor = true
            end
        end
    end

    for side=1,2 do
        local tSide = (side == 1 and self.tWestSideTiles) or self.tEastSideTiles
		local bSpace=false
        for i,addr in ipairs(tSide) do
            local tx,ty = g_World.pathGrid:cellAddrToCoord(addr)
			if self:_testLowOxygen(tx,ty) then
				bSpace=true
				self.bTouchesVacuum=true
				break
			end
        end
        if side == 1 then
            self.bWestSideVacuum = bSpace
        else
            self.bEastSideVacuum = bSpace
        end
    end
end

function Door:getAvailableActivities()
    local tActivities = {}
    if self:shouldDestroy() then
        table.insert(tActivities, g_ActivityOption.new('DestroyEnvObject', { rTargetObject=self,
                utilityGateFn=function(rChar,rAO) return EnvObject.gateJobActivity(rAO.tData.rTargetObject.sName, rChar, true,rAO.tData.rTargetObject) end, 
        }))
    else
        table.insert(tActivities, g_ActivityOption.new('MaintainEnvObject', { rTargetObject=self, 
            utilityGateFn=function(rChar,rAO) 
                if self.nCondition > EnvObject.CONDITION_NEEDED_TO_MAINTAIN then return false,'object healthy' end
                local rEastRoom,rWestRoom = self:getRooms()
                if not rEastRoom and not rWestRoom then
                    -- floating in space; fine
                elseif (not rEastRoom or rEastRoom:playerOwned()) and (not rWestRoom or rWestRoom:playerOwned()) then
                    -- both sides owned, or one side owned and nothing on the other side. fine.
                else
                    return false, 'unowned door'
                end
                return EnvObject.gateJobActivity(rAO.tData.rTargetObject.sName, rChar, false,rAO.tData.rTargetObject) 
            end, 
            utilityOverrideFn=function(rChar,rAO,nOriginalUtility) return self:getMaintainUtility(rChar,nOriginalUtility) end
        } ))
    end
    return tActivities
end

function Door:onTick()
    EnvObject.onTick(self)
    -- ticking door state because of the 'safety lock' during vacuum.
    -- and also because of condition degrades.
    self:_updateDoorState()
end

function Door:takeDamage(rSource, tDamage)
    EnvObject.takeDamage(self,rSource,tDamage)
    if self.nCondition == 0 then
        self.bSmashedOpen = true
    end
end

function Door:isDead()
    return self.nCondition == 0 and self.doorState == Door.doorStates.BROKEN_OPEN
end

function Door:getStatusString()
    local sLinecode = nil
    if self.doorState == Door.doorStates.BROKEN_OPEN then
        sLinecode = "PROPSX053TEXT"
    elseif self.doorState == Door.doorStates.BROKEN_CLOSED then
        sLinecode = "PROPSX054TEXT"
    elseif self.doorState == Door.doorStates.LOCKED then
        if self.operation == Door.operations.LOCKED then
            sLinecode = "PROPSX059TEXT"
        else
            sLinecode = "PROPSX052TEXT"
        end
    elseif self.doorState == Door.doorStates.CLOSED then
        sLinecode = "PROPSX057TEXT"
    else
        sLinecode = 'PROPSX056TEXT'
    end
    assertdev(sLinecode)
    return (sLinecode and g_LM.line(sLinecode)) or ''
end

function Door:_setDoorState(nState)
    self.doorState = nState
    self:_updatePathTags()
end

function Door:isInFrontOfDoor(addr)
    for i,doorAddr in ipairs(self.tEastSideTiles) do
        if doorAddr == addr then return true end
    end
    for i,doorAddr in ipairs(self.tWestSideTiles) do
        if doorAddr == addr then return true end
    end
    return false
end


function Door:_updateDoorState(bForceToOperation)
        Profile.enterScope("Door_State")
        --Profile.enterScope("Door_Space")
    self:_updateSpaceStatus()
        --Profile.leaveScope("Door_Space")
    local oldState = self.doorState

    if bForceToOperation then
        -- special-case behavior just for loading games: don't use condition, oxygen, etc.
        -- to set the door's state.
        if self.operation == Door.operations.FORCED_OPEN then 
            self:_setDoorState(Door.doorStates.OPEN)
        elseif self.operation == Door.operations.NORMAL then
            self:_setDoorState(Door.doorStates.CLOSED)
        else -- locked
            self:_setDoorState(Door.doorStates.LOCKED)
        end
    elseif self.nCondition == 0 and (self.bSmashedOpen or self.doorState == Door.doorStates.OPEN) then
        if self.doorState == Door.doorStates.BROKEN_OPEN then
            Profile.leaveScope("Door_State")
            return
        end
        self:_setDoorState(Door.doorStates.BROKEN_OPEN)
    elseif self.nCondition == 0 then
        if self.doorState == Door.doorStates.BROKEN_CLOSED then
            Profile.leaveScope("Door_State")
            return
        end
        self:_setDoorState(Door.doorStates.BROKEN_CLOSED)
    elseif self.operation == Door.operations.FORCED_OPEN then
        if self.doorState == Door.doorStates.OPEN then
            Profile.leaveScope("Door_State")
            return
        end
        self:_setDoorState(Door.doorStates.OPEN)
    elseif self:_isSabotaged() or self.operation == Door.operations.LOCKED or (self.bTouchesVacuum and self.bEastSideVacuum ~= self.bWestSideVacuum) then
        -- doors touching space on one side (but not the other) behave as locked.
        if self.doorState == Door.doorStates.LOCKED then
            Profile.leaveScope("Door_State")
            return
        end
        self:_setDoorState(Door.doorStates.LOCKED)
    elseif self.operation == Door.operations.NORMAL then
		-- no power? open, or seal if one side is vacuum
		if not self:hasPower() then
			if self.bTouchesVacuum and self.bEastSideVacuum ~= self.bWestSideVacuum then
				if self.doorState == Door.doorStates.LOCKED then
					Profile.leaveScope("Door_State")
					return
				end
				self:_setDoorState(Door.doorStates.LOCKED)
			else
				if self.doorState == Door.doorStates.OPEN then
					Profile.leaveScope("Door_State")
					return
				end
				self:_setDoorState(Door.doorStates.OPEN)
			end
		-- has power
		else
			local bOccupied = false
			local tTiles = self:_getAdjacentTiles(true)
			for addr,tile in pairs(tTiles) do
				local rChar = ObjectList.getObjAtTile(tile.x, tile.y, ObjectList.CHARACTER)
				if rChar and not rChar:isElevated() and not self:locked(rChar) then
					bOccupied = true
					break
				end
			end
			if bOccupied then
				if self.doorState ~= Door.doorStates.OPEN then
					self:_setDoorState(Door.doorStates.OPEN)
				else
					Profile.leaveScope("Door_State")
					return
				end
			else
				if self.doorState ~= Door.doorStates.CLOSED then
					self:_setDoorState(Door.doorStates.CLOSED)
				else
					Profile.leaveScope("Door_State")
					return
				end
			end
		end
    end
            --Profile.leaveScope("Door_State")
    
        --Profile.enterScope("Door_Sounds")
    --sounds
    if not bForceToOperation then
        if self.doorState == Door.doorStates.OPEN then 
            if self.sName == "Airlock" then
                SoundManager.playSfx3D("airlockdooropen", self.wx, self.wy, 0) 
            else
                SoundManager.playSfx3D("dooropen", self.wx, self.wy, 0)
            end
        end
        if oldState == Door.doorStates.OPEN then   
            if self.sName == "Airlock" then
                SoundManager.playSfx3D("airlockdoorclose", self.wx, self.wy, 0) 
            else
                SoundManager.playSfx3D("doorclose", self.wx, self.wy, 0) 
            end
        end
    end
        --Profile.leaveScope("Door_Sounds")

        --Profile.enterScope("Door_Path")
    self:_updatePathTags()
        --Profile.leaveScope("Door_Path")
        --Profile.enterScope("Door_Oxygen")
    self:_updateOxygenBlocking()
        --Profile.leaveScope("Door_Oxygen")

    local index = self.spriteSheet.names[ self.sprites[self.doorState] ] 
    self.nIndex = index
    if self:getVisibility() == g_World.VISIBILITY_FULL then
        self:setIndex(index)
    end

            Profile.leaveScope("Door_State")
end

function Door:isPartOfFunctioningAirlock()
	local rEastRoom,rWestRoom = self:getRooms()
	return self.sName == "Airlock" and (rEastRoom and rEastRoom.zoneObj and rEastRoom.zoneObj.bFunctional) or (rWestRoom and rWestRoom.zoneObj and rWestRoom.zoneObj.bFunctional)
end

return Door
