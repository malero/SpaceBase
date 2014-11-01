local GameRules=require('GameRules')
local Oxygen=require('Oxygen')
local Character=require('CharacterConstants')
local DFGraphics=require('DFCommon.Graphics')
local ObjectList=require('ObjectList')
local Renderer=require('Renderer')
local Lighting=require('Lighting')
local Class=require('Class')
local Zone=require('Zones.Zone')
local GridUtil=require('GridUtil')
local MiscUtil=require('MiscUtil')
local DFUtil=require('DFCommon.Util')
local Asteroid=require('Asteroid')
local Inventory=require('Inventory')
local InventoryData=require('InventoryData')
local Pickup=require('Pickups.Pickup')
local Gui=require('UI.Gui')
local UtilityAI=nil
local Cursor=nil
local ActivityOption=nil
local ActivityOptionList=nil
local EnvObject=nil
local PickupData=nil
local Room=nil
local Profile = require('Profile')

local CommandObject = Class.create()

CommandObject.COMMAND_BUILD_TILE=1
CommandObject.COMMAND_VAPORIZE=2
CommandObject.COMMAND_MINE=3
CommandObject.COMMAND_BUILD_ENVOBJECT=4
CommandObject.COMMAND_CANCEL=5
CommandObject.COMMAND_BATCH=6
CommandObject.COMMAND_DEMOLISH=7
CommandObject.TILE_VALID=1
CommandObject.TILE_INVALID=2
CommandObject.TILE_INTERRUPT=3
CommandObject.orderTargetColor={1*.75,.5*.75,.5*.75,.75}
CommandObject.CommandRenderLayer='WorldWall'
CommandObject.WallCommandSprite='wall_block_temp'
CommandObject.FloorCommandSprite='Wireframe_Floor'
CommandObject.VaporizeCommandSprite='wall_block_temp'
CommandObject.MineCommandSprite='asteroid01'
CommandObject.TileCommandSpriteSheet='Environments/Tiles/Wall'
CommandObject.profilerName = 'CommandObject'

CommandObject.BUILD_PARAM_VAPORIZE = -1
CommandObject.CANCEL_PARAM_MINE = -2
CommandObject.CANCEL_PARAM_BUILD = -3
CommandObject.BUILD_PARAM_DEMOLISH = -4

CommandObject.DEBUG_PROFILE=true

-- total matter costs of new, yet-to-be-confirmed construction
CommandObject.pendingBuildCost = 0
CommandObject.pendingVaporizeCost = 0
CommandObject.pendingCancelCost = 0
CommandObject.pendingMineCost = 0

function countsAsVaporize(commandAction,commandParam,coord)
    if commandAction == CommandObject.COMMAND_VAPORIZE then return true end
    if commandAction == CommandObject.COMMAND_BUILD_TILE then
        return commandParam == CommandObject.BUILD_PARAM_VAPORIZE or (coord and coord.buildTileType == CommandObject.BUILD_PARAM_VAPORIZE)
    end
    return false
end

function countsAsDemolish(commandAction,commandParam,coord)
    if commandAction == CommandObject.COMMAND_DEMOLISH then return true end
    if commandAction == CommandObject.COMMAND_BUILD_TILE then
        return commandParam == CommandObject.BUILD_PARAM_DEMOLISH or (coord and coord.buildTileType == CommandObject.BUILD_PARAM_DEMOLISH)
    end
    return false
end

function CommandObject._canPerformAt(commandAction, commandParam, coord)
    local validity
    if countsAsVaporize(commandAction,commandParam,coord) then
        validity = CommandObject._canVaporizeTile(coord.x,coord.y)
    elseif countsAsDemolish(commandAction,commandParam,coord) then
        validity = CommandObject._canDemolishTile(coord.x,coord.y)
    elseif commandAction == CommandObject.COMMAND_CANCEL then
        local addr = g_World.pathGrid:getCellAddr(coord.x,coord.y)
        local rCommand = CommandObject.tCommands[addr]
        if rCommand then            
            if commandParam == CommandObject.CANCEL_PARAM_MINE then
                if rCommand.commandAction == CommandObject.COMMAND_MINE then
                    validity = CommandObject.TILE_VALID
                else
                    validity = CommandObject.TILE_INVALID
                end
            else
                if rCommand.commandAction ~= CommandObject.COMMAND_MINE then
                    validity = CommandObject.TILE_VALID
                else
                    validity = CommandObject.TILE_INVALID                    
                end
            end
        else
            if commandParam == CommandObject.CANCEL_PARAM_BUILD and Room.getGhostAtTile(coord.x,coord.y) then
                validity = CommandObject.TILE_VALID
            else
                validity = CommandObject.TILE_INVALID
            end
        end
    elseif commandAction == CommandObject.COMMAND_MINE then
        validity = CommandObject._testMine(coord.x,coord.y)
    elseif commandAction == CommandObject.COMMAND_BUILD_TILE then
            if not coord.buildTileType then
                coord.buildTileType = commandParam
            end
            if GameRules.inEditMode then 
                validity = CommandObject.TILE_VALID             
            elseif coord.buildTileType == g_World.logicalTiles.WALL then
                if g_World.canBuildWall(coord.x,coord.y,g_World.logicalTiles.WALL) then 
                    validity = CommandObject.TILE_VALID 
                else
                    validity = CommandObject.TILE_INVALID
                end
            else
                validity = CommandObject._testBuildFloor(coord.x,coord.y)
            end
    elseif commandAction == CommandObject.COMMAND_BUILD_ENVOBJECT then
        if GameRules.inEditMode then 
            validity = CommandObject.TILE_VALID
        else
            local bFound = g_World._findPropFit(coord.x, coord.y, commandParam, coord.bFlipX, coord.bFlipY,false,true)
            validity = (bFound and CommandObject.TILE_VALID) or CommandObject.TILE_INVALID
        end
    end

    return validity
end

function CommandObject:init(commandAction,commandParam)
    self.bTemp=true
    self.bValid=true
    self.commandAction=commandAction
    self.commandParam=commandParam
    self.tTiles={}
    self.tInvalidTiles={}
    self.tAffectedTiles={}
end

function CommandObject:getSaveData()
    local param = self.commandParam
    if ObjectList.isTag(param) then param = ObjectList.getTagSaveData(param) end
    local tData = {commandAction=self.commandAction,commandParam=param}
    -- strip out spriteProp, etc.
    tData.tTiles = MiscUtil.deepCopyData(self.tTiles)
    tData.tInvalidTiles = MiscUtil.deepCopyData(self.tInvalidTiles)
    tData.tAffectedTiles = MiscUtil.deepCopyData(self.tAffectedTiles)
    return tData
end

