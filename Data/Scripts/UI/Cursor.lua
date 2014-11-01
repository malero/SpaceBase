local Class=require('Class')
local GameRules=require('GameRules')
local GameScreen=require('GameScreen')
local ObjectList=require('ObjectList')
local EmergencyBeacon=require('Utility.EmergencyBeacon')
local CommandObject=require('Utility.CommandObject')
local DFInput = require('DFCommon.Input')
local Character=require('CharacterConstants')
local GridUtil=require('GridUtil')
local Renderer=require('Renderer')
local Room=require('Room')
local EnvObject=require('EnvObjects.EnvObject')
local SoundManager = require('SoundManager')
local Gui = require('UI.Gui')
local Profile = require('Profile')

local Cursor = Class.create()

Cursor.tiles={}

function Cursor.execute(touchUpWX,touchUpWY)
    local cursorMode = Cursor.modes[GameRules.currentMode]
    if not cursorMode then return end

    if cursorMode.custom then
        for addr,coord in pairs(Cursor.tiles) do
            cursorMode.custom(coord.x,coord.y,touchUpWX,touchUpWY)
        end
    else
        --[[
        local len = 0
        for _,_ in pairs(Cursor.tiles) do
            len=len+1
            if len > 1 then
                break
            end
        end

        if len > 1 then
            CommandObject.addListCommand(cursorMode.command, Cursor.tiles, cursorMode.param and cursorMode.param(Cursor.tiles,touchUpWX,touchUpWY))
        else
            CommandObject.addCommand(cursorMode.command, touchUpWX,touchUpWY, cursorMode.param and cursorMode.param(Cursor.tiles,touchUpWX,touchUpWY))
        end
        ]]--
        if Cursor.tempCommand then
            CommandObject.addCommand(Cursor.tempCommand)
            Cursor.tempCommand = nil
        end
    end
    if GameRules.inEditMode then
        CommandObject._performAllCommands()
    end
end

function Cursor.refresh()
    local startDragX,startDragY = -1,-1
    if DFInput.m_touches[DFInput.MOUSE_LEFT+1] then
        startDragX,startDragY = GameRules.startDragX, GameRules.startDragY
    end
    
    Cursor.updateGridCursor(GameRules.cursorX, GameRules.cursorY, startDragX, startDragY, GameRules.currentMode)
end

