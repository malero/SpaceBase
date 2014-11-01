local Character=require('CharacterConstants')
local ObjectList=require('ObjectList')
local Room=require('Room')
local Asteroid=require('Asteroid')
local ModuleData=require('ModuleData')
local Zone=require('Zones.Zone')
local DFMath=require('DFCommon/Math')
local DFUtil=require('DFCommon.Util')
local GridUtil=require('GridUtil')
local LuaGrid=require('LuaGrid')
local MiscUtil=require('MiscUtil')

local Docking = {}

-- Tweakable constants for controlling the docking system
Docking.nDerelictFreq = .67 -- what portion of the time is this a derelict event vs. a docking event
Docking.nMaxEventsPerAttempt = 2 -- The number of events to try
Docking.nBridgeLength = 5 -- The length of the bridge to try and build for docking ships
Docking.nMaxTestTilesPerRoom = 3 -- The number of border tiles to test for dockability in a given room.

Docking.tEventRequirements=
{
    editMode={ bLoadModule=false, },
    immigrationEvents=
    {
        bLoadModule=false,
        tSpawnRange={15,20},
    },
    hostileImmigrationEvents=
    {
        bLoadModule=false,
        tSpawnRange={15,20},
    },
    friendlyDockingEvents=
    {
        bLoadModule=true,
        bDocking=true,
        tSpawnRange={40,60},
    },
    friendlyDerelictEvents=
    {
        bLoadModule=true,
        bAllowSpawnInAsteroid = true,
        tSpawnRange={40,60},
    },
    hostileDockingEvents=
    {
        bLoadModule=true,
        bDocking=true,
        tSpawnRange={40,60},
    },
    hostileDerelictEvents=
    {
        bLoadModule=true,
        bAllowSpawnInAsteroid = true,
        tSpawnRange={40,60},
    },
}

-- Some dev flags
Docking.CREATE_BRIDGES = true
Docking.DISABLED = false

-- Working data
Docking.nTimeUntilNextEvent = nil

function Docking.init()
    if Docking.DISABLED then
        return
    end
    
    Docking.tLoadedModules = {}

    local function precomputeEventData(sCategory)
        for k,tEvent in pairs(ModuleData[sCategory]) do
            Docking._loadEventData(sCategory,k)
        end
    end
    
    precomputeEventData('friendlyDockingEvents')
    precomputeEventData('friendlyDerelictEvents')
    precomputeEventData('hostileDerelictEvents')
    precomputeEventData('hostileDockingEvents')
    
    --Docking._precomputeEventData('friendlyDockingEvents')
    --Docking._precomputeEventData('friendlyDerelictEvents')
    --Docking._precomputeEventData('hostileDerelictEvents')
    --Docking._precomputeEventData('hostileDockingEvents')
end

