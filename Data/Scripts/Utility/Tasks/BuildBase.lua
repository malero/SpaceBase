local Task=require('Utility.Task')
local Fire=require('Fire')
local Class=require('Class')
local ObjectList=require('ObjectList')
local Pathfinder=require('Pathfinder')
local CommandObject=require('Utility.CommandObject')
local GridUtil=require('GridUtil')
local MiscUtil=require('MiscUtil')
local GameRules=require('GameRules')
local DFUtil=require('DFCommon.Util')
local Base=require('Base')
local Room=require('Room')
local Character=require('CharacterConstants')

local BuildBase = Class.create(Task)

--BuildBase.emoticon = 'work'
BuildBase.MAX_TILES_TO_BUILD = 20
BuildBase.HELMET_REQUIRED = true
BuildBase.MIN_BUILD_TILE_DURATION = 2
BuildBase.MAX_BUILD_TILE_DURATION = 5

function BuildBase:init(rChar,tPromisedNeeds,rActivityOption)
    Task.init(self,rChar,tPromisedNeeds,rActivityOption)
    -- artificial duration guess. Should be path time + build time, where
    -- build time is for multiple tiles in an area.
    self.duration = 3 + self:getDuration(BuildBase.MIN_BUILD_TILE_DURATION, BuildBase.MAX_BUILD_TILE_DURATION, Character.BUILDER)
    self.bInside = rActivityOption.tData.bInside
	self.nTilesBuilt = 0
    self.tPathParams = DFUtil.deepCopy(rActivityOption.tBlackboard.tPathParams)
    self.targetTile={tx=rActivityOption.tBlackboard.tileX,ty=rActivityOption.tBlackboard.tileY}
    assert(rActivityOption.tBlackboard.rChar == rChar)
    local bSuccess = self:_createPathToBuildLoc(self.targetTile.tx,self.targetTile.ty)
	if not bSuccess then
        Print(TT_Warning, 'Character just started build, but cannot find a path to the build location.')
        self:setWait(4)
        self.bStartedWait=true
    end
    --self:setPath(rActivityOption.tBlackboard.tPath)
end

function BuildBase:_getAdjacentFreeTile(tx,ty)
    local testFn=function(adjX,adjY)
        return g_World._isPathable(adjX,adjY) and not ObjectList.getObjAtTile(adjX,adjY,ObjectList.CHARACTER)
    end
    local newTX,newTY = g_World.isAdjacentToFn(tx, ty, testFn, true, false)
    return newTX,newTY
end

function BuildBase:_createBuildPath(wxDest,wyDest, bNearest)
    self.tPathParams.bPathToNearest = bNearest
    local wx,wy = self.rChar:getLoc()
    
    local tPath = Pathfinder.getPath(wx, wy, wxDest,wyDest, self.rChar, self.tPathParams)
    if tPath then
        self:setPath(tPath)
        return true
    end
end

function BuildBase:_createPathAway()
    local wx,wy = self.rChar:getLoc()
    local tx, ty = g_World._getTileFromWorld(wx,wy)
    local newTX,newTY = self:_getAdjacentFreeTile(tx,ty)
    if not newTX then
        return false
    end
    local newX,newY = g_World._getWorldFromTile(newTX,newTY)
    self:_createBuildPath(newX,newY)
    return true
end

-- will our command cause a breach?
function BuildBase:_pendingBreachCommand()
    if not self.targetTile then return false end
    local tx, ty = self.targetTile.tx,self.targetTile.ty
    local cmd,coord = CommandObject.getCommandAtTile(tx,ty)
    if not coord then return false end
    
    if coord.buildTileType == CommandObject.BUILD_PARAM_VAPORIZE then return true end
   
    if coord.buildTileType == CommandObject.BUILD_PARAM_DEMOLISH and g_World.countsAsWall(g_World._getTileValue(tx,ty)) then
        return g_World.isAdjacentToSpace(tx, ty, true, false)
    end
    return false
end

