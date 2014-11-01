local Oxygen=require('Oxygen')
local ObjectList=require('ObjectList')
local Class=require('Class')
local MiscUtil=require('MiscUtil')
local DFUtil=require('DFCommon.Util')
local Pathfinder=require('Pathfinder')
local Door=require('EnvObjects.Door')
local Malady=require('Malady')
local OptionData=require('Utility.OptionData')
local Zone=require('Zones.Zone')
local Room=require('Room')
local ActivityOptionList=require('Utility.ActivityOptionList')
g_ActivityOption=g_ActivityOption or require('Utility.ActivityOption')
local CommandObject=require('Utility.CommandObject')
local GameRules=require('GameRules')
local Character=require('Character')
local AirlockDoor = require('EnvObjects.Airlock')

local Airlock = Class.create(Zone)

Airlock.STAGE_CLOSE_DOORS = 1
Airlock.STAGE_VENT = 2
Airlock.STAGE_OPEN_DOORS = 3
Airlock.STAGE_LEAVE = 4
Airlock.STAGE_RECLOSE_DOORS = 5
Airlock.STAGE_REPRESSURIZE = 6
Airlock.STAGE_UNLOCK = 7

Airlock.MAX_OPEN_WAIT_TIME = 4

-- fraction of max oxygen that can be vented in one second.
Airlock.OXYGEN_INCREASE_RATE = .3

function Airlock:init(rRoom)
    Zone.init(self,rRoom)
    self.tOwnedDoors = {}
    self.bDangerous = true
    self.tBuildOrders = {}
    self.bForceSim=true
    
    self.doorMonitorState = AirlockDoor.monitorStates.OXYNONE 
    
    self.activityOptionList = ActivityOptionList.new(self)
end

function Airlock:getEnemyActivityOptions(rChar, tObjects)
	return self:getActivityOptions(rChar, tObjects)
end

function Airlock:getActivityOptions(rChar, tObjects)
    tObjects = tObjects or {}
    table.insert(tObjects, self.activityOptionList:getListAsUtilityOptions())
    return tObjects
end

function Airlock:remove()
    Zone.remove(self)
    self:endOpenSequence()

    for rDoor,_ in pairs(self.tOwnedDoors) do
        if rDoor.bDestroyed then 
            self.tOwnedDoors[rDoor] = nil
        elseif rDoor.setOwnedByZone then
            rDoor:setOwnedByZone(self,false)
        end
    end
    self.tOwnedDoors = {}
end

function Airlock:preTileUpdate()
    if self.bRunning then
        self:_claimDoors(false)
    end
end

function Airlock:disallowO2Propagation()
    return self.bRunning
end

function Airlock:postTileUpdate()
    if self.bRunning then
        if not self:_claimDoors(true) then
            self:endOpenSequence()
        end
    end
end

-- return true if it's unsafe to open. Please abort open sequence!
function Airlock:_testSafetyInterrupt(bIncapacitatedOnly)
    local tChars,numChars = self.rRoom:getCharactersInRoom(true)
    for rChar,_ in pairs(tChars) do
        if rChar:getFactionBehavior() == Character.FACTION_BEHAVIOR.Citizen or rChar:getFactionBehavior() == Character.FACTION_BEHAVIOR.Friendly then
            if not rChar:wearingSpacesuit() then
                if bIncapacitatedOnly then
                    if Malady.isIncapacitated(rChar) then
                        return true
                    end
                else
                    return true
                end
            end
        end
    end
end

function Airlock:_testTimeout(dt,nMaxWait)
    self.nTimeoutTest = self.nTimeoutTest+dt
    if self.nTimeoutTest > nMaxWait then
        return true
    end
end