function Docking._loadEventData(sCategory,k)
    -- Let's compute the iso bounds for this
    -- The basic algorith is to flood fill diagonally inward from each corner until you find a tile that is not space.
    -- When you find a non-space tile, you know that it lies along the iso bouding plane associated with that corner/side.
    -- The flood fill directions are selected to minimize the chances of duplicate points being produced.
    -- Once the four points are found, we compute the intersections of the bounding planes to find the corners of the iso bounds.
    -- TODO: Precompute and save this out along with the module.
    local tEvent = ModuleData[sCategory][k]
        -- Cache.
        if not Docking.tLoadedModules[sCategory] then Docking.tLoadedModules[sCategory] = {} end
        if Docking.tLoadedModules[sCategory][k] then return end
        
        tEvent.sName=k
        local tModuleData = require('GameRules').loadModule(sCategory,k)
        
        Docking.tLoadedModules[sCategory][k] = tModuleData
        
        local tSaveData = tModuleData.tSaveData
        
        if not tSaveData then return end
        
        tSaveData.tWorldSaveData.pathGrid = LuaGrid.fromSaveData(tSaveData.tWorldSaveData.pathGrid, false, {nDefaultVal=g_World.logicalTiles.SPACE})
        tSaveData.tWorldSaveData.oxygenGrid = LuaGrid.fromSaveData(tSaveData.tWorldSaveData.oxygenGrid, false, {nDefaultVal=0})
        
        tEvent.isoBoundsUpperLeftX = 0 
        tEvent.isoBoundsLowerLeftX = 0
        tEvent.isoBoundsUpperRightX = 0
        tEvent.isoBoundsLowerRightX = 0
        tEvent.isoBoundsLowerRightY = 0 
        tEvent.isoBoundsLowerLeftY = 0
        tEvent.isoBoundsUpperRightY = 0
        tEvent.isoBoundsUpperLeftY = 0
        
        if next(tSaveData.tWorldSaveData.pathGrid.tTiles) == nil then
            -- no tiles, no bounds
        else
            local bZero = false

        -- Find the SW bounds plane
        local lowerLeftX = tSaveData.tWorldSaveData.minX
        local lowerLeftY = tSaveData.tWorldSaveData.minY
        while lowerLeftY <= tSaveData.tWorldSaveData.maxY and lowerLeftY >= tSaveData.tWorldSaveData.minY do
            local currentX = lowerLeftX
            local currentY = lowerLeftY
            local hitSomething = false
            while currentX >= tSaveData.tWorldSaveData.minX and currentY >= tSaveData.tWorldSaveData.minY and
                  currentX <= tSaveData.tWorldSaveData.maxX and currentY <= tSaveData.tWorldSaveData.maxY do
                if tSaveData.tWorldSaveData.pathGrid:getTileValue(currentX, currentY) ~= g_World.logicalTiles.SPACE then
                    lowerLeftX = currentX
                    lowerLeftY = currentY
                    hitSomething = true
                    break
                else
                    currentX, currentY = g_World._getAdjacentTile(currentX, currentY, g_World.directions.SE)
                end
            end
            if hitSomething then
                break
            else
                lowerLeftX, lowerLeftY = g_World._getAdjacentTile(lowerLeftX, lowerLeftY, g_World.directions.N)
            end
        end

        -- Find the SE bounds plane
        local lowerRightX = tSaveData.tWorldSaveData.maxX
        local lowerRightY = tSaveData.tWorldSaveData.minY
        while lowerRightX >= tSaveData.tWorldSaveData.minX and lowerRightX <= tSaveData.tWorldSaveData.maxX do
            local currentX = lowerRightX
            local currentY = lowerRightY
            local hitSomething = false
            while currentX >= tSaveData.tWorldSaveData.minX and currentY >= tSaveData.tWorldSaveData.minY and
                  currentX <= tSaveData.tWorldSaveData.maxX and currentY <= tSaveData.tWorldSaveData.maxY do
                if tSaveData.tWorldSaveData.pathGrid:getTileValue(currentX, currentY) ~= g_World.logicalTiles.SPACE then
                    lowerRightX = currentX
                    lowerRightY = currentY
                    hitSomething = true
                    break
                else
                    currentX, currentY = g_World._getAdjacentTile(currentX, currentY, g_World.directions.NE)
                end
            end
            if hitSomething then
                break
            else
                lowerRightX, lowerRightY = g_World._getAdjacentTile(lowerRightX, lowerRightY, g_World.directions.W)
            end
        end

        -- Find the NE bounds plane
        local upperRightX = tSaveData.tWorldSaveData.maxX
        local upperRightY = tSaveData.tWorldSaveData.maxY
        while upperRightX >= tSaveData.tWorldSaveData.minX and upperRightX <= tSaveData.tWorldSaveData.maxX do
            local currentX = upperRightX
            local currentY = upperRightY
            local hitSomething = false
            while currentX >= tSaveData.tWorldSaveData.minX and currentY >= tSaveData.tWorldSaveData.minY and
                  currentX <= tSaveData.tWorldSaveData.maxX and currentY <= tSaveData.tWorldSaveData.maxY do
                if tSaveData.tWorldSaveData.pathGrid:getTileValue(currentX, currentY) ~= g_World.logicalTiles.SPACE then
                    upperRightX = currentX
                    upperRightY = currentY
                    hitSomething = true
                    break
                else
                    currentX, currentY = g_World._getAdjacentTile(currentX, currentY, g_World.directions.NW)
                end
            end
            if hitSomething then
                break
            else
                upperRightX, upperRightY = g_World._getAdjacentTile(upperRightX, upperRightY, g_World.directions.S)
            end
        end

        -- Find the NW bounds plane
        local upperLeftX = tSaveData.tWorldSaveData.minX
        local upperLeftY = tSaveData.tWorldSaveData.maxY
        while upperLeftX >= tSaveData.tWorldSaveData.minX and upperLeftX <= tSaveData.tWorldSaveData.maxX do
            local currentX = upperLeftX
            local currentY = upperLeftY
            local hitSomething = false
            while currentX >= tSaveData.tWorldSaveData.minX and currentY >= tSaveData.tWorldSaveData.minY and
                  currentX <= tSaveData.tWorldSaveData.maxX and currentY <= tSaveData.tWorldSaveData.maxY do
                if tSaveData.tWorldSaveData.pathGrid:getTileValue(currentX, currentY) ~= g_World.logicalTiles.SPACE then
                    upperLeftX = currentX
                    upperLeftY = currentY
                    hitSomething = true
                    break
                else
                    currentX, currentY = g_World._getAdjacentTile(currentX, currentY, g_World.directions.SW)
                end
            end
            if hitSomething then
                break
            else
                upperLeftX, upperLeftY = g_World._getAdjacentTile(upperLeftX, upperLeftY, g_World.directions.E)
            end
        end

        -- Now, intersect the planes to find the 4 corners.
        tEvent.isoBoundsLowerLeftX, tEvent.isoBoundsLowerLeftY = GridUtil.ComputeIsoIntersect(lowerLeftX, lowerLeftY, lowerRightX, lowerRightY)
        tEvent.isoBoundsLowerRightX, tEvent.isoBoundsLowerRightY = GridUtil.ComputeIsoIntersect(upperRightX, upperRightY, lowerRightX, lowerRightY)
        tEvent.isoBoundsUpperRightX, tEvent.isoBoundsUpperRightY = GridUtil.ComputeIsoIntersect(upperRightX, upperRightY, upperLeftX, upperLeftY)
        tEvent.isoBoundsUpperLeftX, tEvent.isoBoundsUpperLeftY = GridUtil.ComputeIsoIntersect(lowerLeftX, lowerLeftY, upperLeftX, upperLeftY)
        end

        -- Sanity check the results.
        assert(tEvent.isoBoundsUpperLeftX <= tEvent.isoBoundsLowerLeftX)
        assert(tEvent.isoBoundsUpperRightX <= tEvent.isoBoundsLowerRightX)
        assert(tEvent.isoBoundsLowerRightY >= tEvent.isoBoundsLowerLeftY)
        assert(tEvent.isoBoundsUpperRightY >= tEvent.isoBoundsUpperLeftY)