-- find a good place to stand.
function BuildBase:_findBuildSpot(tx,ty)
    local cmd,coord = CommandObject.getCommandAtTile(tx,ty)

    -- are we building/destroying a wall?
    local bWall = coord.buildTileType == g_World.logicalTiles.WALL
    if (coord.buildTileType == CommandObject.BUILD_PARAM_VAPORIZE or coord.buildTileType == CommandObject.BUILD_PARAM_DEMOLISH) 
            and g_World.countsAsWall(g_World._getTileValue(tx,ty)) then
        bWall = true
    end
    
	local cwx,cwy = self.rChar:getLoc()
    local ctx, cty = g_World._getTileFromWorld(cwx,cwy)
    local wx,wy = g_World._getWorldFromTile(tx,ty)
	if bWall then
		local bestX,bestY
		for i=2,9 do
			local atx,aty = g_World._getAdjacentTile(tx, ty, i)
            local tileValue = g_World._getTileValue(atx,aty)

			if tileValue == g_World.logicalTiles.SPACE then
				if not CommandObject.getCommandAtTile(atx,aty) then
			        local standWX,standWY = g_World._getWorldFromTile(atx,aty)
                    -- first we'll try to path here.
			        if self:_createBuildPath(standWX,standWY) then
                        return true
                    else
                        break
                    end
                end
            end
		end
        -- fallback: just get there. but get out of the way if we're on that tile.
        if g_World.isAdjacentToTile(tx,ty,ctx,cty, true, false) then
            return true
        end
        if tx == ctx and ty == cty then
            if self:_createPathAway(ctx,cty) then
                return true
            else
                return false
            end
        end
        if self:_createBuildPath(wx,wy,true) then
            return true
        end
        return false
	end

    -- build or vaporize floor.
    
	if g_World.isAdjacentToTile(tx,ty, ctx,cty, true, true) then
        return true
	end

    if self:_createBuildPath(wx,wy,true) then
        return true
    end
    return false
end

-- return: bSuccess
function BuildBase:_createPathToBuildLoc(tx,ty)
	local cwx,cwy = self.rChar:getLoc()
   	local ctx, cty = g_World._getTileFromWorld(cwx,cwy)
	-- find a good place to stand to build this tile.
	return self:_findBuildSpot(tx,ty)
end

function BuildBase:_refund(cmdCoord,tx,ty)
	if cmdCoord.buildTileType == CommandObject.BUILD_PARAM_VAPORIZE or cmdCoord.buildTileType == CommandObject.BUILD_PARAM_DEMOLISH then
		local value = g_World._getTileValue(tx,ty)
        local rTileObj = ObjectList.getObjAtTile(tx, ty, ObjectList.ENVOBJECT)
        if rTileObj then
            local objCost = rTileObj:getVaporizeCost()
            GameRules.addMatter(objCost)
        end
		if g_World.countsAsWall(value) then
            if cmdCoord.buildTileType == CommandObject.BUILD_PARAM_VAPORIZE then
                -- vape does floor and wall simultaneously.
                GameRules.addMatter(GameRules.MAT_VAPE_FLOOR)
                local rObjOnWall = g_World._getEnvObjectOnWall(tx,ty)
                if rObjOnWall then
                    local objCost = rObjOnWall:getVaporizeCost()
                    GameRules.addMatter(objCost)
                end                
            end
		elseif g_World.countsAsFloor(value) then
			GameRules.addMatter(GameRules.MAT_VAPE_FLOOR)
		end
    end
end

function BuildBase:_testSafetyDelay()
    if self.duration < 0 and (not self.nTotalTimeDelayed or self.nTotalTimeDelayed < 15) and self:_pendingBreachCommand() then
        local bDelay = false
        local _,tRooms = Room.getRoomAtTile(self.targetTile.tx,self.targetTile.ty,1,true)
        if tRooms then
            for id,rRoom in pairs(tRooms) do
                if rRoom and not rRoom.bDestroyed then
                    local tChars = rRoom:getCharactersInRoom(false)
                    if tChars then
                        for rChar,_ in pairs(tChars) do
                            if rChar:getFactionBehavior() == Character.FACTION_BEHAVIOR.Citizen and not rChar:wearingSpacesuit() then
                                bDelay = true
                                break
                            end
                        end
                    end
                end
            end
        end
        if bDelay then
            self.nTotalTimeDelayed = (self.nTotalTimeDelayed or 0)
            self.nTotalTimeDelayed = self.nTotalTimeDelayed + 3
            self.duration = self.duration + 3
        end
    end
    
end