function Cursor.updateGridCursor(cursorX, cursorY, curStartX, curStartY, mode, bMouseDown)
    if not GameRules.bRunning then return end
    Profile.enterScope("Cursor.updateGridCursor")
    -- blank previous update's tile(s) first
    for addr,tile in pairs(Cursor.tiles) do
        g_World.layers.cursor.grid:setTileValue(tile.x, tile.y, 0)
    end
    
	if Cursor.tempCommand then
		Cursor.tempCommand:setCommandVisible(false,true)
        Cursor.tempCommand = nil
	end
    
    -- recalc Cursor.tiles
    local bDragging = Cursor._updateDragArea(cursorX, cursorY, curStartX, curStartY, mode)
    
    local cursorMode = Cursor.modes[GameRules.currentMode]
    if not cursorMode then 
        Profile.leaveScope("Cursor.updateGridCursor")
        return 
    end

    if cursorMode.customClearFunction then
        Profile.enterScope("Cursor.customClearFunction")
        cursorMode.customClearFunction()
        Profile.leaveScope("Cursor.customClearFunction")
    end
    
    local tValid={}
    local tInvalid={}
    local wx,wy = Renderer.getWorldFromCursor(cursorX, cursorY)
    if cursorMode.customMoveFunction then
        local addr = next(Cursor.tiles)
        if addr then
            local coord=Cursor.tiles[addr]
            local tUpdatedValid,tUpdatedInvalid = cursorMode.customMoveFunction(coord.x,coord.y,wx,wy)
            if tUpdatedValid then
                tValid=tUpdatedValid
                tInvalid=tUpdatedInvalid
            end
        end
    elseif cursorMode.test then
        local addr = next(Cursor.tiles)
        if addr then
            local coord=Cursor.tiles[addr]
            if cursorMode.test(coord.x,coord.y,wx,wy) then
                tValid[addr] = {x=coord.x,y=coord.y,addr=addr}
            else
                tInvalid[addr] = {x=coord.x,y=coord.y,addr=addr}
            end
        end
    elseif cursorMode.command then
        local tTiles = Cursor.tiles
        if cursorMode.command == CommandObject.COMMAND_BUILD_ENVOBJECT and GameScreen.bFlipProp and cursorMode.param and EnvObject.canFlipX(cursorMode.param()) then
            for addr,coord in pairs(tTiles) do
                coord.bFlipX = GameScreen.bFlipProp
            end
        end

        Cursor.tempCommand = CommandObject.getCommandFromDragOperation(cursorMode.command, tTiles, (cursorMode.param and cursorMode.param(Cursor.tiles,wx,wy,Cursor.bDrag)), GameRules.currentMode, Cursor.bDrag)
        tValid,tInvalid = Cursor.tempCommand.tTiles,Cursor.tempCommand.tInvalidTiles
    end

    if Cursor.tempCommand then
        --[[
	if Cursor.tempCommand and (Cursor.tempCommand.commandAction == CommandObject.COMMAND_BUILD_ENVOBJECT 
            or Cursor.tempCommand.commandAction == CommandObject.COMMAND_VAPORIZE
            or Cursor.tempCommand.commandAction == CommandObject.COMMAND_BUILD_TILE) then
            ]]--
		Cursor.tempCommand:setCommandVisible(true,true)
	-- hide grid cursor for some modes
	elseif not cursorMode.hideGrid then
        Profile.enterScope("Cursor.drawTiles")
        Cursor.drawTiles(tValid, true,true)
        Cursor.drawTiles(tInvalid, false,true)
        Profile.leaveScope("Cursor.drawTiles")
	end

    if GameRules.currentMode == GameRules.MODE_INSPECT and GameRules.inEditMode and bMouseDown then
        if Cursor.currentDragTarget and bDragging then
            local wx,wy = Renderer.getWorldFromCursor(cursorX, cursorY)
            Cursor.currentDragTarget:setLoc(wx,wy)
        else
            local rObjTarget = g_GuiManager.getSelected(ObjectList.ENVOBJECT)
            if rObjTarget then
                Cursor.currentDragTarget = rObjTarget
            end
        end
        --[[
        local rObjTarget = g_GuiManager._getTargetAt(wx,wy)
        if rObjTarget and ObjectList.getObjType(rObjTarget) == ObjectList.ENVOBJECT then
        ]]--
    else
        Cursor.currentDragTarget = nil
    end
    Profile.leaveScope("Cursor.updateGridCursor")
end

function Cursor.modeChanging(oldMode,newMode)
    local cursorMode = Cursor.modes[oldMode]
    if not cursorMode then return end
    if cursorMode.customClearFunction then
        cursorMode.customClearFunction()
    end
end