end

function Docking._createDoorAt(tx,ty)
    if not ObjectList.getDoorAtTile(tx,ty) then
        local wx,wy = g_World._getWorldFromTile(tx,ty)
        require('EnvObjects.EnvObject').createEnvObject('Door', wx, wy, nil, nil, true)
    end
end

function Docking._testModuleFit(tPossibleEvent, tModuleData, tDockingTile, nDockingCoordsX, nDockingCoordsY, sEventType)
        local moduleOffsetTX,moduleOffsetTY
        local tSaveData
        local tEventRequirements = Docking.tEventRequirements[sEventType]
        if not tEventRequirements.bLoadModule then
            -- not using a module for immigration (for now!), so we just make some numbers up 
            -- to give it a little room away from structures and asteroids.
            tSaveData={ tWorldSaveData={ minX=123,minY=117,maxX=133,maxY=139} }
            tPossibleEvent = {}
            tPossibleEvent.isoBoundsLowerLeftX = 127.75
            tPossibleEvent.isoBoundsLowerLeftY = 112.5
            tPossibleEvent.isoBoundsLowerRightX = 135.25
            tPossibleEvent.isoBoundsLowerRightY = 127.5
            tPossibleEvent.isoBoundsUpperLeftX = 120.25
            tPossibleEvent.isoBoundsUpperLeftY= 127.5
            tPossibleEvent.isoBoundsUpperRightX = 127.75
            tPossibleEvent.isoBoundsUpperRightY = 142.5
        else
            tSaveData = tModuleData.tSaveData
        end

        if tEventRequirements.bDocking then
            -- we always dock at a pre-authored port location.
            -- ships are expected to have one for each grid side, but we'll try not to crash if they don't.
            -- If it becomes common to have an incomplete set of docking ports, we'll want to move this check earlier.
            local tDockingPort = tSaveData.tWorldSaveData.dockingPoints and tSaveData.tWorldSaveData.dockingPoints[tDockingTile.nRoomDirection]
            if tDockingPort == nil then
                Print(TT_Error, "Shouldn't create a docking event without a docking port. Data error", tPossibleEvent.sName)
            else
                -- Math doesn't work on MOAI's busted iso tile system, so I translate everything to world coords to do
                -- the math, and then back to tile coords.
                -- Get the loc of the docking port. Offset so that loc lines up with nDockingCoordsX/Y.
                local portWX,portWY = g_World._getWorldFromTile(tDockingPort.tileX, tDockingPort.tileY)
                local dockingCoordsWX,dockingCoordsWY = g_World._getWorldFromTile(nDockingCoordsX,nDockingCoordsY)
                local dockingOffsetWX = dockingCoordsWX - (portWX-tSaveData.tWorldSaveData.worldMinX)
                local dockingOffsetWY = dockingCoordsWY - (portWY-tSaveData.tWorldSaveData.worldMinY)
                moduleOffsetTX,moduleOffsetTY = g_World._getTileFromWorld(dockingOffsetWX,dockingOffsetWY)
                
                --moduleOffsetTX = nDockingCoordsX - (tDockingPort.tileX - tSaveData.tWorldSaveData.minX)
                --moduleOffsetTY = nDockingCoordsY - (tDockingPort.tileY - tSaveData.tWorldSaveData.minY)
            end
        else
            -- for non-dockers, "docking" coords are really just spawn coords.
            -- let's center it, though.
            local tw,th = tSaveData.tWorldSaveData.maxX-tSaveData.tWorldSaveData.minX,tSaveData.tWorldSaveData.maxY-tSaveData.tWorldSaveData.minY
            moduleOffsetTX = nDockingCoordsX - math.ceil(tw*.5)
            moduleOffsetTY = nDockingCoordsY - math.ceil(th*.5)
        end
            
        if moduleOffsetTX then
            if Docking._testModuleFitAtOffset(sEventType, tPossibleEvent, tModuleData, moduleOffsetTX, moduleOffsetTY) then
                return moduleOffsetTX,moduleOffsetTY
            end
        end