function BuildBase:_tickBuild(dt)
    self.duration = self.duration - dt
    
    self:_testSafetyDelay()
    
    if self.duration < 0 then
        local targetX,targetY=self.targetTile.tx,self.targetTile.ty
        local cmdObj,cmdCoord = CommandObject.getCommandAtTile(targetX,targetY)

        if cmdObj and cmdObj.commandAction == CommandObject.COMMAND_BUILD_TILE then
            local bWall = cmdCoord.buildTileType == g_World.logicalTiles.WALL
            local existingChar = ObjectList.getObjAtTile(targetX,targetY,ObjectList.CHARACTER)
			local tileAddr = g_World.pathGrid:getCellAddr(targetX,targetY)
			local tile = cmdObj.tTiles[tileAddr]
            if bWall and existingChar == self.rChar then
                -- This case shouldn't occur, since we path away in _tryToBuild.
                Print(TT_Warning, 'Character attempting to build on top of self.')
                local bSuccess = self:_createPathToBuildLoc(targetX,targetY)
				if not bSuccess or not self.tPath then
                    self:interrupt('Character attempting to build on top of self.')
                    return false
                end
            elseif bWall and existingChar then
                if self.bStartedWait then
                    Print(TT_Warning, 'Character attempting to build on top of another character. Timed out. Interrupting task.')
                    self:interrupt('Character attempting to build on top of another character.')
                    return false
                else
                    self:setWait(4)
                    self.bStartedWait=true
                end
            else
                local bTurbo = false
				
				if cmdCoord.buildTileType == CommandObject.BUILD_PARAM_VAPORIZE or cmdCoord.buildTileType == CommandObject.BUILD_PARAM_DEMOLISH then
                    bTurbo = Base.hasCompletedResearch('VaporizeLevel2')
                else
                    bTurbo = Base.hasCompletedResearch('BuildLevel2')
				end
                if self.rChar:getInventoryItemOfTemplate('SuperBuilder') then
                    bTurbo = true
                end
				
                --build completed
                self:_refund(cmdCoord,targetX,targetY)
                CommandObject.performCommandAtTile(cmdObj,targetX,targetY)
                self.rChar:builtBase()
                self.nTilesBuilt = self.nTilesBuilt+1
                if bTurbo then
                    for i=2,5 do
                        local atx,aty = g_World._getAdjacentTile(targetX,targetY,i)
                        local adjacentCmdObj,adjacentCmdCoord = CommandObject.getCommandAtTile(atx,aty)
                        if adjacentCmdObj then
                            local bAdjacentDestroy = (adjacentCmdCoord.buildTileType == CommandObject.BUILD_PARAM_VAPORIZE or cmdCoord.buildTileType == CommandObject.BUILD_PARAM_VAPORIZE) and true
                            local bCmdDestroy = (cmdCoord.buildTileType == CommandObject.BUILD_PARAM_VAPORIZE or cmdCoord.buildTileType == CommandObject.BUILD_PARAM_DEMOLISH) and true
                            
                            if bAdjacentDestroy == bCmdDestroy then
                                self:_refund(adjacentCmdCoord,atx,aty)
                                CommandObject.performCommandAtTile(adjacentCmdObj,atx,aty)
                                self.rChar:builtBase()
                            end
                        end
                    end
                end
        
                --respect cutaway mode when adding new tiles. JM
                if bWall then
                    local wallLayer = g_Renderer.getRenderLayer('WorldWall')
                    local propTable = g_World.tWalls[tileAddr]
                    if propTable then propTable = propTable.tProps end
                    
                    if propTable and cmdCoord.buildTileType ~= CommandObject.BUILD_PARAM_VAPORIZE and cmdCoord.buildTileType ~= CommandObject.BUILD_PARAM_DEMOLISH then 
                        if GameRules.cutawayMode then
                            wallLayer:removeProp(propTable.top)
                        else
                            wallLayer:insertProp(propTable.top)
                        end
                    end
                end
            end
        end
        self.bBuilding = false
        self.targetTile=nil
    end
    return true
end

function BuildBase:_enteredNewTile()
    Task._enteredNewTile(self)
    if not self.nAlertedBreachTime and self:_pendingBreachCommand() then
        local ctx,cty = self.rChar:getTileLoc()
        if MiscUtil.isoDist(ctx,cty,self.targetTile.tx,self.targetTile.ty) < 10 then
            self.nAlertedBreachTime = GameRules.elapsedTime
            local _,tRooms = Room.getRoomAtTile(self.targetTile.tx,self.targetTile.ty,1,true)
            if tRooms then
                self:_clearBreachAlerts()
                self.tAlertedRooms = {}
                for id,rRoom in pairs(tRooms) do
                    rRoom:setPendingBreach(self.targetTile.tx,self.targetTile.ty,true)
                    self.tAlertedRooms[id] = {x=self.targetTile.tx,y=self.targetTile.ty}
                end
            end
        end
    end
    --self:_testForNearbyConstruction()
end