function CommandObject:getMatterCost(sHackParam)
    if self.commandAction == CommandObject.COMMAND_BATCH then
        local cost,items=0,{}
        for _,cmd in ipairs(self.commandParam) do
            local subcost,subitems = cmd:getMatterCost()
            cost=cost+subcost
            if subitems and next(subitems) then items=subitems end
        end
        return cost,items
    end

	local cost = 0
	local tTiles = (self.bValid and self.tTiles) or (not self.bValid and self.tInvalidTiles)
	local tItems = {}
    local tObjectsToBeVaporizedCost = {}
	tItems.door, tItems.mine, tItems.wall, tItems.floor = 0,0,0,0
	tItems.cancelDoor, tItems.cancelFloor, tItems.cancelWall = 0,0,0
	tItems.vapeFloor, tItems.vapeWall = 0,0
	for addr,coord in pairs(tTiles) do
        if self.commandAction == CommandObject.COMMAND_BUILD_ENVOBJECT then
			tItems.door = tItems.door + 1
			-- get envobject type, charge for doors
			if not coord.objectType then
			elseif coord.objectType == 'Door' then
				cost = cost + GameRules.MAT_BUILD_DOOR
			elseif coord.objectType == 'Airlock' then
				cost = cost + GameRules.MAT_BUILD_AIRLOCK_DOOR
			elseif coord.objectType == 'HeavyDoor' then
				cost = cost + GameRules.MAT_BUILD_HEAVY_DOOR
			end
		elseif self.commandAction == CommandObject.COMMAND_MINE then
			tItems.mine = tItems.mine + 1
			-- JPL TODO: get # of rocks present in this tile instead of assuming max
			local Mine=require('Utility.Tasks.Mine')
			local nRocks = Inventory.getMaxStacks(InventoryData.MINE_PICKUP_NAME)
			cost = cost + GameRules.MAT_MINE_ROCK_MIN * nRocks
		elseif self.commandAction == CommandObject.COMMAND_CANCEL then
			-- get value of thing being cancelled
			local tileAddr = g_World.pathGrid:getCellAddr(coord.x, coord.y)
			local buildCoord = CommandObject.tBuildCmd.tTiles[tileAddr]
			if buildCoord then
				if buildCoord.buildTileType == g_World.logicalTiles.WALL then
                    local currentTile = g_World._getTileValue(buildCoord.x, buildCoord.y)
                    if not g_World.countsAsFloor(currentTile) then
                        cost = cost - GameRules.MAT_BUILD_FLOOR
                    end
					tItems.cancelWall = tItems.cancelWall + 1
				elseif buildCoord.buildTileType == g_World.logicalTiles.ZONE_LIST_START then
					tItems.cancelFloor = tItems.cancelFloor + 1
					cost = cost - GameRules.MAT_BUILD_FLOOR				                    
				end
			end
        elseif countsAsVaporize(self.commandAction,coord.buildTileType) then
            if sHackParam ~= 'novaporize' then
                local rObj = ObjectList.getObjAtTile(coord.x,coord.y,ObjectList.ENVOBJECT)
                if rObj and not tObjectsToBeVaporizedCost[rObj] then
                    tObjectsToBeVaporizedCost[rObj] = rObj:getVaporizeCost()
                end
		        local tileValue = g_World._getTileValue(coord.x, coord.y)
                local bFloor = g_World.countsAsFloor(tileValue) or g_World.isDoor(tileValue)
                local bWall = g_World.countsAsWall(tileValue)
		        if bFloor or bWall then
                    -- walls count for wall AND floor, since both will be vaped.
			        tItems.vapeFloor = tItems.vapeFloor + 1
			        cost = cost - GameRules.MAT_VAPE_FLOOR
                    if bWall then
                        local rObjOnWall = g_World._getEnvObjectOnWall(coord.x, coord.y)
                        if rObjOnWall then
                            tObjectsToBeVaporizedCost[rObjOnWall] = rObjOnWall:getVaporizeCost()                            
                        end
                    end
                end
		        if bWall then
			        tItems.vapeWall = tItems.vapeWall + 1
		        end
            end
		elseif countsAsDemolish(self.commandAction,coord.buildTileType) then
            local rObj = ObjectList.getObjAtTile(coord.x,coord.y,ObjectList.ENVOBJECT)
            if rObj and not tObjectsToBeVaporizedCost[rObj] then
                tObjectsToBeVaporizedCost[rObj] = rObj:getVaporizeCost()
            end
		elseif self.commandAction == CommandObject.COMMAND_BUILD_TILE and 
                (coord.buildTileType == CommandObject.BUILD_PARAM_VAPORIZE or coord.buildTileType == CommandObject.BUILD_PARAM_DEMOLISH) then
            if sHackParam ~= 'novaporize' then
                local rObj = ObjectList.getObjAtTile(coord.x,coord.y,ObjectList.ENVOBJECT)
                if rObj and not tObjectsToBeVaporizedCost[rObj] then
                    tObjectsToBeVaporizedCost[rObj] = rObj:getVaporizeCost()
                end
            end
		elseif self.commandAction == CommandObject.COMMAND_BUILD_TILE then
            if sHackParam ~= 'vaporizeonly' then
                local currentTile = g_World._getTileValue(coord.x, coord.y)
			    if coord.buildTileType == g_World.logicalTiles.WALL then
                    if currentTile == g_World.logicalTiles.WALL then
                    elseif g_World.countsAsFloor(currentTile) then
                        tItems.wall = tItems.wall + 1
                    else
                        cost = cost + GameRules.MAT_BUILD_FLOOR
                        tItems.wall = tItems.wall + 1
                    end
			    elseif coord.buildTileType == g_World.logicalTiles.ZONE_LIST_START then
				    tItems.floor = tItems.floor + 1
				    cost = cost + GameRules.MAT_BUILD_FLOOR
			    end
            end
		end
	end
    for rObj, nCost in pairs(tObjectsToBeVaporizedCost) do
        cost = cost - nCost
    end
	return cost, tItems
end

function CommandObject.getDemolishObjectCommand(obj)
    if not obj then return end
    local objTX,objTY = g_World._getTileFromWorld(obj:getLoc())
    local objAddr = g_World.pathGrid:getCellAddr(objTX,objTY)
    local objectDemolishCmd = CommandObject.new(CommandObject.COMMAND_DEMOLISH, obj.tag)
    local tPropTiles = obj:getFootprint()

    local bHasChildren=false
    for _,footprintAddr in ipairs(tPropTiles) do
        local footprintTX,footprintTY = g_World.pathGrid:cellAddrToCoord(footprintAddr)
        objectDemolishCmd.tTiles[footprintAddr] = {x=footprintTX,y=footprintTY,addr=footprintAddr,objAddr=objAddr}
        if footprintAddr ~= objAddr then
            objectDemolishCmd.tTiles[footprintAddr].sourceCmdAddr = objAddr
            bHasChildren=true
        end
    end
    objectDemolishCmd.tTiles[objAddr].bHasChildren=bHasChildren
    return objectDemolishCmd
end

function CommandObject._getDemolishCommandsFromDragOperation(commandAction, tTiles, commandParam)
    local tCmds = {}
    local tCmdsByAddr = {}

    local rDemolishBaseCmd = CommandObject.new(CommandObject.COMMAND_BUILD_TILE, CommandObject.BUILD_PARAM_DEMOLISH)
    local bInsertedVaporize=false

    for addr,coord in pairs(tTiles) do
        local tileValue = g_World._getTileValue(coord.x, coord.y)
        if CommandObject._canPerformAt(commandAction, commandParam, coord) ~= CommandObject.TILE_VALID then
            -- nothing
        elseif g_World.countsAsWall(tileValue) then
            if not bInsertedVaporize then
                table.insert(tCmds,rDemolishBaseCmd)
                bInsertedVaporize=true
            end
            tCmdsByAddr[addr] = rDemolishBaseCmd
            rDemolishBaseCmd.tTiles[addr] = {x=coord.x,y=coord.y,buildTileType=CommandObject.BUILD_PARAM_DEMOLISH}
        else
            local tag = ObjectList.getTagAtTile(coord.x,coord.y,ObjectList.ENVOBJECT)
            if tag and ObjectList.tObjList[tag.objID] then
                local obj = ObjectList.tObjList[tag.objID].obj
                local objTX,objTY = g_World._getTileFromWorld(obj:getLoc())
                local objAddr = g_World.pathGrid:getCellAddr(objTX,objTY)
                if not tCmdsByAddr[objAddr] then
                    local objectDemolishCmd = CommandObject.getDemolishObjectCommand(obj)
                    for objAddr,_ in pairs(objectDemolishCmd.tTiles) do
                        tCmdsByAddr[objAddr] = objectDemolishCmd
                    end
                    table.insert(tCmds,objectDemolishCmd)
                end
            end
        end
    end

    return tCmds
end

function CommandObject.demolishObject(tx, ty)
    assertdev(tx and ty)
    if tx and ty then
        local obj = ObjectList.getObjAtTile(tx,ty,ObjectList.ENVOBJECT)
        local command = CommandObject.getDemolishObjectCommand(obj)
        if command then
            CommandObject.saveCommandStates()
            CommandObject.addCommand(command)
            CommandObject.clearSavedCommandStates() -- confirm right away
        end
    end    
end

function CommandObject.undoDemolishObject(tx, ty)
    if tx and ty then
        CommandObject.saveCommandStates()            
        local cmdObj = CommandObject.getCommandAtTile(tx,ty)
        if cmdObj and cmdObj.commandAction == CommandObject.COMMAND_DEMOLISH then
            cmdObj:remove()
        end
    end
end