end

function Docking.getModule(sSet,sModule)
    if not Docking.tLoadedModules[sSet] or not Docking.tLoadedModules[sSet][sModule] then
        Docking._loadEventData(sSet,sModule)
    end
    return Docking.tLoadedModules[sSet][sModule]
end

function Docking.testModuleFitAtOffset(sEventType, tPossibleEvent, sModuleSet, sModuleName, moduleOffsetTX, moduleOffsetTY)
    local tModuleData = Docking.tLoadedModules[sModuleSet][sModuleName]
    return Docking._testModuleFitAtOffset(sEventType, tPossibleEvent, tModuleData, moduleOffsetTX, moduleOffsetTY)
end

function Docking._testModuleFitAtOffset(sEventType, tPossibleEvent, tModuleData, moduleOffsetTX, moduleOffsetTY)
    local tSaveData = tModuleData.tSaveData
            local lowerLeftX, lowerLeftY, lowerRightX, lowerRightY, upperRightX, upperRightY, upperLeftX, upperLeftY
            lowerLeftX = moduleOffsetTX + (tPossibleEvent.isoBoundsLowerLeftX - tSaveData.tWorldSaveData.minX)
            lowerLeftY = moduleOffsetTY + (tPossibleEvent.isoBoundsLowerLeftY - tSaveData.tWorldSaveData.minY)
            lowerRightX = moduleOffsetTX + (tPossibleEvent.isoBoundsLowerRightX - tSaveData.tWorldSaveData.minX)
            lowerRightY = moduleOffsetTY + (tPossibleEvent.isoBoundsLowerRightY - tSaveData.tWorldSaveData.minY)
            upperRightX = moduleOffsetTX + (tPossibleEvent.isoBoundsUpperRightX - tSaveData.tWorldSaveData.minX)
            upperRightY = moduleOffsetTY + (tPossibleEvent.isoBoundsUpperRightY - tSaveData.tWorldSaveData.minY)
            upperLeftX = moduleOffsetTX + (tPossibleEvent.isoBoundsUpperLeftX - tSaveData.tWorldSaveData.minX)
            upperLeftY = moduleOffsetTY + (tPossibleEvent.isoBoundsUpperLeftY- tSaveData.tWorldSaveData.minY)
            -- Check to see if there is space to fit the iso bounds of the candidate module
            if Docking._isIsoAreaSpace(sEventType, lowerLeftX, lowerLeftY, lowerRightX, lowerRightY, upperRightX, upperRightY, upperLeftX, upperLeftY) then
                return true
            end