function Airlock:_tickOpenSequence(dt)
    if self.nStage == Airlock.STAGE_CLOSE_DOORS then
        if self:_attemptChangeDoors(dt,Door.operations.LOCKED,Door.doorStates.LOCKED) then
            self:_incrementStage()
        elseif self:_testTimeout(dt,5) then
            self.nStage = Airlock.STAGE_REPRESSURIZE
        end
    elseif self.nStage == Airlock.STAGE_VENT then
        if self:_testSafetyInterrupt() then
            self.nStage = Airlock.STAGE_REPRESSURIZE
        elseif self:_tickVenting(dt,false) then
            self:_incrementStage()
        end
    elseif self.nStage == Airlock.STAGE_OPEN_DOORS then
        if self:_testSafetyInterrupt() then
            self.nStage = Airlock.STAGE_RECLOSE_DOORS
        elseif self:_attemptChangeDoors(dt,Door.operations.FORCED_OPEN,Door.doorStates.OPEN,true) then
            self:_incrementStage()
        elseif self:_testTimeout(dt,5) then
            self.nStage = Airlock.STAGE_REPRESSURIZE
        end
    elseif self.nStage == Airlock.STAGE_LEAVE then
        if self:_waitForDudesToLeave(dt) then
            self:_incrementStage()
        end
    elseif self.nStage == Airlock.STAGE_RECLOSE_DOORS then
        if self:_attemptChangeDoors(dt,Door.operations.LOCKED,Door.doorStates.LOCKED) then
            self:_incrementStage()
        elseif self:_testTimeout(dt,5) then
            self.nStage = Airlock.STAGE_REPRESSURIZE
        end
    elseif self.nStage == Airlock.STAGE_REPRESSURIZE then
        if self:_tickVenting(dt,true) then
            self:_incrementStage()
        end
    elseif self.nStage == Airlock.STAGE_UNLOCK then
        for addr,_ in pairs(self.rRoom.tDoors) do
            local rDoor = ObjectList.getDoorAtTile(g_World.pathGrid:cellAddrToCoord(addr))
            if rDoor then
                rDoor:setOperation(Door.operations.NORMAL)
                rDoor:_updateDoorState(false, true)
            end
        end
        self:endOpenSequence()
    end
end

function Airlock:isSafe(wx,wy)
    if self.nStage == Airlock.STAGE_UNLOCK or not self.bRunning then
        local tx,ty = self.rRoom:getCenterTile(true,true)
        local o2 = g_World.oxygenGrid:getOxygen(tx,ty)
        return o2 > Character.OXYGEN_LOW
        -- we could check oxygen level in the room to be extra safe.
        --local tx, ty = g_World._getTileFromWorld(wx,wy)
        --g_World.oxygenGrid:setOxygen(newTileX,newTileY, saveData.oxygenGrid:getOxygen(x,y))
    end
end

function Airlock:beginOpenSequence()
    assert(not self.bRunning)
    self.bRunning = true
    self.nStage = nil
    if self:_claimDoors(true) then
        self:_incrementStage()
    else
        self.bRunning = false
    end
end

function Airlock:endOpenSequence()
    self:_claimDoors(false)
    self.bRunning = false
end

function Airlock:_claimDoors(bClaim)
    local bSuccess = true
    if not self.rRoom then
        Print(TT_Error,"Claiming a door without a room.")
        return
    end
    for addr,_ in pairs(self.rRoom.tDoors) do
        local rDoor = ObjectList.getDoorAtTile(g_World.pathGrid:cellAddrToCoord(addr))
        if rDoor and rDoor.sName == 'Airlock' then 
            local oldController = rDoor:getScriptController()
            if bClaim and oldController and oldController ~= self and oldController.bFunctional and oldController.bRunning then
                bSuccess = false
                -- whee, fighting for doors! For now, uh... give up. smh.
            elseif bClaim then
                rDoor:setScriptController(self)
            elseif rDoor:getScriptController() == self then
                rDoor:setScriptController(nil)
            end
        elseif not rDoor then
            Print(TT_Error,"Room lists a door that does not exist.")
        end
    end
    self.bClaimed = bSuccess and bClaim
    return bSuccess
end

function Airlock:_incrementStage()
    self.nStage = (self.nStage and self.nStage+1) or 1
    self.nStartingOxygen = nil
    self.nDesiredOxygen = nil
    self.nTimeWaited = nil
    self.nTimeoutTest = 0
end

function Airlock:getLightingOverride()
    if not self.bFunctional then
        return Room.LIGHTING_SCHEME_VACUUM
    end
end