function CommandObject.getCommandFromDragOperation(commandAction, tTiles, commandParam, cursorMode, bDrag)
    Profile.enterScope("Command.fromDragOp")
    local tCmds = {}

    if commandAction == CommandObject.COMMAND_DEMOLISH then
        --if bDrag then
            tCmds = CommandObject._getDemolishCommandsFromDragOperation(commandAction, tTiles)
        --elseif commandParam then
            --local command = CommandObject.getDemolishObjectCommand(commandParam)
            --if command then table.insert(tCmds,command) end
        --end
    else
        if commandAction == CommandObject.COMMAND_VAPORIZE then
            commandAction = CommandObject.COMMAND_BUILD_TILE
            commandParam = CommandObject.BUILD_PARAM_VAPORIZE
        end
        local tempCommand = CommandObject.new(commandAction,commandParam)
        local tAffectedTiles = {}
        local tValid = {}

        for addr,coord in pairs(tTiles) do
            local validity = CommandObject._canPerformAt(commandAction, commandParam, coord)
            if validity == CommandObject.TILE_INTERRUPT then
                tempCommand.bValid = false
                --tempCommand.tInvalidTiles = tTiles
                break
                --return tempCommand
            else
                if validity == CommandObject.TILE_VALID then
                    if commandAction == CommandObject.COMMAND_MINE then
                        tValid[addr] = coord
                    elseif commandAction == CommandObject.COMMAND_CANCEL then
                        tValid[addr] = coord
                    elseif commandAction == CommandObject.COMMAND_BUILD_TILE then
                        if cursorMode == GameRules.MODE_BUILD_WALL then
                            coord.buildTileType = g_World.logicalTiles.WALL
                        elseif cursorMode == GameRules.MODE_BUILD_FLOOR then
                            coord.buildTileType = g_World.logicalTiles.ZONE_LIST_START
                        elseif commandParam == CommandObject.BUILD_PARAM_VAPORIZE then
                            coord.buildTileType = CommandObject.BUILD_PARAM_VAPORIZE
                        elseif cursorMode == GameRules.MODE_BUILD_ROOM then
                            coord.buildTileType = g_World.logicalTiles.ZONE_LIST_START
                            if coord.edge then
                                -- edge of the drag. if it touches space (without pending construction), then it's a wall.
                                -- if it does not, and it touches a wall or planned wall, then it's floor.
                                -- if it touches a door, it's always floor. that's a rhyming mnemonic device i made up for you.
                                local bTouchesSpace=false
                                local bTouchesWall=false
                                local bTouchesDoor=false
                                for i=2,9 do
                                    local testTX,testTY = g_World._getAdjacentTile(coord.x,coord.y,i)
                                    local tv = g_World._getTileValue(testTX,testTY)
                                    local _,pendingObj,pendingCoord = CommandObject.getConstructionAtTile(testTX,testTY)
                                    local bSpace = tv == g_World.logicalTiles.SPACE and not pendingObj and not tTiles[g_World.pathGrid:getCellAddr(testTX,testTY)]
                                    if bSpace then bTouchesSpace = true end
                                    if i < 6 then
                                        local bWall = g_World.countsAsWall(tv) or (pendingCoord and pendingCoord.buildTileType == g_World.logicalTiles.WALL)
                                        local bDoor = tv == g_World.logicalTiles.DOOR or (pendingCoord and pendingCoord.buildTileType == g_World.logicalTiles.DOOR)

                                        if bWall then bTouchesWall = true end
                                        if bDoor then bTouchesDoor = true end
                                    end
                                end
                                if not bTouchesDoor and (bTouchesSpace or not bTouchesWall) then
                                    coord.buildTileType = g_World.logicalTiles.WALL
                                end
                            end
                            if coord.buildTileType == g_World.logicalTiles.ZONE_LIST_START then
                                -- special case: in build room mode, don't turn existing wall commands into floor commands.
                                local cmdObj = CommandObject.getCommandAtTile(coord.x,coord.y,true)
                                if cmdObj and cmdObj.tTiles[addr].buildTileType == g_World.logicalTiles.WALL then
                                    coord.buildTileType = g_World.logicalTiles.WALL
                                end
                            end
                        end
                        tValid[addr] = coord
                    elseif commandAction == CommandObject.COMMAND_BUILD_ENVOBJECT then
                        --[[
                        --MTF: tAffectedTiles not currently used.
                        --Reinstate if we enable re-testing a command when its tAffectedTiles are modified.
                        local tPropTiles = g_World._getPropFootprint(coord.x,coord.y, commandParam, true, coord.bFlipX)
                        for i,tile in ipairs(tPropTiles) do 
                            tAffectedTiles[tile] = 1
                        end
                        ]]--
        
                        if coord.sourceCmdAddr then
                            -- these get handled by the source command.
                        else
                            local bFound,txPlaced,tyPlaced,bFlipX,bFlipY,tPropTiles = g_World._findPropFit(coord.x,coord.y, commandParam, coord.bFlipX, coord.bFlipY, true, true)
                            if bFound and txPlaced == coord.x and tyPlaced == coord.y then
                                for footprintAddr,footprintTileData in pairs(tPropTiles) do
                                    local tx,ty = footprintTileData.x,footprintTileData.y
                                    if tx ~= coord.x or ty ~= coord.y then
                                        tValid[footprintAddr] = {x=tx,y=ty,addr=footprintAddr,sourceCmdAddr=addr}
                                        coord.bHasChildren=true
                                    else
                                        coord.bFlipX = bFlipX
                                        tValid[footprintAddr] = coord
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        tempCommand.tTiles = tValid
        tempCommand.tAffectedTiles = tAffectedTiles
        table.insert(tCmds,tempCommand)
    end

    local batchCommand = CommandObject.new(CommandObject.COMMAND_BATCH, tCmds)
    batchCommand.tInvalidTiles = tTiles
    for _,cmd in ipairs(tCmds) do
        for addr,_ in pairs(cmd.tTiles) do
            batchCommand.tInvalidTiles[addr] = nil
        end
    end
    Profile.leaveScope("Command.fromDragOp")

    return batchCommand
end

function CommandObject._invalidateCommandTile(addr, bNoRetest)
    local cmdObj = CommandObject.tCommands[addr]
    if cmdObj then
        cmdObj:invalidateTile(addr, bNoRetest)
    end
end

function CommandObject:setTileVisible(addr,bVisible)
    local coord = self.tTiles[addr]
    local bValid = true
    if not coord then
        coord = self.tInvalidTiles[addr]
        bValid = false
    end
    if not coord then return end
	
    if self.commandAction == CommandObject.COMMAND_BUILD_ENVOBJECT and coord.sourceCmdAddr then
        return
    end
    if self.commandAction == CommandObject.COMMAND_DEMOLISH and coord.sourceCmdAddr then
        return
    end
	
    if bVisible and bValid then
        local spriteProp = coord.spriteProp
        local propTable = coord.propTable
        
        if propTable and (not propTable.top and not propTable.bottom) then
            propTable = nil
            coord.propTable = nil
        end
        -- if loading a wall, propTable will exist but be empty
        if not spriteProp and (not propTable or (propTable and not next(propTable))) then
            local spriteSheetPath
            local spriteName
            local color = Gui.GREEN
            local tileAlpha = nil

            if self.commandAction == CommandObject.COMMAND_BUILD_ENVOBJECT then
                local tData = EnvObject.getObjectData(self.commandParam)
                spriteSheetPath = tData.commandSpriteSheet or EnvObject.spriteSheetPath
                spriteName = tData.commandSpriteName or tData.spriteName
                color = EnvObject.ghostColor
            elseif self.commandAction == CommandObject.COMMAND_MINE then
                spriteSheetPath = CommandObject.TileCommandSpriteSheet
                spriteName = CommandObject.MineCommandSprite
                color = Gui.RED
            elseif self.commandAction == CommandObject.COMMAND_BUILD_TILE then
                spriteSheetPath = CommandObject.TileCommandSpriteSheet
                if coord.buildTileType == CommandObject.BUILD_PARAM_VAPORIZE then
                    local tileValue = g_World._getTileValue(coord.x,coord.y)
                    if g_World.countsAsFloor(tileValue) then
                        spriteName = CommandObject.FloorCommandSprite
                        color = Gui.RED--{1, 0.25, 0.25, 1}
                    else
					    --local tDetails = g_World._getWallTileDetails(coord.x,coord.y)
                        --propTable = g_World._getWallPropTable(g_World.layers.worldWall, coord.x, coord.y, tDetails.topIdx, tDetails.bottomIdx, tDetails.bFlip, true)
                        --color = Gui.RED --{1, 0.25, 0.25, 1}
                        spriteName = CommandObject.FloorCommandSprite
                        spriteSheetPath = CommandObject.TileCommandSpriteSheet
                        color = Gui.RED --{1, 0.25, 0.25, 1}
--[[
					    -- vaporize = red version of construction viz
					    local tDetails = g_World._getWallTileDetails(coord.x,coord.y)
                        propTable = g_World._getWallPropTable(g_World.layers.worldWall, coord.x, coord.y, tDetails.topIdx, tDetails.bottomIdx, tDetails.bFlip, true)
                        color = Gui.RED --{1, 0.25, 0.25, 1}
                        ]]--
                    end
                    tileAlpha = .2
                elseif coord.buildTileType == CommandObject.BUILD_PARAM_DEMOLISH then
                    local tileValue = g_World._getTileValue(coord.x,coord.y)
                    if g_World.isDoor(tileValue) then
                        spriteName = CommandObject.FloorCommandSprite
                        color = Gui.RED--{1, 0.25, 0.25, 1}
                    elseif g_World.countsAsWall(tileValue) then
					    local tDetails = g_World._getWallTileDetails(coord.x,coord.y)
                        tDetails.topIdx = g_World.layers.worldWall.spriteSheet.names[next(Zone.CONSTRUCTION.wallCrossTop)]
                        tDetails.bottomIdx = g_World.layers.worldWall.spriteSheet.names[next(Zone.CONSTRUCTION.wallCrossBottom)]
                        propTable = g_World._getWallPropTable(g_World.layers.worldWall, coord.x, coord.y, tDetails.topIdx, tDetails.bottomIdx, tDetails.bFlip, true)
                        color = Gui.RED --{1, 0.25, 0.25, 1}
                        
                    --[[
					    -- red version of construction viz
					    local tDetails = g_World._getWallTileDetails(coord.x,coord.y)
                        propTable = g_World._getWallPropTable(g_World.layers.worldWall, coord.x, coord.y, tDetails.topIdx, tDetails.bottomIdx, tDetails.bFlip, true)
                        color = Gui.RED --{1, 0.25, 0.25, 1}
                        spriteName = CommandObject.FloorCommandSprite
                        spriteSheetPath = CommandObject.TileCommandSpriteSheet
                        ]]--
                    end
                elseif coord.buildTileType == g_World.logicalTiles.WALL then
                    -- use World's rules for determining wireframe wall type
                    -- local top, bottom, flip = g_World._getBaseWallTile(coord.x, coord.y)
                    local tDetails = g_World._getWallTileDetails(coord.x,coord.y)
					color = {1, 1, 1, 1}
                    propTable = g_World._getWallPropTable(g_World.layers.worldWall, coord.x, coord.y, tDetails.topIdx, tDetails.bottomIdx, tDetails.bFlip, true, coord.propTable)
                    -- for now show top and bottom, regardless of cutaway status
                elseif coord.buildTileType == g_World.logicalTiles.ZONE_LIST_START then
                    spriteName = CommandObject.FloorCommandSprite
                    color = {1, 1, 1}
                else
                    --assertdev(false)
                    Print(TT_Warning, "bad command coord buildTileType "..tostring(coord.buildTileType))
                    self:invalidateTile(addr)
                    return
                end
                --color = {1,0,0,1}
            elseif self.commandAction == CommandObject.COMMAND_CANCEL then
            elseif self.commandAction == CommandObject.COMMAND_DEMOLISH then
            else
                spriteSheetPath = CommandObject.TileCommandSpriteSheet
                spriteName = CommandObject.VaporizeCommandSprite
            end

            if self.commandAction == CommandObject.COMMAND_DEMOLISH or
                (self.commandAction == CommandObject.COMMAND_BUILD_TILE and 
                    (coord.buildTileType == CommandObject.BUILD_PARAM_VAPORIZE or coord.buildTileType == CommandObject.BUILD_PARAM_DEMOLISH)) then
                local rObj = ObjectList.getObjAtTile(coord.x,coord.y,ObjectList.ENVOBJECT)
                if rObj then
                    rObj:setSlatedForDemolition(true)
                end
            end

			-- display the prop(s)
			local renderLayer = Renderer.getRenderLayer(CommandObject.CommandRenderLayer)
            if spriteName then
                local spriteSheet = DFGraphics.loadSpriteSheet( spriteSheetPath )
                spriteProp = MOAIProp.new()
                spriteProp:setDeck(spriteSheet)
                local index = spriteSheet.names[spriteName] 
                spriteProp:setIndex(index)
                spriteProp:setColor(unpack(color))
                renderLayer:insertProp(spriteProp)
                coord.spriteProp = spriteProp
				-- remember name for eg determining EnvObject type later
				coord.objectType = self.commandParam
            end
            if propTable then
                assertdev(propTable.top)
                assertdev(propTable.bottom)
				coord.propTable = propTable
				coord.propTable.top:setColor(unpack(color))
				coord.propTable.bottom:setColor(unpack(color))
                coord.propTable.top:setVisible(true)
                local x,y,z = coord.propTable.top:getLoc()
                coord.propTable.top:setLoc(x,y,z+10)
                coord.propTable.top.bVisible = true
                
				-- respect cutaway
				--if GameRules.cutawayMode then