end

function Docking.spawnModule(tEventData)
    local tModuleData = {}
    if tEventData.sModuleName then
        tModuleData = Docking.tLoadedModules[tEventData.sSetName][tEventData.sModuleName]
        tModuleData.tRoomTile = tEventData.tRoomTile
        tModuleData.sModuleEventName = tEventData.sModuleEventName
    end
    local sEventName = Docking._spawnModule(
            tEventData,
            tModuleData,
            tEventData.tx, tEventData.ty,
            tEventData.tDockingTile)
end

-- HACK: Poor encapsulation of tEventData. Should be handled by Event.lua, not Docking.lua.
function Docking._spawnModule(tEventData, tModuleData, tx, ty, tDockingTile)
    local sEventType = tEventData.sEventType
    local tCrewData = tEventData.tCrewData
    local tObjectData = tEventData.tObjectData
    local tSaveData = tModuleData.tSaveData
    local wx,wy = g_World._getWorldFromTile(tx,ty)
    local nDefaultFactionBehavior = (tModuleData.bHostile and Character.FACTION_BEHAVIOR.EnemyGroup) or Character.FACTION_BEHAVIOR.Friendly
    local nNewTeam = g_World.loadModule(tSaveData.nSavegameVersion, tSaveData.tWorldSaveData, wx, wy, nDefaultFactionBehavior )
    require('EventController').spawnModuleEntities(
        tEventData, tModuleData,
        {
            nDefaultTeam = nNewTeam,
            nDefaultFactionBehavior = nDefaultFactionBehavior
        })

    g_World.bSuspendFixupVisuals = true
    
    -- Create the bridge
    if tDockingTile then
        -- create base-side door
        local doorX, doorY = g_World._getAdjacentTile(tDockingTile.x, tDockingTile.y, tDockingTile.nRoomDirection)
        Docking._createDoorAt(doorX,doorY)
        
        -- create hallway
        local nDockingCoordsX = tDockingTile.x
        local nDockingCoordsY = tDockingTile.y
        local nEmptySpaceDirection = g_World.getOppositeDirection(tDockingTile.nRoomDirection)
        local nLeftDirection = g_World.getPerpindicularDirection(nEmptySpaceDirection)
        local nRightDirection = g_World.getOppositeDirection(nLeftDirection)

        while g_World._getTileValue(nDockingCoordsX, nDockingCoordsY) == g_World.logicalTiles.SPACE do
            g_World._setTile(nDockingCoordsX, nDockingCoordsY, g_World.logicalTiles.ZONE_LIST_START)
            local leftWallX, leftWallY = g_World._getAdjacentTile(nDockingCoordsX, nDockingCoordsY, nLeftDirection)
            g_World._setTile(leftWallX, leftWallY, g_World.logicalTiles.WALL)
            local rightWallX, rightWallY = g_World._getAdjacentTile(nDockingCoordsX, nDockingCoordsY, nRightDirection)
            g_World._setTile(rightWallX, rightWallY, g_World.logicalTiles.WALL)
            nDockingCoordsX, nDockingCoordsY = g_World._getAdjacentTile(nDockingCoordsX, nDockingCoordsY, nEmptySpaceDirection)
        end
        
        -- create module-side door
        g_World._setTile(nDockingCoordsX, nDockingCoordsY, g_World.logicalTiles.DOOR)
        Docking._createDoorAt(nDockingCoordsX, nDockingCoordsY)
    end
    
    -- clean up the docking point locators embedded in the module
    local fn = ObjectList.getTypeIterater(ObjectList.ENVOBJECT,false,'DockPoint')
    local rEnvObj = fn()
    while rEnvObj do
        rEnvObj:remove()
        rEnvObj = fn()
    end
    
    g_World.bSuspendFixupVisuals = false

    -- HACK: docking tells non-visible things to sim.
    if tDockingTile then
        local tRooms = Room.getRoomsOfTeam(nNewTeam)
        for rRoom, id in pairs(tRooms) do
            rRoom.bForceSim = true
        end
        local tChars = require('CharacterManager').getTeamCharacters(nNewTeam,true)
        for _,rChar in pairs(tChars) do
            rChar.tStatus.bForceSim=true
        end
        require('CharacterManager').updateOwnedCharacters()
    end
    
    -- Update all the world state.
    --g_World.fixupVisuals()
    return tModuleData.sModuleName
    