function Cursor.drawTiles(tTiles, bValid, bDraw, bNeutral) 
	local spriteIndex = g_World.visualTiles.cursor_dragbox.index
    local color
    if bValid then color = Gui.GREEN else color = Gui.RED end
	-- "neutral" color for other viz like turret range
	if bNeutral then color = Gui.AMBER end
    if not bDraw then spriteIndex = 0 end
	
	-- highlight affected tiles
	for i,tile in pairs(tTiles) do
		g_World.layers.cursor.grid:setTileValue(tile.x, tile.y, spriteIndex)
		g_World.layers.cursor.grid:setTileColor(tile.x, tile.y, unpack(color))
	end
	
	-- highlight current cursor X and Y axes
	if not GameRules.isBuildMode(GameRules.currentMode) then
		return
	end
	local bg = g_World.layers.buildGrid.grid
	local empty = g_World.visualTiles.build_grid_square.index
	local bright = g_World.visualTiles.build_grid_square_bright.index
	local brightX = g_World.visualTiles.build_grid_square_bright_xaxis.index
	local brightY = g_World.visualTiles.build_grid_square_bright_yaxis.index
    bg:fill(empty)
    local cx, cy = g_World._getTileFromCursor(GameRules.cursorX, GameRules.cursorY)
    local sqx, sqy = GridUtil.CalculateIsoToSquare(cx, cy)
    for x = 1, GridUtil.GetMaxSquareCoordX() do
        local newIsoX, newIsoY = GridUtil.SquareToIso(x, sqy)
        if newIsoX and newIsoY then
            bg:setTile(newIsoX, newIsoY, brightX)
        end
    end
    for y = 1, GridUtil.GetMaxSquareCoordY(sqx) do
        local newIsoX, newIsoY = GridUtil.SquareToIso(sqx, y)
        if newIsoX and newIsoY then
            bg:setTile(newIsoX, newIsoY, brightY)
        end
    end
end

function Cursor._updateDragArea(cursorX, cursorY, curStartX, curStartY, mode)
    -- iterate over each square in drag area, building Cursor.tiles and
    -- noting which tiles are valid to build on, possibly invalidating the
    -- entire drag operation in some cases.
    -- various build tools use this information, reducing code complexity.
    local cursorMode = Cursor.modes[mode]
    if not cursorMode then 
        return 
    end
        Profile.enterScope("Cursor.updateDragArea")

    local wx,wy = Renderer.getWorldFromCursor(cursorX, cursorY)
    local tileX, tileY = g_World._getTileFromWorld(wx,wy)
    --local bInBounds = g_World.isInTileBounds(tileX,tileY)
    --tileX,tileY = g_World.clampTileToBounds(tileX,tileY) -- clamp extents
    local dragging = curStartX >= 0 and curStartY >= 0
    local tileStartX, tileStartY = tileX, tileY
    Cursor.tiles = {}
    Cursor.bDrag = false
    local tBoxTiles = {}
    if cursorMode.customSelector then
        assert(not cursorMode.allowDrag)
        tileX,tileY = cursorMode.customSelector(wx,wy)
        local addr = g_World.pathGrid:getCellAddr(tileX,tileY)
        tBoxTiles[addr] = {x=tileX, y=tileY, wall=g_World.countsAsWall(g_World._getTileValue(tileX, tileY)), addr=addr}
    -- only drag in certain modes
    elseif dragging and cursorMode.allowDrag then --and bInBounds then
        tileStartX, tileStartY = g_World._getTileFromCursor(curStartX, curStartY)
        if tileStartX > 1 and tileStartY > 1 then --and tileX > 1 and tileY > 1 then
            local x1,y1 = tileStartX,tileStartY
            --x1,y1 = g_World.clampTileToBounds(x1,y1) -- clamp extents
            local x2,y2 = tileX,tileY

            if x1 ~= x2 or y1 ~= y2 then
                Cursor.bDrag = true
            end
            
            tBoxTiles = GridUtil.GetTilesForIsoRectangle(x1,y1,x2,y2)
            if GameRules.currentMode == GameRules.MODE_BUILD_FLOOR then
                for addr,tile in pairs(tBoxTiles) do
                    if tBoxTiles[addr].edge then
                        tBoxTiles[addr].edge = false
                    end
                end
            end
            -- get tiles in a line if wall building
            if GameRules.currentMode == GameRules.MODE_BUILD_WALL then
                tBoxTiles = GridUtil.GetLongestTileRow(tBoxTiles, x1, y1, x2, y2)
            end
        end
    else
        -- start list with cursor's tile
        local addr = g_World.pathGrid:getCellAddr(tileX,tileY)
        tBoxTiles[addr] = {x=tileX, y=tileY, wall=g_World.countsAsWall(g_World._getTileValue(tileX, tileY)), addr=addr}
    end


    Cursor.tiles = tBoxTiles

        Profile.leaveScope("Cursor.updateDragArea")

    return dragging