--					Renderer.getRenderLayer('WorldWall'):removeProp(coord.propTable.top)
				--end
                -- TODO MTF:
                -- I only add where there aren't walls already, because this was clobbering
                -- real walls and screwing up cutaway. But that means cutaway doesn't work for
                -- commands such as "vaporize that wall."
                if not g_World.tWalls[addr] then
                    --g_World.addWall(addr, {tProps=coord.propTable})
                end
			end
            if tileAlpha then
                coord.tileAlpha=tileAlpha
            end
        end
		
        local wx,wy,wz
        if self.commandAction == CommandObject.COMMAND_BUILD_ENVOBJECT then
            wx,wy,wz = EnvObject.getSpriteLocFromTile(self.commandParam,coord.x,coord.y,coord.bFlipX)
        else
            wx,wy = g_World._getWorldFromTile(coord.x,coord.y, 1, MOAIGridSpace.TILE_LEFT_TOP)
            wz = g_World.getHackySortingZ(wx,wy,true)
            -- floor tiles sorting in front of nearby walls, cheat em a bit
            if coord.buildTileType == g_World.logicalTiles.ZONE_LIST_START then
                wz = wz - 40
            else
                wz = wz+100
            end
        end
        if coord.tileAlpha then
            Lighting.setAlphaForTile(coord.x,coord.y,coord.tileAlpha)
        end
        if spriteProp then
            spriteProp:setLoc(wx,wy,wz)
            if coord.bFlipX then
                spriteProp:setScl(-1,1)
            end
        end
    else
        if coord.tileAlpha then
            coord.tileAlpha=nil
            Lighting.setAlphaForTile(coord.x,coord.y,1)
        end
        if coord.spriteProp then
            Renderer.getRenderLayer(CommandObject.CommandRenderLayer):removeProp(coord.spriteProp)
            coord.spriteProp = nil
        elseif coord.propTable then
			-- remove from cutaway list
            g_World.removeWall(addr,coord.propTable)
            -- if this was a wall, clear out its possibly-multiple props
            for _,prop in pairs(coord.propTable) do
                g_World.layers.worldWall.renderLayer:removeProp(prop)
            end
            coord.propTable = nil
        end

        -- Re-test an object's "to be demolished" state. Just because this command is being hidden
        -- doesn't mean other commands aren't setting it up for demolition.
        local rObj,bDemolish = self:_retestObjectForDemolition(coord.x,coord.y)
        if rObj then 
            rObj:setSlatedForDemolition(bDemolish) 
        end
        
        if CommandObject.tCommands[addr] and CommandObject.tCommands[addr] ~= self and CommandObject.tCommands[addr].bVisible then
            -- hack to refresh visuals on the command underneath this one.
            CommandObject.tCommands[addr]:setTileVisible(addr,true)
        end
	end
end

function CommandObject:_retestObjectForDemolition(tx,ty)
    local rObj = ObjectList.getObjAtTile(tx,ty,ObjectList.ENVOBJECT)
    if rObj then
        local ignoreAddr = g_World.pathGrid:getCellAddr(tx,ty)
        local tAddrs = rObj:getFootprint()
        local bDemolish = false
        for _,addr in ipairs(tAddrs) do
            local testX,testY = g_World.pathGrid:cellAddrToCoord(addr)
            local tCmd = CommandObject.tCommands[addr] 
            if tCmd and (tCmd ~= self or addr ~= ignoreAddr) and (tCmd.commandAction == CommandObject.COMMAND_DEMOLISH or
                (tCmd.commandAction == CommandObject.COMMAND_BUILD_TILE and
                    tCmd.tTiles[addr].buildTileType  == CommandObject.BUILD_PARAM_VAPORIZE)) then
                bDemolish = true
                break
            end
        end
        return rObj,bDemolish
    end
end

function CommandObject:invalidateTile(addr, bNoRetest)
    local coord = self.tTiles[addr]
    if not coord then return end

    local function removeTile(addr)
        local bConstruction = self:isConstruction(addr) 
        self:setTileVisible(addr,false)
        self.tTiles[addr] = nil
        self.tAffectedTiles[addr] = nil
        CommandObject.tCommands[addr] = nil

        CommandObject.tBuildTiles['inside']['wall'][addr] = nil
        CommandObject.tBuildTiles['inside']['floor'][addr] = nil
        CommandObject.tBuildTiles['inside']['asteroid'][addr] = nil
        CommandObject.tBuildTiles['outside']['wall'][addr] = nil
        CommandObject.tBuildTiles['outside']['floor'][addr] = nil
        CommandObject.tBuildTiles['outside']['asteroid'][addr] = nil
        
        -- MTF fixupVisuals hack: might be better to use a delegate if we're going to base a lot of 
        -- world visuals on construction status.
        if bConstruction then
            g_World._dirtyTile(g_World.pathGrid:cellAddrToCoord(addr))
        end

        CommandObject.bActivitiesDirty=true
    end

    if coord.sourceCmdAddr then
        return self:invalidateTile(coord.sourceCmdAddr,bNoRetest)
    elseif coord.bHasChildren then
        for childAddr,childCoord in pairs(self.tTiles) do
            if childAddr == addr or childCoord.sourceCmdAddr == addr then
                removeTile(childAddr)
            end
        end
    else
        removeTile(addr)
    end

    if not bNoRetest then
        self:retestCommandValidity()
    end
end

function CommandObject:onAdd()
    self.bTemp = false
    self.tInvalid = {}
    for addr,coord in pairs(self.tTiles) do
        local oldCmd = CommandObject.tCommands[addr]
        if oldCmd and oldCmd ~= self then
            oldCmd:invalidateTile(addr)
            oldCmd = CommandObject.tCommands[addr]
        end

        assert(not oldCmd or oldCmd == self)

        coord.addr = addr
        CommandObject.tCommands[addr] = self
        --tempCommand:updateCommandVisuals(coord, true)
    end
end

function CommandObject:remove()
    self.bValid = false
    for addr,coord in pairs(self.tTiles) do
        CommandObject.tCommands[addr] = nil
        CommandObject.bActivitiesDirty=true
        --self:updateCommandVisuals(coord, false)
    end
    self:setCommandVisible(false)
end

function CommandObject:addTile(addr,coord)
    if self.tTiles[addr] and self.bVisible then
        self:setTileVisible(addr,false)
    end

    local oldCmd = CommandObject.tCommands[addr]
    if oldCmd and oldCmd ~= self then
        oldCmd:invalidateTile(addr)
        oldCmd = CommandObject.tCommands[addr]
    end
    assert(not oldCmd or oldCmd == self)

    coord.addr = addr
    CommandObject.tCommands[addr] = self
    self.tTiles[addr] = coord
    if self.bVisible then
        self:setTileVisible(addr,true)
    end
end