function Airlock:onTick(dt)

    self:_updateDoorMonitor()
    
    if self.bRunning then
        self:_tickOpenSequence(dt)
        return
    end    

    local bFunctional = true
    local sNonFunctionalReason = nil
    if self.rRoom:disallowO2Propagation() then
        bFunctional = false
        sNonFunctionalReason = 'INSPEC153TEXT'
    end
    if bFunctional and self.rRoom:isBreached() then
        bFunctional = false
        sNonFunctionalReason = 'INSPEC152TEXT'
    end
    
    if self:_testSafetyInterrupt(true) then
        bFunctional = false
        sNonFunctionalReason = 'INSPEC169TEXT'
    end
    
    local tProcessedDoors={}
    self.rSpaceDoor=nil -- for hints
    self.bBadDoor=false -- for hints
    if bFunctional then
        local bSpaceAccess = false
        for addr,_ in pairs(self.rRoom.tDoors) do
            local rDoor = ObjectList.getDoorAtTile(g_World.pathGrid:cellAddrToCoord(addr))
            
            if rDoor and not tProcessedDoors[rDoor] then
                if rDoor.doorState == Door.doorStates.BROKEN_OPEN then
                    bFunctional = false
                    sNonFunctionalReason = 'INSPEC154TEXT'
                    break
                end
            
                if rDoor.sName == 'Airlock' then 
                    rDoor:testAirlock() 
                    if rDoor.bValidAirlock then
                        bSpaceAccess = true
                        self.rSpaceDoor=rDoor
                    end
                else
                    bFunctional = false
                    sNonFunctionalReason = 'INSPEC155TEXT'
                    self.bBadDoor = true
                    break
                end
                tProcessedDoors[rDoor] = 1
            end
        end
        if not bSpaceAccess then
            bFunctional = false
            sNonFunctionalReason = 'INSPEC156TEXT'
        end
    end
    
    --update airlock door oxygen vis

    for rDoor,_ in pairs(self.tOwnedDoors) do
        if rDoor.bDestroyed then 
            self.tOwnedDoors[rDoor] = nil
        elseif not bFunctional or not tProcessedDoors[rDoor] then
            if rDoor.setOwnedByZone then        
                rDoor:setOwnedByZone(self,false)
            end
            self.tOwnedDoors[rDoor] = nil
        end   
    end

    self.rLocker = nil
    for rProp,_ in pairs(self.rRoom.tProps) do
        if rProp.sName == 'AirlockLocker' and rProp:isFunctioning() then
            if rProp:getAccessWorldLoc() then
                self.rLocker = rProp
            end
        end
    end
    if not self.rLocker and bFunctional then
        bFunctional = false
        sNonFunctionalReason = 'INSPEC157TEXT'
    end

    if bFunctional then
        for rDoor,_ in pairs(tProcessedDoors) do
            if not self.tOwnedDoors[rDoor] then
                self.tOwnedDoors[rDoor] = 1
                if rDoor.setOwnedByZone then
                    rDoor:setOwnedByZone(self,true)
                    if not self.bRunning then 
                        rDoor:setOperation(Door.operations.NORMAL) 
                    end
                end
            end
        end
    end

    self.bFunctional = bFunctional
    self.sNonFunctionalReason = sNonFunctionalReason
    assertdev(self.bFunctional or self.sNonFunctionalReason)
    
 --   local _,_,o2 = rRoom:getOxygenScore()
  --  self.relativeOxygen = math.abs(o2) / Oxygen.TILE_MAX
    
    self:_updateJobList()
    
end

function Airlock:getAlertString()
    if not self.bFunctional and self.sNonFunctionalReason then
        return g_LM.line(self.sNonFunctionalReason)
    end
end

function Airlock:requestOpen()
    if not self.bRunning and not self:_testSafetyInterrupt() then
        self:beginOpenSequence()
        return true
    end
end

function Airlock:canGoOutside()
    return self.nStage == Airlock.STAGE_LEAVE
end

-- Returns a tile outside the airlock, in vacuum/space
function Airlock:getExteriorTile(bAll)
    return self:_getTileOutsideAirlock(true,bAll)