end

function Docking._queueUpBuild(tModuleData,tx,ty,sEventType, tDockingTile,bDBGForceHostile)
    Docking.tQueuedEvent = {}
    
    Docking.tQueuedEvent.sSetName = tModuleData.sSetName
    Docking.tQueuedEvent.sModuleName = tModuleData.sModuleName
    Docking.tQueuedEvent.tRoomTile = tModuleData.tRoomTile
    Docking.tQueuedEvent.sModuleEventName = tModuleData.sModuleEventName
    
    Docking.tQueuedEvent.tx = tx
    Docking.tQueuedEvent.ty = ty
    Docking.tQueuedEvent.tDockingTile = tDockingTile
    Docking.tQueuedEvent.sEventType = sEventType
    Docking.tQueuedEvent.bDBGForceHostile = bDBGForceHostile
    return Docking.tQueuedEvent
end

function Docking.getQueuedEvent()
    return Docking.tQueuedEvent
end

function Docking.attemptQueueEvent(sEventType, nEventDifficulty)
    nEventDifficulty = nEventDifficulty or 0
    local tEventRequirements = Docking.tEventRequirements[sEventType]
    local bDockingEvent = tEventRequirements.bDocking

    -- we only want to iterate through exterior rooms
    local tExteriorRooms = {}
    local tRooms = Room.getRoomsOfTeam(Character.TEAM_ID_PLAYER)
    local nRooms = DFUtil.tableSize(tRooms)
    local bAdded = false
    for room,id in pairs(tRooms) do
        if room.bExterior and not room:isDangerous() then
            tExteriorRooms[id] = room
            bAdded = true
        end
    end

    -- no rooms! OR, if this is a docking event and no exterior rooms
    if nRooms == 0 or (not bAdded and tEventRequirements and tEventRequirements.bDocking) then
        return
    end

    -- Now build up a list of possible events based on the available rooms.
    -- We also sum up the weights as an optimization for the random selection later.
    local tValidEvents = {}
    local nTotalWeight = 0
    for name,event in pairs(ModuleData[sEventType]) do
        if event.difficulty and event.difficulty > nEventDifficulty then
            -- nope.
        elseif event.tRequiredZones then
            -- if the event specifies required zones types, check for them.
            -- As an optimization, cache all of the rooms that could work for this event, now.
            -- Make sure the cache is clear before populating it.
            assert(sEventType == 'hostileDockingEvents' or sEventType == 'friendlyDockingEvents')
            event.tPotentialRooms = {}
            local bValidEvent = false
            for i,room in pairs(tExteriorRooms) do
                if event.tRequiredZones[room.zoneName] then
                    table.insert(event.tPotentialRooms, room)
                    bValidEvent = true
                end
            end
            if bValidEvent then
                table.insert(tValidEvents, event)
                nTotalWeight = nTotalWeight + (event.weight or 1)
            end
        else -- if no required zones, the event is always valid.
            -- And add all of the exterior rooms to the list
            event.tPotentialRooms = {}
            for i,room in pairs(tExteriorRooms) do
                table.insert(event.tPotentialRooms, room)
            end
            table.insert(tValidEvents, event)
            nTotalWeight = nTotalWeight + (event.weight or 1)
        end
    end

    if #tValidEvents == 0 then
        return
    end

    local tPossibleEvents = Docking._selectRandomEvents(tValidEvents, nTotalWeight, Docking.nMaxEventsPerAttempt)
    for tPossibleEvent in tPossibleEvents do
        -- pick a random, valid room
        local tCandidateRoom = nil
        if #tPossibleEvent.tPotentialRooms > 0 then
            tCandidateRoom = DFUtil.arrayRandom(tPossibleEvent.tPotentialRooms)
        elseif tEventRequirements and not tEventRequirements.bDocking then
            _, tCandidateRoom = DFUtil.tableRandom(tRooms, nRooms)
        end
        local tModuleData, tx, ty, tDockingTile = Docking._testCandidateRoom(tCandidateRoom,tPossibleEvent,sEventType)
        if tModuleData then
            if not bDockingEvent then
                tDockingTile = nil
            end
            tModuleData.tRoomTile = { tCandidateRoom.nCenterTileX, tCandidateRoom.nCenterTileY, tCandidateRoom.nLevel }
            tModuleData.sModuleEventName = tPossibleEvent.sName
            return Docking._queueUpBuild(tModuleData, tx, ty, sEventType, tDockingTile)
        end
    end