function CommandObject:getCoord(addr)
    if self.commandAction == CommandObject.COMMAND_BATCH then
        for _,cmd in ipairs(self.commandParam) do
            local coord = cmd:getCoord(addr)
            if coord then return coord end
        end
    else
        return self.tTiles[addr]
    end
end


function CommandObject:retestCommandValidity()
    if not self.bValid then
        return false
    end
    for addr,coord in pairs(self.tTiles) do
        if not coord.sourceCmdAddr then
            local validity = CommandObject._canPerformAt(self.commandAction, self.commandParam, coord)
            if validity ~= CommandObject.TILE_VALID then
                self:invalidateTile(addr,true)
            elseif self.commandAction == CommandObject.COMMAND_DEMOLISH then
                if not ObjectList.isTag(self.commandParam) then
                    self:invalidateTile(addr,true)
                end
            end
        end
    end
    if self ~= CommandObject.tBuildCmd and self ~= CommandObject.tMineCmd then
        if not next(self.tTiles) then
            self:remove()
            return false
        end
    end
    return true
end

-- command "state saving" - used for back/confirm functionality

function CommandObject.saveCommandStates()
	-- saves current command states for possible restore later
	CommandObject.tPrevCommands = CommandObject.getSaveTable()
    CommandObject.tPrevCosts = CommandObject.computePendingCosts()
    CommandObject.updatePendingCosts()
	print('entered build mode, saved command state')
end

function CommandObject.restoreCommandStates()
	CommandObject.pendingBuildCost = 0
	CommandObject.pendingVaporizeCost = 0
	CommandObject.pendingMineCost = 0
	CommandObject.pendingCancelCost = 0
    CommandObject.tPrevCosts = nil
	CommandObject.fromSaveTable(CommandObject.tPrevCommands)
	CommandObject.clearSavedCommandStates(true)
    Room.removeAllPendingPropPlacements()
    Room.removeAllPendingObjectCancels()
	print('aborted build mode, restored command state')
end

function CommandObject.getTotalPendingCost()
	return CommandObject.pendingBuildCost + CommandObject.pendingCancelCost + Room.getPendingPropPlacementCost() - Room.getPendingObjectCancelCost()
end

function CommandObject.getCurrentPendingBuildCost()
    return CommandObject.pendingBuildCost + Room.getPendingPropPlacementCost() - Room.getPendingObjectCancelCost()
end

function CommandObject.canAffordCost()
	return GameRules.nMatter - CommandObject.getTotalPendingCost() > 0
end

function CommandObject.clearSavedCommandStates(bRestoring, bDontExpendMatter)
	CommandObject.tPrevCommands = nil
	if not bRestoring then
        if not bDontExpendMatter then
            -- commit total matter cost, sans mine or vaporize
            local total = CommandObject.getTotalPendingCost()
            GameRules.expendMatter(total)
        end
		CommandObject.pendingBuildCost = 0
		CommandObject.pendingVaporizeCost = 0
		CommandObject.pendingMineCost = 0
		CommandObject.pendingCancelCost = 0
        Room.confirmAllPendingPropPlacements()
        Room.confirmAllPendingObjectCancels()
		print('confirmed build, wiped command state')
	end
end

function CommandObject.getPriorCommand(cellAddr)
	-- returns a command type and command data if tile with given address was
    -- confirmed in a previous build session, nil if tile was set down this
    -- session (ie part of cost estimates)
    if not (CommandObject.tPrevCommands or CommandObject.tCommands) then
        return nil
    end
    for idx,cmd in pairs(CommandObject.tPrevCommands) do
        if cmd.tTiles[cellAddr] then
            return idx,cmd,cmd.tTiles[cellAddr]
        end
    end
    return nil
end

function CommandObject.addCommand(tempCommandObject)
    if tempCommandObject.commandAction == CommandObject.COMMAND_BATCH then
        for _,cmd in ipairs(tempCommandObject.commandParam) do
            CommandObject.addCommand(cmd)
        end
        return
    end
    
    if tempCommandObject.bValid then
        local rAddedCommand = CommandObject._addCommand(tempCommandObject)
        CommandObject.updatePendingCosts()
        return rAddedCommand
    end
end

function CommandObject.updatePendingCosts()
    local tPendingCosts = CommandObject.computePendingCosts()
    local nOldBuild=(CommandObject.tPrevCosts and CommandObject.tPrevCosts.pendingBuildCost) or 0
    local nOldVaporize=(CommandObject.tPrevCosts and CommandObject.tPrevCosts.pendingVaporizeCost) or 0
    local nOldMine=(CommandObject.tPrevCosts and CommandObject.tPrevCosts.pendingMineCost) or 0
    local nOldCancel=(CommandObject.tPrevCosts and CommandObject.tPrevCosts.pendingCancelCost) or 0
	CommandObject.pendingBuildCost = tPendingCosts.pendingBuildCost-nOldBuild
	CommandObject.pendingVaporizeCost = tPendingCosts.pendingVaporizeCost-nOldVaporize
	CommandObject.pendingMineCost = tPendingCosts.pendingMineCost-nOldMine
	CommandObject.pendingCancelCost = tPendingCosts.pendingCancelCost-nOldCancel
end

function CommandObject.computePendingCosts()
    local t = {}
	t.pendingBuildCost = 0
	t.pendingVaporizeCost = 0
	t.pendingMineCost = 0
	t.pendingCancelCost = 0
    local tCmds={}
    for addr,cmdObj in pairs(CommandObject.tCommands) do
        tCmds[cmdObj] = cmdObj
    end
    for cmdObj,_ in pairs(tCmds) do
        local nPB,nPV,nPM,nPC = cmdObj:computeCosts()
        t.pendingBuildCost=t.pendingBuildCost+nPB
        t.pendingVaporizeCost=t.pendingVaporizeCost+nPV
        t.pendingMineCost=t.pendingMineCost+nPM
        t.pendingCancelCost=t.pendingCancelCost+nPC
    end
    return t
end

function CommandObject:computeCosts()
	local pB = 0
	local pV = 0
	local pM = 0
	local pC = 0
    if self.commandAction == CommandObject.COMMAND_BATCH then
        for _,cmd in ipairs(self.commandParam) do
            local b,v,m,c = cmd:computeCosts()
            pB=pB+b
            pV=pV+v
            pM=pM+m
            pC=pC+c
        end
    else
		if self.commandAction == CommandObject.COMMAND_BUILD_TILE then
            pV = pV + self:getMatterCost('vaporizeonly')
            pB = pB + self:getMatterCost('novaporize')
        elseif self.commandAction == CommandObject.COMMAND_VAPORIZE then
			pV=pV + self:getMatterCost()
		elseif self.commandAction == CommandObject.COMMAND_MINE then
			pM=pM + self:getMatterCost()
		elseif self.commandAction == CommandObject.COMMAND_BUILD_ENVOBJECT then
			pB = pB + self:getMatterCost()
		end
    end
    
    return pB,pV,pM,pC
end

function CommandObject._addCommand(tempCommand)
    assert(tempCommand.bValid)
    assert(tempCommand.bTemp)
    
    local addedCommand = nil

    for addr,coord in pairs(tempCommand.tTiles) do
        CommandObject._invalidateCommandTile(addr, true)
    end
    local tTested = {}
    for addr,coord in pairs(tempCommand.tTiles) do
        if coord.sourceCmdAddr and tempCommand.commandAction ~= CommandObject.COMMAND_DEMOLISH and tempCommand.commandAction ~= CommandObject.COMMAND_BUILD_ENVOBJECT then
            -- taking care of old savedata: only two command types can have a sourceCmdAddr.
            tempCommand.tTiles[addr] = nil
        elseif CommandObject.tCommands then
            local cmdObj = CommandObject.tCommands[addr]
            if cmdObj and not tTested[cmdObj] then    
                tTested[cmdObj] = 1
                cmdObj:retestCommandValidity()
            end
        end
    end
    
    if not next(tempCommand.tTiles) then
        tempCommand:remove()
        return nil
    end

    if tempCommand.commandAction == CommandObject.COMMAND_MINE then
        for addr,coord in pairs(tempCommand.tTiles) do
            CommandObject.tMineCmd:addTile(addr,coord)
        end
        CommandObject.tMineCmd:setCommandVisible(true)
        addedCommand = CommandObject.tMineCmd
    elseif tempCommand.commandAction == CommandObject.COMMAND_DEMOLISH then
        -- object demolish
        tempCommand:onAdd()
        tempCommand:setCommandVisible(true)
        addedCommand = tempCommand
    elseif tempCommand.commandAction == CommandObject.COMMAND_BUILD_TILE or tempCommand.commandAction == CommandObject.COMMAND_VAPORIZE then
        -- Here, build, demolish, and vaporize tile commands all get lumped together into one mega-command.
        -- Demolish has already been converted.
        for addr,coord in pairs(tempCommand.tTiles) do
            CommandObject.tBuildCmd:addTile(addr,coord)
            if tempCommand.commandAction == CommandObject.COMMAND_VAPORIZE then
                coord.buildTileType = CommandObject.BUILD_PARAM_VAPORIZE
            end
            assert(coord.buildTileType)
        end
        CommandObject.tBuildCmd:setCommandVisible(true)
        addedCommand = CommandObject.tBuildCmd
    elseif tempCommand.commandAction == CommandObject.COMMAND_CANCEL then
        for addr,coord in pairs(tempCommand.tTiles) do
            CommandObject._invalidateCommandTile(addr)
            -- see if there's any object placements we need to cancel
            Room.removePendingPropPlacementAtTile(coord.x, coord.y)
            local rObj = ObjectList.getObjAtTile(coord.x,coord.y,ObjectList.ENVOBJECT)
            if rObj then
                if rObj:slatedForTeardown(false,true) then
                    rObj:setSlatedForDemolition(false)
                end
            end
            Room.addPendingObjectCancel(coord.x, coord.y)
        end
        tempCommand:remove()
        return nil
    else
        tempCommand:onAdd()
        tempCommand:setCommandVisible(true)
        addedCommand = tempCommand
    end

    CommandObject.bActivitiesDirty=true

    return addedCommand