end

function Cursor.getDragSize()
	local worldLayer = g_World.getWorldRenderLayer()
	local x1,y1 = worldLayer:wndToWorld(GameRules.startDragX, GameRules.startDragY)
	local pdx, pdy = GameRules.prevDragX[DFInput.MOUSE_LEFT], GameRules.prevDragY[DFInput.MOUSE_LEFT]
	-- if we haven't clicked left mouse this session, prevDrag won't have a number for us
	if not pdx then
		return 0,0
	end
	local x2,y2 = worldLayer:wndToWorld(pdx, pdy)
	-- corners in tile coords, subtract to get dimensions
	x1,y1 = g_World._getTileFromWorld(x1,y1)
	x2,y2 = g_World._getTileFromWorld(x2,y2)
	local tCorners = GridUtil.GetRectCorners(x1, y1, x2, y2)
	local width = tCorners.leftY - tCorners.bottomY + 1
	local height = tCorners.topY - tCorners.leftY + 1
	return width, height
end

function Cursor.damageTile(tx,ty,wx,wy)
    g_World.damageTile(tx, ty, 1, { nDamage = 100 })
end

function Cursor.placeNewCharacter(tx,ty,wx,wy)
    local CharacterManager=require('CharacterManager')
    local nFactionBehavior = GameRules.currentModeParam
    local tData = { tStats={  }, tStatus={ } }
    local nTeam = nil
    if nFactionBehavior == Character.FACTION_BEHAVIOR.Citizen then
        nTeam = Character.TEAM_ID_PLAYER
    elseif nFactionBehavior == Character.FACTION_BEHAVIOR.Friendly then
        nTeam = Character.TEAM_ID_DEBUG_FRIENDLY
    elseif nFactionBehavior == Character.FACTION_BEHAVIOR.EnemyGroup then
        nTeam = Character.TEAM_ID_DEBUG_ENEMYGROUP
    elseif nFactionBehavior == Character.FACTION_BEHAVIOR.Monster then
        nTeam = Character.TEAM_ID_DEBUG_MONSTER
    elseif nFactionBehavior == Character.FACTION_BEHAVIOR.KILLBOT then
        nTeam = Character.TEAM_ID_DEBUG_MONSTER
    else
        assertdev(false)
        nTeam = Character.TEAM_ID_PLAYER
    end

    local bSpace = g_World._getTileValue(tx,ty) == g_World.logicalTiles.SPACE

    if nFactionBehavior == Character.FACTION_BEHAVIOR.Monster then
        tData.tStats.nRace = Character.RACE_MONSTER
        tData.tStats.sName = 'DebugMonster'
    elseif nFactionBehavior == Character.FACTION_BEHAVIOR.EnemyGroup then
        tData.tStats.nJob = Character.RAIDER
        tData.tStats.sName = 'Raider'
        tData.tStats.nChallengeLevel = require('GameEvents.Event').getChallengeLevel()
        if bSpace then
            tData.tStatus.bSpacewalking = true
        end
	-- semi-hack: killbots belong in enemygroup, but a custom faction is the
	-- easiest way to get them passed to placeNewCharacter
    elseif nFactionBehavior == Character.FACTION_BEHAVIOR.KillBot then
        tData.tStats.nRace = Character.RACE_KILLBOT
        tData.tStats.sName = 'KillBot'
    else
        if bSpace then
            tData.tStatus.bSpacewalking = true
        end
	end

    local range = 0 --g_World.tileWidth * 10
    for i=1,1 do
        local rChar = CharacterManager.addNewCharacter(wx+math.random(-range,range),wy+math.random(-range,range), tData,nTeam)
        rChar:updateAI(.1)
    end
end