end

-- Returns a tile coordinate some distance from the candidate tile.
function Docking._getNonDockedSpawnLoc(tCandidateTile,tSpawnRange)
    local nEmptySpaceDirection = g_World.getOppositeDirection(tCandidateTile.nRoomDirection)
    local nDist = math.random(tSpawnRange[1],tSpawnRange[2])
    local tx,ty = tCandidateTile.x,tCandidateTile.y
    for i=1,nDist do
        tx,ty = g_World._getAdjacentTile(tx,ty,nEmptySpaceDirection)
    end
    return g_World.clampTileToBounds(tx, ty)
end

-- Tests to see if we can attach a docking bridge to the tile.
-- returns the x and y coordinate of the end of the docking bridge, e.g. the location 
-- where the spawned module will attach.
function Docking._testTileForDockingBridge(tCandidateTile)
    -- for now, only accept tiles that have 3 adjacent walls (i.e. are likely to be locally flat)
    -- and which have a room direction that's colinear with a grid axis
    if #tCandidateTile.tWallDirections == 3 and (tCandidateTile.nRoomDirection >= g_World.directions.NW and tCandidateTile.nRoomDirection <= g_World.directions.SE) then
        -- Compute some directions that will be useful later
        local nEmptySpaceDirection = g_World.getOppositeDirection(tCandidateTile.nRoomDirection)
        local nLeftDirection = g_World.getPerpindicularDirection(nEmptySpaceDirection)
        local nRightDirection = g_World.getOppositeDirection(nLeftDirection)

        -- Docking coords will be used as a sort of "cursor" for placing the docked module.
        local nDockingCoordsX = tCandidateTile.x
        local nDockingCoordsY = tCandidateTile.y

        -- let's check for clear space for the bridge
        -- this intentionally modifies the docking coords in order to move the "cursor"
        local bCanBuildBridge = true
        -- we start at 2 because we know the starting space is exterior and hence clear space.
        for nBridgeIndex = 2,Docking.nBridgeLength do
            nDockingCoordsX, nDockingCoordsY = g_World._getAdjacentTile(nDockingCoordsX, nDockingCoordsY, nEmptySpaceDirection)
            if g_World._getTileValue(nDockingCoordsX, nDockingCoordsY) ~= g_World.logicalTiles.SPACE or
               g_World._getTileValue(g_World._getAdjacentTile(nDockingCoordsX, nDockingCoordsY, nLeftDirection)) ~= g_World.logicalTiles.SPACE or
               g_World._getTileValue(g_World._getAdjacentTile(nDockingCoordsX, nDockingCoordsY, nRightDirection)) ~= g_World.logicalTiles.SPACE
            then
                bCanBuildBridge = false
                break
            end
        end

        -- if we have enough space to build a bridge, let's try to fit the module in.
        if bCanBuildBridge then
            return nDockingCoordsX, nDockingCoordsY
        end
    end
end