end

function CommandObject:setCommandVisible(bVisible,bDrawInvalid)
    self.bVisible = bVisible

    if self.commandAction == CommandObject.COMMAND_BATCH then
        Profile.enterScope("Cursor.setCommandVisibleBatch")
        for _,cmd in ipairs(self.commandParam) do
            cmd:setCommandVisible(bVisible,bDrawInvalid)
        end
        Cursor.drawTiles(self.tInvalidTiles,false,bVisible)
        Profile.leaveScope("Cursor.setCommandVisibleBatch")
        return
    end

        Profile.enterScope("Cursor.setCommandVisible")
    if self.commandAction == CommandObject.COMMAND_CANCEL then
        Cursor.drawTiles(self.tTiles,true,bVisible)
    else
        for addr,coord in pairs(self.tTiles) do
            self:setTileVisible(addr,bVisible)
        end
    end
    Cursor.drawTiles(self.tInvalidTiles,false,bVisible)
    
        Profile.leaveScope("Cursor.setCommandVisible")
end

function CommandObject._canVaporizeTile(tx,ty)
    local tileValue = g_World._getTileValue(tx, ty)
    if g_World.countsAsWall(tileValue) then
        return CommandObject.TILE_VALID
        -- doors
    elseif g_World.countsAsFloor(tileValue) or g_World.isDoor(tileValue) then
        return CommandObject.TILE_VALID
        --local oldObj = ObjectList.getObjAtTile(tx, ty,ObjectList.ENVOBJECT)
        --if not oldObj then
            --return CommandObject.TILE_VALID
        --end
        -- unmined, non-dim asteroids
    elseif GameRules.inEditMode then
        return CommandObject.TILE_VALID
    end
    return CommandObject.TILE_INVALID
end

function CommandObject._canDemolishTile(tx,ty)
    -- Let's disallow demolishing indoor tiles that we can't see.
    -- But space-adjacent is fine.
    if g_World._getVisibility(tx,ty,1) == g_World.VISIBILITY_HIDDEN then
        if not g_World.isAdjacentToSpace(tx,ty,true,false) then
            return CommandObject.TILE_INVALID
        end
    end

    local tileValue = g_World._getTileValue(tx, ty)
    if g_World.countsAsWall(tileValue) then
        return CommandObject.TILE_VALID
        -- doors
    elseif g_World.isDoor(tileValue) then
        return CommandObject.TILE_VALID
        -- unmined, non-dim asteroids
    elseif GameRules.inEditMode then
        return CommandObject.TILE_VALID
    end
    
    local obj = ObjectList.getObjAtTile(tx, ty,ObjectList.ENVOBJECT)
    if obj then
        return CommandObject.TILE_VALID
    end
    return CommandObject.TILE_INVALID
end

function CommandObject._testMine(tx,ty)
    local tileValue = g_World._getTileValue(tx, ty)
    if Asteroid.isAsteroid(tileValue) then
        return CommandObject.TILE_VALID
    end
    return CommandObject.TILE_INVALID
end

function CommandObject._testBuildFloor(tx,ty)
    if GameRules.inEditMode then return CommandObject.TILE_VALID end
    
    local tileValue = g_World._getTileValue(tx, ty)
    if Asteroid.isAsteroid(tileValue) then
        return CommandObject.TILE_INVALID
    elseif tileValue == g_World.logicalTiles.WALL or g_World.countsAsFloor(tileValue) or g_World.isDoor(tileValue) then
        return CommandObject.TILE_INVALID
    end
    -- deliberately allowing WALL_DESTROYED to fall through-- let people build floor on top of destroyed wall if they want.
    return CommandObject.TILE_VALID
end

function CommandObject.tileChanged(tx,ty,addr,tileValue)
    -- MTF TODO: this doesn't check tAffectedTiles. tAffectedTiles includes things like buffer space for props,
    -- and violates the 1-command-per-tile assumption.
    -- So we could see bugs where characters don't realize a command is invalid until they try to perform it.

    local cmdObj = CommandObject.tCommands[addr]
    if cmdObj then
        cmdObj:retestCommandValidity() 
    end
end

function CommandObject.getSortedTilesInRange(wx,wy,nDist,commandType,rTask,bInside)
    nDist = nDist or g_World.tileWidth * 30
    local tAllTiles = {}
    if commandType == CommandObject.COMMAND_BUILD_TILE then
        tAllTiles = DFUtil.tableMergeNew(CommandObject.getBuildTiles(bInside,'wall',rTask),CommandObject.getBuildTiles(bInside,'floor',rTask))
    elseif commandType == CommandObject.COMMAND_MINE then
        tAllTiles = CommandObject.getBuildTiles(bInside,'asteroid',rTask)
    else
        assert(false)
    end
    local tSortedTiles = {}
    for addr,tTileData in pairs(tAllTiles) do
        table.insert(tSortedTiles, tTileData)
    end
    table.sort(tSortedTiles, function(a,b)
            return MiscUtil.isoDist(wx,wy,a.x,a.y) < MiscUtil.isoDist(wx,wy,b.x,b.y)
        end)
    return tSortedTiles, true
end


-- find a build command at the specified location, or adjacent.
-- returns world coordinates, despite the name.
function CommandObject.findBuildTile(worldX,worldY,requiredType,rTask,nRange)
    local tileX,tileY = g_World._getTileFromWorld(worldX,worldY) 
    local testFn=function(tx,ty)
        if rTask then
            if rTask.rActivityOption:reserved(tx,ty,rTask.rChar) then return false end
        end

        local addr = g_World.pathGrid:getCellAddr(tx,ty)
        local cmdObj = CommandObject.tCommands[addr]
        if cmdObj and cmdObj.commandAction == CommandObject.COMMAND_BUILD_TILE then
            -- MTF hack: regardless of required type, always adds a vaporize command.
            if cmdObj.tTiles[addr].buildTileType == CommandObject.BUILD_PARAM_VAPORIZE or not requiredType or (requiredType == g_World.logicalTiles.WALL and cmdObj.tTiles[addr].buildTileType == g_World.logicalTiles.WALL)
                    or (requiredType == g_World.logicalTiles.ZONE_LIST_START and cmdObj.tTiles[addr].buildTileType == g_World.logicalTiles.ZONE_LIST_START) then
                return true
            end
        end
    end
    return CommandObject._findAppropriateTile(worldX,worldY,testFn,nRange)
end

function CommandObject.findMineTile(worldX,worldY,rTask,nRange)
    local tileX,tileY = g_World._getTileFromWorld(worldX,worldY) 
    local testFn=function(tx,ty)
        if rTask then
            if rTask.rActivityOption:reserved(tx,ty,rTask.rChar) then return false end
        end

        local addr = g_World.pathGrid:getCellAddr(tx,ty)
        local cmdObj = CommandObject.tCommands[addr]
        if cmdObj and cmdObj.commandAction == CommandObject.COMMAND_MINE then
            return true
        end
    end
    return CommandObject._findAppropriateTile(worldX,worldY,testFn,nRange)
    --[[
    local adjx,adjy = g_World.isAdjacentToFn(tileX, tileY, testFn, true, true)
    if adjx then
        local adjcmd = CommandObject.tCommands[g_World.pathGrid:getCellAddr(adjx,adjy)]
        local targetWorldX,targetWorldY = g_World._getWorldFromTile(adjx,adjy)
        return targetWorldX,targetWorldY,adjcmd
    end
    ]]--
end