end

-- Returns a tile outside of the airlock zone, in the base.
function Airlock:getInteriorTile(bAll)
    return self:_getTileOutsideAirlock(false,bAll)
end

function Airlock:_getTileOutsideAirlock(bInSpace)
    for addr,_ in pairs(self.rRoom.tDoors) do
        local rDoor = ObjectList.getDoorAtTile(g_World.pathGrid:cellAddrToCoord(addr))
        if rDoor and (rDoor.bValidAirlock == bInSpace) then
            local wx,wy,tx,ty

            if bInSpace then
                wx,wy,tx,ty = rDoor:getValidTileOnSide(false)
            else
			    local tTests = {rDoor.tEastSideTiles[1],rDoor.tWestSideTiles[1]}
			    for i=1,2 do
				    tx,ty = g_World.pathGrid:cellAddrToCoord(tTests[i])
				    local rRoom = Room.getRoomAtTile(tx,ty,rDoor.nLevel)
				    if rRoom and rRoom ~= self.rRoom then
					    wx,wy = g_World._getWorldFromTile(tx,ty)
				    end
			    end
            end

            return wx,wy,tx,ty
        end
    end
end

function Airlock:utilityOverride(rChar, rAO, nOldScore)
    local nMult = 1
    if self:_testSafetyInterrupt() then
        nMult = .9
    end
	-- reduce score if this isn't a player-owned airlock
	if self.rRoom.nTeam == Character.TEAM_ID_PLAYER then
		-- nothing
	else
		nMult = nMult * 0.75
	end
    return nOldScore * nMult
end

function Airlock:utilityGate(rChar, rAO)
    local tChars,numChars = self.rRoom:getCharactersInRoom(true)
    
    -- SPECIAL-CASE HACK for incapacitated characters in airlock.
    -- We may down the line want to track safety interrupt time and make the airlock
    -- off-limits if it's been too long, and interrupt the GoInside task to find another
    -- airlock.
    for rChar,_ in pairs(tChars) do
        if not rChar:wearingSpacesuit() and Malady.isIncapacitated(rChar) then
            return false, 'Incapacitated character blocking airlock function.'
        end
    end

	-- if not player owned, only use if we're suffocating
	if self.rRoom.nTeam == Character.TEAM_ID_PLAYER then
		return true
	elseif rChar.tStatus.suffocationTime > 0 then
		return true
	else
		return false, 'not player owned (and not suffocating)'
	end
end

function Airlock:_updateJobList()
    local tData
    local tJobs = {}

    if self.bFunctional and self.rRoom and not self.rRoom.nOwnershipDuration and not self.bBreach and self.rLocker then
        --[[
        -- Add GoInsideStandalone
        -- It's just a RunTo to somewhere inside the airlock.
        tData = {}
        local x, y = self.rLocker:getLoc()
        tData.pathX,tData.pathY = x,y
        tData.priorityOverrideFn = function(rChar,rAO,nUnmodifiedPri)
            if rChar.tStatus.bLowOxygen then
                return OptionData.tPriorities.SURVIVAL_NORMAL
            end
            return nUnmodifiedPri
        end
		tData.bInfinite = true
		-- gate based on player ownership, etc
		tData.utilityGateFn = function(rChar, rAO) 
            local bOK, sReason = self:utilityGate(rChar, rAO) 
            if not bOK then 
                return bOK,sReason 
            end
            
        end
		tData.utilityOverrideFn = function(rChar, rAO, nScore) return self:utilityOverride(rChar, rAO, nScore) end
                
        table.insert(tJobs, g_ActivityOption.new('GoInsideStandalone',tData))
        ]]--
        
        -- now GoOutsideStandalone
        -- It's just a rare fallback case for people in an airlock with nothing else to do, so that they don't
        -- sit around blocking the door.
        tData = {}
		tData.bInfinite = true
        local tx,ty = self:_getTileOutsideAirlock(true)
        if tx then
            tData.pathX,tData.pathY = g_World._getWorldFromTile(tx,ty)
            -- gate based on player ownership, etc
            tData.utilityGateFn = function(rChar, rAO) 
                if rChar:getRoom() ~= self.rRoom then
                    return false, 'not inhabiting airlock'
                end
                return self:utilityGate(rChar, rAO) 
            end
            table.insert(tJobs, g_ActivityOption.new('GoOutsideStandalone',tData))
        end
    end

    self.activityOptionList:set(tJobs)