function BuildBase:_clearBreachAlerts()
    if self.tAlertedRooms then
        for id,coord in pairs(self.tAlertedRooms) do
            local rRoom = Room.tRooms[id]
            if rRoom then rRoom:setPendingBreach(coord.x,coord.y,false) end
        end
        self.tAlertedRooms = nil
        self.nAlertedBreachTime = nil
        self.nTotalTimeDelayed = nil
    end
end

function BuildBase:_acquireNewTarget()
    self:_clearBreachAlerts()
    self.targetTile=nil
    local wx,wy = self.rChar:getLoc()
    local nRange=3

    local nPathingAttempts=0
    local function testFn(tx,ty,requiredType)
        if self.rActivityOption:reserved(tx,ty,self.rChar) or nPathingAttempts > 2 then return false end

        local addr = g_World.pathGrid:getCellAddr(tx,ty)
        local cmdObj = CommandObject.tCommands[addr]
        if cmdObj and cmdObj.commandAction == CommandObject.COMMAND_BUILD_TILE then
            -- MTF hack: regardless of required type, always adds a vaporize command.
            if cmdObj.tTiles[addr].buildTileType == CommandObject.BUILD_PARAM_VAPORIZE or cmdObj.tTiles[addr].buildTileType == CommandObject.BUILD_PARAM_DEMOLISH or not requiredType or (requiredType == g_World.logicalTiles.WALL and cmdObj.tTiles[addr].buildTileType == g_World.logicalTiles.WALL)
                    or (requiredType == g_World.logicalTiles.ZONE_LIST_START and cmdObj.tTiles[addr].buildTileType == g_World.logicalTiles.ZONE_LIST_START) then

                if self:_findBuildSpot(tx,ty) then
                    return true
                else
                    nPathingAttempts=nPathingAttempts+1
                end
            end
        end
    end
    local targetWorldX,targetWorldY,cmd,coord = CommandObject._findAppropriateTile(wx,wy,
        function(tx,ty) return testFn(tx,ty,g_World.logicalTiles.ZONE_LIST_START) end,
        nRange)

    if not targetWorldX then
        nPathingAttempts=0
        targetWorldX,targetWorldY,cmd,coord = CommandObject._findAppropriateTile(wx,wy,
            function(tx,ty) return testFn(tx,ty,g_World.logicalTiles.WALL) end,
            nRange)
    end

    if targetWorldX then
        local tx,ty = g_World._getTileFromWorld(targetWorldX,targetWorldY)
        self.targetTile={tx=tx,ty=ty}
        self.rActivityOption:updateTileReservation(self.rChar,tx,ty)
        return true
    end
end

function BuildBase:_startBuilding()
    if self.targetTile then
        local ctx,cty = self.rChar:getTileLoc()
        local tx,ty = self.targetTile.tx,self.targetTile.ty
        if not g_World._areTilesAdjacent(ctx,cty,tx,ty,true,true) then
            return
        end

        self.tPath=nil
        --self.rActivityOption:updateTileReservation(self.rChar,tx,ty)
        self.bBuilding = true
        self.rChar:playAnim('build')
        local wx,wy = g_World._getWorldFromTile(tx,ty)
        self.rChar:faceWorld(wx,wy)
        self.duration = self:getDuration(BuildBase.MIN_BUILD_TILE_DURATION, BuildBase.MAX_BUILD_TILE_DURATION, Character.BUILDER)
        return true
    end
end

function BuildBase:onUpdate(dt)
    if self.nTilesBuilt >= BuildBase.MAX_TILES_TO_BUILD then
        self:complete()
    elseif self:tickWait(dt) then
        -- nothing
    elseif self.tPath then
        self:tickWalk(dt)
    elseif self.bBuilding then
        if not self:_tickBuild(dt) then
            return false
        end
    elseif self:_startBuilding() then
    elseif self:_acquireNewTarget() then
        -- _acquireNewTarget will set a new self.tPath, or set self.bBuilding, if successful. if not, we fall through to interrupt, below.
    else
        if self.nTilesBuilt > 0 then 
            local fraction = math.max(.5,self.nTilesBuilt / BuildBase.MAX_TILES_TO_BUILD)
            if self.tPromisedNeeds['Duty'] then
                self.tPromisedNeeds = DFUtil.deepCopy(self.tPromisedNeeds)
                self.tPromisedNeeds['Duty'] = self.tPromisedNeeds['Duty'] * fraction
            end
            return true
        else
            self:interrupt("No pathable targets.")
        end
    end
end

function BuildBase:onComplete(bSuccess)
    self:_clearBreachAlerts()
    Task.onComplete(self,bSuccess)
end

return BuildBase