function Docking._testCandidateRoom(tCandidateRoom,tPossibleEvent,sEventType)
    assertdev(sEventType)
    if not sEventType then return end

    local tEventRequirements = Docking.tEventRequirements[sEventType]
    -- sample a random set of tiles, looking for good candidates
    -- Dupe the exterior list because we're going to modify it.
    local tExteriorCopies = DFUtil.deepCopy(tCandidateRoom.tExteriors)
    local nExteriorTiles = DFUtil.tableSize(tExteriorCopies)

    -- if not a docking event, settle for the border tiles if no exterior ones
    if nExteriorTiles == 0 then
        if tEventRequirements.bDocking then
            return
        else
            tExteriorCopies = DFUtil.deepCopy(tCandidateRoom.tBorders)
            nExteriorTiles = DFUtil.tableSize(tExteriorCopies)
            if nExteriorTiles == 0 then return end
        end
    end
    local nMaxTests = (tEventRequirements.bDocking and math.min(Docking.nMaxTestTilesPerRoom, nExteriorTiles)) or 1

    local tModuleData

    for nTileIndex = 1, nMaxTests do
        -- select a random tile from the list
        local tCandidateTile, nCandidateIndex = DFUtil.tableRandom(tExteriorCopies, nExteriorTiles)
        -- and then remove it from the list
        tExteriorCopies[nCandidateIndex] = nil
        nExteriorTiles = nExteriorTiles - 1

        local nDockingCoordsX, nDockingCoordsY
        if tEventRequirements.bDocking then
            nDockingCoordsX, nDockingCoordsY = Docking._testTileForDockingBridge(tCandidateTile)
        else
            nDockingCoordsX, nDockingCoordsY = Docking._getNonDockedSpawnLoc(tCandidateTile,tEventRequirements.tSpawnRange)
        end

        if nDockingCoordsX then
            if not tEventRequirements.bLoadModule then
                tModuleData = {}
            elseif not tModuleData then
                tModuleData = DFUtil.deepCopy(Docking.tLoadedModules[sEventType][tPossibleEvent.sName])
            end
            local spawnTX,spawnTY = Docking._testModuleFit(tPossibleEvent, tModuleData, tCandidateTile, nDockingCoordsX,nDockingCoordsY, sEventType)
            if spawnTX then
                return tModuleData, spawnTX,spawnTY, tCandidateTile
            end
        end
    end
end

-- Returns an iterator that will randomly select nEvents elements from a list of weighted events.
-- Implementation is based the weighted sampling w/ replacement algo at http://stackoverflow.com/a/2149533
function Docking._selectRandomEvents(tPossibleEvents, totalWeight, nEvents)
    local i = 1
    local tEvent = tPossibleEvents[i]
    local weight = tEvent.weight or 1
    return function()
        while nEvents > 0 do
            local x = totalWeight * (1 - math.pow(math.random(), 1.0 / nEvents))
            totalWeight = totalWeight - x
            while x > weight do
                x = x - weight
                i = i + 1
                tEvent = tPossibleEvents[i]
                weight = (tEvent.weight or 1)
            end
            weight = weight - x
            nEvents = nEvents - 1
            return tEvent
        end
    end
end

-- Checks the specified isometric region of the world to see if it's entirely clear space.
-- Returns true if the region is clear, false if it is not.
function Docking._isIsoAreaSpace(sEventType, lowerLeftX, lowerLeftY, lowerRightX, lowerRightY, upperRightX, upperRightY, upperLeftX, upperLeftY)
    -- compute the width and height assuming the slope of our grid.
    local nTilesHoriz = math.floor(((lowerRightX - lowerLeftX) * 2) + 0.5)
    local nTilesVert = math.floor((upperLeftY - lowerLeftY) + 0.5)
    local tEventRequirements = Docking.tEventRequirements[sEventType]
    local bAsteroidsAllowed = tEventRequirements.bAllowSpawnInAsteroid

    -- Search through the grid for anything that's not empty space.
    local baseX = lowerLeftX
    local baseY = lowerLeftY
    for i = 1,nTilesHoriz do
        local testX = baseX
        local testY = baseY
        for j = 1,nTilesVert do
            if testX < g_World.CHARACTER_SAFETY_TOLERANCE or testY < g_World.CHARACTER_SAFETY_TOLERANCE 
                    or testX > g_World.width - g_World.CHARACTER_SAFETY_TOLERANCE or testY > g_World.height - g_World.CHARACTER_SAFETY_TOLERANCE then
                return false
            end

            local tileValue = g_World._getTileValue(testX, testY)
            if not tileValue or tileValue == 0 or (tileValue ~= g_World.logicalTiles.SPACE and (not bAsteroidsAllowed or not Asteroid.isAsteroid(tileValue))) then
                return false
            end
            testX, testY = g_World._getAdjacentTile(testX, testY, g_World.directions.NW)
        end
        baseX, baseY = g_World._getAdjacentTile(baseX, baseY, g_World.directions.NE)
    end

    return true
end

return Docking