function CommandObject._findAppropriateTile(wx,wy,testFn,nRange)
    local tileX,tileY = g_World._getTileFromWorld(wx,wy)
    local foundTX,foundTY 
    if not nRange then
        foundTX,foundTY = g_World.isAdjacentToFn(tileX, tileY, testFn, true, true)
    else
		-- only modify the range in x, since the iso rect will grab us a good range of y as well.
        local tTiles = GridUtil.GetTilesForIsoRectangle(tileX-nRange,tileY,tileX+nRange,tileY)
        -- first test adjacent
        for i=1,9 do
            local atx,aty = g_World._getAdjacentTile(tileX,tileY, i)
            local addr = g_World.pathGrid:getCellAddr(atx,aty)
            if tTiles[addr] then
                tTiles[addr] = nil
                if testFn(atx,aty) then
                    foundTX,foundTY = atx,aty
                    break
                end
            end
        end
        if not foundTX then
            -- random order, so we don't always head the same direction every time.
            local tList = {}
            for addr, coord in pairs(tTiles) do
                table.insert(tList,coord)
            end
            while #tList > 0 do
                local idx = math.random(1,#tList)
                local coord=tList[idx]
                if testFn(coord.x,coord.y) then
                    foundTX,foundTY = coord.x,coord.y
                    break
                end
                table.remove(tList,idx)
            end
        end
    end
    if foundTX then
        local addr = g_World.pathGrid:getCellAddr(foundTX,foundTY)
        local adjcmd = CommandObject.tCommands[addr]
        local targetWorldX,targetWorldY = g_World._getWorldFromTile(foundTX,foundTY)
        return targetWorldX,targetWorldY,adjcmd,adjcmd.tTiles[addr]
    end
end

function CommandObject._performAllCommands()
    local addr = next(CommandObject.tCommands)
    while addr do
        local tx,ty = g_World.pathGrid:cellAddrToCoord(addr)
        CommandObject._performCommand(CommandObject.tCommands[addr],tx,ty)
        addr = next(CommandObject.tCommands)
    end
end

function CommandObject._removeAllCommands()
    for addr,cmd in pairs(CommandObject.tCommands) do
        cmd:remove()
    end
end

function CommandObject.performCommandAtTile(cmdObj,tx,ty)
    if CommandObject._performCommand(cmdObj,tx,ty) then
        return true
    end
end

function CommandObject._performCommand(cmdObj,tx,ty)
    local tileAddr

    if tx then
        tileAddr = g_World.pathGrid:getCellAddr(tx,ty)
    else
        local firstCoord = cmdObj.tTiles[ next(cmdObj.tTiles) ]
        tileAddr = g_World.pathGrid:getCellAddr(firstCoord.x, firstCoord.y)
    end

    local coord = cmdObj.tTiles[tileAddr]
    
    if coord.sourceCmdAddr then
        coord = cmdObj.tTiles[coord.sourceCmdAddr]
    end
    assert(coord)

    local bSuccess = false

    if cmdObj.commandAction == CommandObject.COMMAND_BUILD_TILE then
        bSuccess = g_World._buildTile(coord.x,coord.y,coord.buildTileType)
        cmdObj:invalidateTile(tileAddr)
    elseif cmdObj.commandAction == CommandObject.COMMAND_BUILD_ENVOBJECT then
        local wx,wy = g_World._getWorldFromTile(coord.x,coord.y)
        -- For now, we assume all EnvObjects are exclusive.
        -- May not always be the case.
        local tPropTiles = g_World._getPropFootprint(coord.x,coord.y, cmdObj.commandParam, false, coord.bFlipX)
        if GameRules.inEditMode then
            for i,tile in ipairs(tPropTiles) do 
                local oldObj = ObjectList.getObjAtTile(coord.x,coord.y,ObjectList.ENVOBJECT)
                if oldObj then
                    oldObj:remove()
                end
            end
        end

        local rProp = require('EnvObjects.EnvObject').createEnvObject(cmdObj.commandParam, wx,wy, coord.bFlipX, coord.bFlipY, GameRules.inEditMode)
        cmdObj:remove()
        bSuccess = (rProp ~= nil)
    elseif cmdObj.commandAction == CommandObject.COMMAND_VAPORIZE or cmdObj.commandAction == CommandObject.COMMAND_DEMOLISH then
        local obj = ObjectList.getObjAtTile(coord.x,coord.y,ObjectList.ENVOBJECT)
        if obj then
            obj:remove()
            bSuccess = true
        end
        cmdObj:remove()
    elseif cmdObj.commandAction == CommandObject.COMMAND_MINE then
        local tileValue = g_World._getTileValue(coord.x,coord.y)
        bSuccess,tileValue = Asteroid.vaporizeTile(coord.x,coord.y,tileValue)
        if tileValue == g_World.logicalTiles.SPACE then
            cmdObj:invalidateTile(tileAddr)
        end
    else
        assert(false)
    end
    return bSuccess
end

function CommandObject.getConstructionAtTile(tx,ty)
    local cmdObj,coord = CommandObject.getCommandAtTile(tx,ty,true)
    if cmdObj and cmdObj:isConstruction(coord.addr) then return coord.buildTileType,cmdObj,coord end
end

function CommandObject:isConstruction(addr)

    if self.commandAction  == CommandObject.COMMAND_BATCH then
        for _,cmd in ipairs(self.commandParam) do
            if cmd:isConstruction(addr) then return true end
        end
    end
    if not self.tTiles[addr] then return false end

    if self.commandAction == CommandObject.COMMAND_BUILD_TILE then
        if self.tTiles[addr].buildTileType ~= CommandObject.BUILD_PARAM_VAPORIZE and self.tTiles[addr].buildTileType ~= CommandObject.BUILD_PARAM_DEMOLISH then
            return true
        end
    end
    return false
end

function CommandObject.getCommandAtWorld(wx,wy)
    local tx,ty = g_World._getTileFromWorld(wx,wy)
	return CommandObject.getCommandAtTile(tx,ty)
end

function CommandObject.getCommandAtTile(tx,ty,bIncludeTemp)
    local addr = g_World.pathGrid:getCellAddr(tx,ty)
    if bIncludeTemp and Cursor.tempCommand and Cursor.tempCommand:getCoord(addr) then
        return Cursor.tempCommand,Cursor.tempCommand:getCoord(addr)
    end

    local cmdObj = CommandObject.tCommands[addr]
    if cmdObj then
        return cmdObj,cmdObj.tTiles[addr]
    end
end

--[[
function CommandObject.getCommandColorAtAddr(addr)
    if CommandObject.tCommands[addr] then
        return CommandObject.orderTargetColor
    end
end
]]--

function CommandObject.getSaveTable(xOff,yOff)
    if not xOff then
        local tDone={}
        local tSave = {}
        for addr,cmd in pairs(CommandObject.tCommands) do
            if not tDone[cmd] then
                tDone[cmd] = 1

                table.insert(tSave,cmd:getSaveData())
            end
        end

        return tSave
    end
end

function CommandObject.fromSaveTable(tSave, xOff, yOff, bClearSavedCommandStates)
    if tSave and not xOff then
        CommandObject.shutdown()
        CommandObject.staticInit()
        for i,data in ipairs(tSave) do
            local param = data.commandParam
            local cmd = CommandObject.new(data.commandAction,param)
            cmd.tTiles=data.tTiles or {}
            cmd.tInvalidTiles=data.tInvalidTiles or {}
            cmd.tAffectedTiles=data.tAffectedTiles or {}
            CommandObject.addCommand(cmd)
        end
        -- the following is mainly here when you load up a game
        -- this clears out all pending costs so that loaded costs aren't computed
        if bClearSavedCommandStates then
            CommandObject.clearSavedCommandStates(false, true)
        end
    end
end

function CommandObject.shutdown()
    if CommandObject.tCommands then
        CommandObject._removeAllCommands()
    end
end

function CommandObject.staticInit()
    UtilityAI = require('Utility.UtilityAI')
    Cursor = require('UI.Cursor')
    ActivityOption=require('Utility.ActivityOption')
    ActivityOptionList=require('Utility.ActivityOptionList')
    EnvObject=require('EnvObjects.EnvObject')
    PickupData=require('Pickups.PickupData')
    Room=require('Room')
    
    CommandObject.tBuildTiles = { inside={ floor={}, wall={},asteroid={} }, outside={ floor={}, wall={},asteroid={} } }
    CommandObject.activityOptionList = ActivityOptionList.new(CommandObject)
    CommandObject.tCommands = {}    
    CommandObject.bActivitiesDirty = true
    CommandObject.tBuildCmd = CommandObject.new(CommandObject.COMMAND_BUILD_TILE)
    CommandObject.tMineCmd = CommandObject.new(CommandObject.COMMAND_MINE)
    CommandObject.coBuildTileIter = CommandObject._cmdTileIter('build')
    CommandObject.coMineTileIter = CommandObject._cmdTileIter('mine')
    g_World.dTileChanged:register(CommandObject.tileChanged)
    ObjectList.dTileContentsChanged:register(function(tx,ty,sourceTag,bSet) CommandObject.tileChanged(tx,ty,sourceTag.addr) end)
    --g_World.dPropGridChanged:register(CommandObject.propGridChanged)
end

function CommandObject.onTick( dt )
    CommandObject._refreshBuildTiles()
    CommandObject._refreshMineTiles()
end

function CommandObject.getActivityOptions(rChar, tObjects)
    local tCmds = {}
    if CommandObject.bActivitiesDirty then
        for addr,cmdObj in pairs(CommandObject.tCommands) do
            tCmds[cmdObj] = cmdObj
        end
        local tActivities = {}
        for cmdObj,_ in pairs(tCmds) do
            CommandObject._addCommandAsActivity(cmdObj,tActivities)
        end
        CommandObject.activityOptionList:set(tActivities)
        CommandObject.bActivitiesDirty = false
    end
    tObjects = tObjects or {}
    table.insert(tObjects, CommandObject.activityOptionList:getListAsUtilityOptions())
    return tObjects
end

-- Returns ipairs {x=worldX,y=worldX,val=desiredBuildTileType,addr=addr}
function CommandObject.getBuildTiles(bInside,sGroup,rTask)
    local insideIdx = (bInside and 'inside') or 'outside'
    if rTask then
        local tTiles = {}
        for addr,tileData in pairs(CommandObject.tBuildTiles[insideIdx][sGroup]) do
            if not rTask.rActivityOption:reserved(tileData.tx,tileData.ty,rTask.rChar) then
                tTiles[addr] = tileData
            end
        end
        return tTiles
    else
        return CommandObject.tBuildTiles[insideIdx][sGroup]
    end
end

function CommandObject._cmdTileIter(sType)
    return coroutine.wrap(function()
        while true do
            local tTiles = (sType == 'build' and CommandObject.tBuildCmd.tTiles) or CommandObject.tMineCmd.tTiles
            for addr,coord in pairs(tTiles) do
                if tTiles[addr] then
                    coroutine.yield(addr,coord)
                end
            end
            coroutine.yield()
        end
    end)
end

    CommandObject._indoorFn = function(tx,ty)
        local tileValue = g_World._getTileValue(tx,ty)
        if not g_World.countsAsFloor(tileValue) then return false end

        local rRoom = Room.getRoomAtTile(tx,ty,1)
        if rRoom and rRoom:isBreached() then return false end
        
        local o2 = g_World.oxygenGrid:getOxygen(tx,ty)
        return o2 > Character.OXYGEN_LOW 
    end

    CommandObject._getTargetTableMine = function(coord,addr)
        local tileValue = g_World._getTileValue(coord.x,coord.y)

        if g_World.isAdjacentToFn(coord.x, coord.y, CommandObject._indoorFn) then
            return CommandObject.tBuildTiles['inside']['asteroid']
        end
        if g_World.isAdjacentToSpace(coord.x,coord.y,true,true) then
            return CommandObject.tBuildTiles['outside']['asteroid']
        end
        -- If we're not indoors and not adjacent to space, we're likely embedded in an asteroid. 
        -- We don't know if that'll be reached via space or indoors, so just don't add for now.
        return nil
    end

    CommandObject._getTargetTable = function(coord,addr)
        local tileValue = g_World._getTileValue(coord.x,coord.y)
        local o2

        if coord.buildTileType == CommandObject.BUILD_PARAM_VAPORIZE then 
            -- Vaporize will be outside by the time the operation is done, so it needs a spacesuit.
            return CommandObject.tBuildTiles['outside'][(g_World.countsAsFloor(tileValue) and 'floor') or 'wall']
        end

        local wallOrFloor = (coord.buildTileType == g_World.logicalTiles.WALL and 'wall') or 'floor'
        if g_World.isAdjacentToSpace(coord.x,coord.y,true,true) then
            return CommandObject.tBuildTiles['outside'][wallOrFloor]
        end
        if g_World.oxygenGrid:checkTileFlag(coord.x, coord.y,DFOxygenGrid.TILE_OCCLUDE) then
            return CommandObject.tBuildTiles['inside'][wallOrFloor]
        end

        o2 = g_World.oxygenGrid:getOxygen(coord.x,coord.y)
        local bOutside = o2 < Character.OXYGEN_SUFFOCATING
        return CommandObject.tBuildTiles[(bOutside and 'outside') or 'inside'][wallOrFloor]
    end

function CommandObject._refreshMineTiles()
    local addr, coord = CommandObject.coMineTileIter()

    if not addr then 
        return 
    end

    CommandObject.tBuildTiles['inside']['asteroid'][addr] = nil
    CommandObject.tBuildTiles['outside']['asteroid'][addr] = nil

    local wx,wy = g_World._getWorldFromTile(coord.x,coord.y)
    local tTileData = {x=wx,y=wy,val=coord.buildTileType,addr=addr,tx=coord.x,ty=coord.y}

    local t = CommandObject._getTargetTableMine(coord,addr)
    if t then
        t[addr] = tTileData
    end
end

function CommandObject._refreshBuildTiles()
    if CommandObject.DEBUG_PROFILE then Profile.enterScope("CO.RefreshBuildTiles") end
    
    local addr, coord = CommandObject.coBuildTileIter()
    
    if not addr then 
        if CommandObject.DEBUG_PROFILE then Profile.leaveScope("CO.RefreshBuildTiles") end
        return 
    end

    CommandObject.tBuildTiles['inside']['wall'][addr] = nil
    CommandObject.tBuildTiles['inside']['floor'][addr] = nil
    CommandObject.tBuildTiles['outside']['wall'][addr] = nil
    CommandObject.tBuildTiles['outside']['floor'][addr] = nil
    
    local wx,wy = g_World._getWorldFromTile(coord.x,coord.y)
    local tTileData = {x=wx,y=wy,val=coord.buildTileType,addr=addr,tx=coord.x,ty=coord.y}

    local t = CommandObject._getTargetTable(coord,addr)
    if t then
        t[addr] = tTileData
    end

    if CommandObject.DEBUG_PROFILE then Profile.leaveScope("CO.RefreshBuildTiles") end
end

function CommandObject.jobGate(rChar, job)
    if rChar:getJob() == job then
        return true
    else
        return false, 'wrong job'
    end
end

function CommandObject._addCommandAsActivity(cmdObj,tTarget)
    if cmdObj.commandAction == CommandObject.COMMAND_BUILD_TILE 
--            or (cmdObj.commandAction == CommandObject.COMMAND_VAPORIZE and cmdObj.commandAction == CommandObject.BUILD_PARAM_VAPORIZE) then
            or cmdObj.commandAction == CommandObject.COMMAND_MINE then
        local tData
        tData={
            targetTileListFn=function(rChar,rAO) 
                local cx,cy = rChar:getLoc()
                return CommandObject.getSortedTilesInRange(cx,cy,nil,CommandObject.COMMAND_BUILD_TILE,nil,false)
            end,
            bInside=false,
            pathToNearest=true,
            utilityGateFn=function(rChar, rAO) return CommandObject.jobGate(rChar, Character.BUILDER) end,
        }
        table.insert(tTarget, ActivityOption.new('BuildSpace',tData))
        tData={
            targetTileListFn=function(rChar,rAO) 
                local cx,cy = rChar:getLoc()
                return CommandObject.getSortedTilesInRange(cx,cy,nil,CommandObject.COMMAND_BUILD_TILE,nil,true)
            end,
            bInside=true,
            pathToNearest=true,
            utilityGateFn=function(rChar, rAO) return CommandObject.jobGate(rChar, Character.BUILDER) end,
        }
        table.insert(tTarget, ActivityOption.new('BuildInside',tData))

        tData={
            targetTileListFn=function() return CommandObject.getBuildTiles(true,'asteroid') end,
            pathToNearest=true,
            bInside=true,
            utilityGateFn=function(rChar, rAO) 
                if rChar:getInventoryCountByTemplate(InventoryData.MINE_PICKUP_NAME) >= Inventory.getMaxStacks(InventoryData.MINE_PICKUP_NAME) then
                    return false, 'too many rocks'
                end
                return CommandObject.jobGate(rChar, Character.MINER) 
            end,
        }
        table.insert(tTarget, ActivityOption.new('MineInside',tData))

        tData={
            targetTileListFn=function() return CommandObject.getBuildTiles(false,'asteroid') end,
            pathToNearest=true,
            bInside=false,
            utilityGateFn=function(rChar, rAO) 
                if rChar:getInventoryCountByTemplate(InventoryData.MINE_PICKUP_NAME) >= Inventory.getMaxStacks(InventoryData.MINE_PICKUP_NAME) then
                    return false, 'too many rocks'
                end
                return CommandObject.jobGate(rChar, Character.MINER) 
            end,
        }
        table.insert(tTarget, ActivityOption.new('MineSpace',tData))
    elseif cmdObj.commandAction == CommandObject.COMMAND_BUILD_ENVOBJECT then
        local targetAddr = next(cmdObj.tTiles)
        local targetCoord = cmdObj.tTiles[targetAddr]
        if targetCoord.sourceCmdAddr then
            targetAddr = targetCoord.sourceCmdAddr 
            targetCoord = cmdObj.tTiles[targetAddr]
        end

        local tx,ty = g_World.pathGrid:cellAddrToCoord(targetAddr)
        assert(tx == targetCoord.x and ty == targetCoord.y)
        local wx,wy = g_World._getWorldFromTile(tx,ty)
        assert(cmdObj.commandParam)
        local tData = { pathX=wx, pathY=wy, pathToNearest=true, tCommand=cmdObj, utilityGateFn=function(rChar) return require('EnvObjects.EnvObject').gateJobActivity(cmdObj.commandParam, rChar, true) end}
        table.insert(tTarget, ActivityOption.new('BuildEnvObject',tData))
    elseif cmdObj.commandAction == CommandObject.COMMAND_VAPORIZE or cmdObj.commandAction == CommandObject.COMMAND_DEMOLISH then
        local rObj = ObjectList.isTag(cmdObj.commandParam) and ObjectList.getObject(cmdObj.commandParam)
        if ObjectList.getObjType(rObj) ~= ObjectList.ENVOBJECT then
            rObj = nil
        end
        if rObj and not rObj.bDestroyed then
            table.insert(tTarget, ActivityOption.new('DestroyEnvObject', { rTargetObject=rObj, bRequiresCommand=true }))
        else
            cmdObj:remove()
        end
    else
        assert(false)
    end
end

return CommandObject