function Cursor._getDemolishTarget(wx,wy,bDrag)
    if not bDrag then
        local rObjTarget = g_GuiManager._getTargetAt(wx,wy)
        if rObjTarget and ObjectList.getObjType(rObjTarget) == ObjectList.ENVOBJECT then
            return rObjTarget
        end
    end
    return nil
end

function Cursor._getBuildEnvObjectTarget(wx,wy,bDrag)
    if not bDrag then
        local rObjTarget = g_GuiManager._getTargetAt(wx,wy)
        if rObjTarget and ObjectList.getObjType(rObjTarget) == ObjectList.ENVOBJECT then
            return rObjTarget.tag
        end
    end
    return -1
end

Cursor.modes=
{
    [GameRules.MODE_INSPECT]={
		hideGrid=true,
        custom=function(tx,ty,wx,wy) 
            if g_GuiManager.inspectMode() then
                g_GuiManager.inspectTouch(wx,wy)
            end
        end,
    },
    [GameRules.MODE_PICK]={
		hideGrid=true,
        custom=function(tx,ty,wx,wy) 
            g_GuiManager.pickTouch(wx,wy)
        end,
    },
    [GameRules.MODE_MINE]={
        command=CommandObject.COMMAND_MINE,
        allowDrag=true,
    },
    [GameRules.MODE_CANCEL_COMMAND]={
        command=CommandObject.COMMAND_CANCEL,
        allowDrag=true,
        param=function() return GameRules.currentModeParam end,
    },
    [GameRules.MODE_VAPORIZE]={
        --test=Cursor.canVaporize,
        command=CommandObject.COMMAND_VAPORIZE,
        allowDrag=true,
        param=function() return -1 end,
    },
    [GameRules.MODE_DEMOLISH]={
        --test=Cursor.canVaporize,
        command=CommandObject.COMMAND_DEMOLISH,
        allowDrag=true,
        param=function(tTiles,wx,wy,bDrag) return Cursor._getDemolishTarget(wx,wy,bDrag) end
    },
    [GameRules.MODE_BUILD_ROOM]={
        command=CommandObject.COMMAND_BUILD_TILE,
        allowDrag=true,
    },
    [GameRules.MODE_BUILD_WALL]={
        command = CommandObject.COMMAND_BUILD_TILE,
        allowDrag=true,
        param = function() return g_World.logicalTiles.WALL end,
    },
    [GameRules.MODE_BUILD_FLOOR]={
        command = CommandObject.COMMAND_BUILD_TILE,
        allowDrag=true,
    },
    [GameRules.MODE_BUILD_DOOR]={
        command = CommandObject.COMMAND_BUILD_ENVOBJECT,
        param = function() return GameRules.currentModeParam end,
        customSelector = function(wx,wy)
            local rWall = g_GuiManager._getTargetAt(wx,wy,'wall')
            if rWall then
                if not rWall.tx then
                    print('huh')
                else
                    return rWall.tx,rWall.ty
                end
            else
                return g_World._getTileFromWorld(wx,wy)
            end
        end,
    },
    [GameRules.MODE_MAKE_CHARACTER]={
        test=function(tx,ty) return (g_World.canBuildWall(tx,ty, g_World.logicalTiles.WALL) and CommandObject.TILE_VALID) or CommandObject.TILE_INTERRUPT end,
        custom=Cursor.placeNewCharacter,
    },
    [GameRules.MODE_DAMAGE_WORLD_TILE]={
        test=function(tx,ty) local tile=g_World._getTileValue(tx, ty) return ((g_World.countsAsFloor(tile) or tile == g_World.logicalTiles.WALL or tile == g_World.logicalTiles.DOOR) and CommandObject.TILE_VALID) or CommandObject.TILE_INTERRUPT end,
        custom=Cursor.damageTile,
    },
    [GameRules.MODE_PLACE_ASTEROID]={
        custom=function(tx,ty)
            require('Asteroid').placeAsteroid(tx,ty)
            require('Room').updateDirty()
        end,
        allowDrag=true,
    },
    [GameRules.MODE_DELETE_CHARACTER]={
        custom=function(tx,ty,wx,wy) GameRules.deleteCharacter(wx,wy) end,
    },
    [GameRules.MODE_PLACE_WORLDOBJECT]={
        hideGrid=true,
        customMoveFunction=function(tx,ty,wx,wy) 
            require('WorldObjects.WorldObject').setGhostCursor(tx,ty,GameRules.currentModeParam,GameScreen.bFlipProp)
        end,
        customClearFunction=function()
            require('WorldObjects.WorldObject').clearGhostCursor()
        end,
        custom=function(tx,ty,wx,wy) 
            if GameRules.currentModeParam == 'BreachShip' then
                local bs = require('WorldObjects.BreachShip').new(wx, wy, nil, Character.TEAM_ID_DEBUG_ENEMYGROUP)
                --local tx,ty = require('EventController').getIndoorTarget(bRequireSafeAndPathable)
            end
        end,
    },
    [GameRules.MODE_PLACE_PROP]={
        --command = CommandObject.COMMAND_BUILD_ENVOBJECT,
        --param = function() return GameRules.currentModeParam end,
        hideGrid=true,
        customMoveFunction=function(tx,ty,wx,wy) 
            return require('Room').createGhostCursor(tx,ty,GameRules.currentModeParam,GameScreen.bFlipProp)
        end,
        customClearFunction=function()
            require('Room').clearGhostCursor()
        end,
        custom=function(tx,ty,wx,wy) 
            if GameRules.inEditMode then
                EnvObject.createEnvObject(GameRules.currentModeParam,wx,wy,GameScreen.bFlipProp,nil,true)
            else
				local tObjectData = EnvObject.getObjectData(GameRules.currentModeParam)
                local bAllow,newTX,newTY = require('Room').attemptAddPropGhostAt(tx,ty,1,GameRules.currentModeParam,GameScreen.bFlipProp) 
                if not bAllow then
                    SoundManager.playSfx("disallow")
                else
                    if tObjectData.placeSound then 
                        SoundManager.playSfx(tObjectData.placeSound)
                    end
                    -- "auto-zone" unzoned room if zone-specific obj placed
                    local rRoom = require('Room').getRoomAtTile(newTX,newTY,1)
                    if rRoom and tObjectData.zoneName and rRoom:getZoneName() == 'PLAIN' then
                        rRoom:setZone(tObjectData.zoneName)
                    end
                end
            end
        end,
        customSelector = function(wx,wy)
            local sPropName = GameRules.currentModeParam
            local tData = EnvObject.getObjectData(sPropName)
            local tx,ty = g_World._getTileFromWorld(wx,wy)
            return tx,ty
        end,
    },
    [GameRules.MODE_BEACON]={
        hideGrid=true,
        test=function(tx,ty,wx,wy) 
            local rTarget = g_GuiManager._getTargetAt(wx, wy)
            if rTarget and rTarget.tag and rTarget.tag.objType == ObjectList.CHARACTER then
                return g_ERBeacon:showAtWorldPos(wx,wy) 
            else
                tx,ty = g_World._getTileFromWorld(wx,wy)
                return g_ERBeacon:showAtTile(tx,ty) 
            end
        end,
        custom=function(tx,ty,wx,wy) 
            local rTarget = g_GuiManager._getTargetAt(wx, wy)
            if rTarget and rTarget.tag and rTarget.tag.objType == ObjectList.CHARACTER then
                return g_ERBeacon:attachTo(rTarget)
            else
                tx,ty = g_World._getTileFromWorld(wx,wy)
                return g_ERBeacon:placeAt(tx,ty)
            end
        end,
    },
    [GameRules.MODE_PLACE_SPAWNER]={
        command = CommandObject.COMMAND_BUILD_ENVOBJECT,
        param = function() return 'Spawner' end,
    },
}

return Cursor