end

function Airlock:_testPathToJob(sType)
    local spaceTiles = CommandObject.getBuildTiles(false,sType)
    local oldestUpdate = GameRules.elapsedTime
    local oldestTileAddr = nil
    local oldestTileData = nil
    
    for addr,data in pairs(spaceTiles) do
        local cachedData = self.tBuildOrders[data.addr]
        if not cachedData then
            oldestTileAddr = data.addr
            oldestTileData = data
            break
        elseif cachedData.updateTime < oldestUpdate then
            oldestUpdate = cachedData.updateTime
            oldestTileAddr = data.addr
            oldestTileData = data
        end
    end

    if oldestTileData then
        local cache = self.tBuildOrders[oldestTileAddr]
        if not cache then
            cache = {}
            self.tBuildOrders[oldestTileAddr] = cache
        end
        cache.updateTime = GameRules.elapsedTime
        cache.tPath = nil
        cache.addr = oldestTileAddr

        local x1,y1 = oldestTileData.x,oldestTileData.y
        for addr,_ in pairs(self.rRoom.tDoors) do
            local rDoor = ObjectList.getDoorAtTile(g_World.pathGrid:cellAddrToCoord(addr))
            if rDoor and rDoor.bValidAirlock then
                local x0,y0 = rDoor:getValidTileOnSide(false)
                local tPath = Pathfinder.getPath(x0, y0, x1, y1, nil, {bForceSpacewalking=true})
                if tPath then
                    cache.tPath = tPath
                    cache.doorAddr = addr
                    break
                end
            end
        end
    end
end

function Airlock:_attemptChangeDoors(dt,operation,state,bSpaceOnly)
    local bSuccess = true
    for addr,_ in pairs(self.rRoom.tDoors) do
        local rDoor = ObjectList.getDoorAtTile(g_World.pathGrid:cellAddrToCoord(addr))
        
        if not rDoor or (bSpaceOnly and not rDoor.bValidAirlock) then
            --print('skipping door because not an airlock')
        else
            rDoor:setOperation(operation)
            rDoor:_updateDoorState(false, true)
            
            rDoor.monitorState = self.doorMonitorState
            
            if rDoor.doorState ~= state then
                -- HACK: checking for very similar states
                if state == Door.doorStates.LOCKED and rDoor.doorState == Door.doorStates.BROKEN_CLOSED then
                else
                    bSuccess = false
                end
            end
        end
    end
    return bSuccess
end

function Airlock:_tickVenting(dt,bIncreasing)
    if not self.nStartingOxygen then
        --[[
        local o2 = 0
        local n = 0
        for addr,_ in pairs(self.rRoom.tTiles) do
            n=n+1
            local x, y = g_World.pathGrid:cellAddrToCoord(addr)
            o2 = o2 + g_World.oxygenGrid:getOxygen(x,y)
        end        
        self.nStartingOxygen = o2/n
        ]]--
        self.bOxygenScoreOutOfDate = true -- forcing a recalc, since airlocks can change faster than o2 tick rate.
        self.nStartingOxygen = self.rRoom:getOxygenScore()
        if not bIncreasing then 
            self.nInitialOxygen = self.nStartingOxygen 
        end
    else
        for addr,_ in pairs(self.rRoom.tTiles) do
            local x, y = g_World.pathGrid:cellAddrToCoord(addr)
            g_World.oxygenGrid:setOxygen(x,y,self.nStartingOxygen)
        end
        
        if bIncreasing and not self.nDesiredOxygen then 
            self.nDesiredOxygen = Oxygen.TILE_MAX
            if self.rRoom.tAdjoining then
                self.nDesiredOxygen = 0
                for rAdjoiningRoom,nAdjoining in pairs(self.rRoom.tAdjoining) do
                    self.nDesiredOxygen = self.nDesiredOxygen + rAdjoiningRoom:getOxygenScore()
                end
                self.nDesiredOxygen = self.nDesiredOxygen / math.max(#self.rRoom.tAdjoining, 1)
                if self.nInitialOxygen then
                    self.nDesiredOxygen = self.nDesiredOxygen + self.nInitialOxygen
                    self.nInitialOxygen = nil
                end
                self.nDesiredOxygen = math.min(self.nDesiredOxygen, Oxygen.TILE_MAX)
            end
        end
        if (not bIncreasing and self.nStartingOxygen <= 0) or (bIncreasing and self.nStartingOxygen >= self.nDesiredOxygen) then
            return true
        else
            if bIncreasing then
                self.nStartingOxygen = math.min(Oxygen.TILE_MAX,self.nStartingOxygen + Oxygen.TILE_MAX * Airlock.OXYGEN_INCREASE_RATE * dt)
            else
                self.nStartingOxygen = math.max(0, self.nStartingOxygen - Oxygen.TILE_MAX * Airlock.OXYGEN_INCREASE_RATE * dt)
            end
        end
    end
end

function Airlock:_updateDoorMonitor()
    if not true then -- self.rRoom:disallowO2Propagation()
        self.doorMonitorState = AirlockDoor.monitorStates.LOCKED
    else    
        local relativeOxygen = (self:_getRelativeOxygen() or 0)
        if relativeOxygen > 0.8 then
            self.doorMonitorState = AirlockDoor.monitorStates.OXYFULL
        elseif relativeOxygen >= 0.55 then
            self.doorMonitorState = AirlockDoor.monitorStates.OXYMED
        elseif relativeOxygen >= 0.35 then
            self.doorMonitorState = AirlockDoor.monitorStates.OXYLOW
        else
            self.doorMonitorState = AirlockDoor.monitorStates.OXYNONE
        end    
    end
    
    for rDoor,_ in pairs(self.tOwnedDoors) do
        --if rDoor:locked() then
        --    rDoor.monitorState = AirlockDoor.monitorStates.LOCKED
        --else
            rDoor.monitorState = self.doorMonitorState
        --end
    end
end

function Airlock:_getRelativeOxygen()
    local _,_,o2 = self.rRoom:getOxygenScore()
    return math.abs(o2) / Oxygen.TILE_MAX
end

function Airlock:_waitForDudesToLeave(dt)
    self.nTimeWaited = (self.nTimeWaited or 0)+dt
    if self.nTimeWaited > Airlock.MAX_OPEN_WAIT_TIME then
        return true
    end
    --[[
    -- UNSAFE: this function is actually used for both entering and leaving the airlock.
    local tChars,numChars = self.rRoom:getCharactersInRoom(true)
    if numChars == 0 then
        return true
    end
    ]]--
end

--[[
function Airlock.interceptNextStep(currentTX,currentTY,nextTX,nextTY)
    --local tNode = self.tPathNodes[self.tCurrentStepData.nCurrentStep]
    --local tNextNode = self.tPathNodes[self.tCurrentStepData.nNextStep]
    --local rDoor = ObjectList.getDoorAtTile(tNextNode.tx,tNextNode.ty)
    local rDoor = ObjectList.getDoorAtTile(nextTX,nextTY)
    if rDoor and rDoor.bValidAirlock and rDoor:functioningAsOuterAirlockDoor() then
    end
end
]]--

--function Airlock.interceptStep(rChar, destTX,destTY)
function Airlock.interceptSegment(rChar, destTX,destTY, nCurRoom,nNextRoom, bPathToNearest)
    -- sort of hacky: bPathToNearest means we're just going next to the final position.
    -- And since we're only checking the final position in this function, to see if it's on
    -- an airlock door, then bPathToNearest means we're not going into the door.
    if bPathToNearest then return end

    local rDoor = ObjectList.getDoorAtTile(destTX,destTY)
    if rDoor and rDoor.bValidAirlock and rDoor:functioningAsOuterAirlockDoor() then

        if rChar.rCurrentTask then
            local rLeaf = rChar.rCurrentTask:getLeafTask()
            if rLeaf and rLeaf.rActivityOption and rLeaf.rActivityOption.tData and rLeaf.rActivityOption.tData.bAirlockActionNode then
                return nil
            end
        end

        local bGoInside=nil
        if nCurRoom == 1 then
            bGoInside=true
        elseif nNextRoom == 1 then
            bGoInside=false
        else
            local wx,wy,tx,ty = rDoor:getValidTileOnSide(true)
            local rRoom = Room.getRoomAtTile(tx,ty,rDoor.nLevel)
            if rRoom then
                if rRoom.id == nCurRoom then
                    bGoInside=false
                elseif rRoom.id == nNextRoom then
                    bGoInside=true
                end
            end
            if bGoInside==nil then
                wx,wy,tx,ty = rDoor:getValidTileOnSide(false)
                rRoom = Room.getRoomAtTile(tx,ty,rDoor.nLevel)
                if rRoom then
                    if rRoom.id == nCurRoom then
                        bGoInside=true
                    elseif rRoom.id == nNextRoom then
                        bGoInside=false
                    end
                end
            end
        end
        if bGoInside == nil then
            Print(TT_Error,"Unable to determine if we're going inside or outside.")
            print(destTX,destTY,nCurRoom,nNextRoom)
        end
        
        return Airlock.createActionNode(rChar, bGoInside, rDoor,destTX,destTY)
    end
end

function Airlock.createActionNode(rChar, bGoInside, rDoor, doorTX,doorTY)
    local rAirlockZone = rDoor:_getFunctionalAirlockZone()
    local rRoom = rAirlockZone and rAirlockZone.rRoom
    if not rRoom then
        Print(TT_Warning,"Airlock attempting to create a path through an invalid airlock.",rAirlockZone,rRoom)
        return
    end
    if rRoom.zoneObj ~= rAirlockZone then
        Print(TT_Error,"How does that even happen?",rAirlockZone,rRoom,rRoom.zoneObj)
        return
    end

    local insideTX,insideTY = g_World._getAdjacentTile(doorTX,doorTY, rDoor.airlockInsideDir)
    local outsideTX,outsideTY = g_World._getAdjacentTile(doorTX,doorTY, rDoor.airlockSpaceDir)
    --local rRoom = Room.getRoomAtTile(insideTX,insideTY)

    local afterWX,afterWY,beforeWX,beforeWY
    if bGoInside then
        afterWX,afterWY = g_World._getWorldFromTile(insideTX,insideTY)
        beforeWX,beforeWY = g_World._getWorldFromTile(outsideTX,outsideTY)
    else
        afterWX,afterWY = g_World._getWorldFromTile(outsideTX,outsideTY)
        beforeWX,beforeWY = g_World._getWorldFromTile(insideTX,insideTY)
    end

    -- Create the special path node for Pathfinder to use.
    local tTaskNode={
        sTaskName=(bGoInside and 'Utility.Tasks.GoInside') or 'Utility.Tasks.GoOutside',
    }

    local tTaskData = {
        pathToNearest=false,
        rAirlockZone=rRoom.zoneObj,
        rLocker = rRoom.zoneObj.rLocker,
        -- A bunch of flags to keep this from getting shut down by the pathing system.
        -- We should perhaps just simplify to something like a bForcePath flag?
        bAllowHostilePathing = true,
        bTestMemoryBreach=false,
        bTestMemoryCombat=false,
    }
    local dropOffX,dropOffY = g_World._getWorldFromTile(doorTX,doorTY)
    if not bGoInside then
        tTaskData.dropOffX=dropOffX
        tTaskData.dropOffY=dropOffY
    end
    if bGoInside then
        tTaskData.pathX=beforeWX
        tTaskData.pathY=beforeWY
    else
        tTaskData.pathX,tTaskData.pathY = rRoom.zoneObj.rLocker:getAccessWorldLoc()
    end
    tTaskData.bAirlockActionNode = true

    
    tTaskNode.tTaskData = tTaskData
    tTaskNode.sNodeType='task'
    tTaskNode.tx,tTaskNode.ty = g_World._getTileFromWorld(beforeWX,beforeWY)

    return tTaskNode
end

return Airlock
