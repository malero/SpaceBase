local DFMath = require("DFCommon.Math")
local Asteroid = require("Asteroid")
local ObjectList = require("ObjectList")

local GridUtil = {}

-- get the bounding box coords that contain a rectangle defined by top left and bottom right tile coordinates
function GridUtil.GetIsoBB(x1, y1, x2, y2)
	local x3,y3 = GridUtil.FindIsoTileIntersection(x1,y1,x2,y2,true)
    local x4, y4 = GridUtil.FindIsoTileIntersection(x1,y1,x2,y2,false)
    local tPoints = {}
    table.insert(tPoints, {x1,y1})
    table.insert(tPoints, {x2,y2})
    table.insert(tPoints, {x3,y3})
    table.insert(tPoints, {x4,y4})
    table.sort(tPoints, function(a,b) 
        if a[1] == b[1] then 
            if a[2] % 2 == 1 then
                if b[2] % 2 ~= 1 then
                    return true
                else 
                    return a[2] < b[2] 
                end
            elseif b[2] % 2 == 1 then 
                return false
            else 
                return a[2] < b[2]
            end
        end
        return a[1] < b[1] 
    end)
    local tBox = {}
    tBox[1] = tPoints[1]
    tBox[3] = tPoints[4]
    table.sort(tPoints, function(a,b) return a[2] < b[2] end)
    tBox[2] = tPoints[1]
    tBox[4] = tPoints[4]
	return tBox
end

-- call this whenever the shape of the world's grids change, it populates some tables so we can do fast grid
--  lookups when switching between rectangular and so-called "dumb ass" coordinate systems.
function GridUtil.PopulateTileLookup()
    GridUtil._IsoToSquareLookup = {}
    GridUtil._SquareToIsoLookup = {}

    for x=1,g_World.width do
        table.insert(GridUtil._IsoToSquareLookup, x, {})
        
        for y=1,g_World.height do
        
            local sqX, sqY = GridUtil.CalculateIsoToSquare(x, y)
        
            if nil == GridUtil._SquareToIsoLookup[sqX] then
                GridUtil._SquareToIsoLookup[sqX] = {}
            end
        
            GridUtil._IsoToSquareLookup[x][y] = {sqX, sqY}
            GridUtil._SquareToIsoLookup[sqX][sqY] = {x, y}
            
            local checkSqX, checkSqY = GridUtil.IsoToSquare(x,y)
            local tx, ty = GridUtil.SquareToIso(checkSqX, checkSqY)            
        end
    end
    
    -- validation checks
    --[[
    for x=1,g_World.width do
        for y=1,g_World.height do
            local sqX, sqY = GridUtil.IsoToSquare(x,y)
            local tx, ty = GridUtil.SquareToIso(sqX, sqY)
            if tx ~= x or ty ~= y then
                print("match is bad bro")
            end
        end
    end
    ]]--
end

-- lookup the iso coordinate from a square coordinate
function GridUtil.IsoToSquare(tx, ty)
    local coord = GridUtil._IsoToSquareLookup[tx]
    coord = coord and coord[ty]
    if coord then
        return coord[1], coord[2]
    end
end

-- reverse lookup from square space back to iso space
function GridUtil.SquareToIso(tx, ty)
    local coord = GridUtil._SquareToIsoLookup[tx]
    coord = coord and coord[ty]
    if coord then
        return coord[1], coord[2]
    end
end

function GridUtil.GetMaxSquareCoordX()
    local nMaxX = 0
    if GridUtil._SquareToIsoLookup then
        nMaxX = table.getn(GridUtil._SquareToIsoLookup)
    end
    return nMaxX
end

function GridUtil.GetMaxSquareCoordY(nSqX)
    local nMaxY = 0
    if GridUtil._SquareToIsoLookup and GridUtil._SquareToIsoLookup[nSqX] then
        for nVal, _ in pairs(GridUtil._SquareToIsoLookup[nSqX]) do
            if nVal > nMaxY then
                nMaxY = nVal
            end
        end
    end
    return nMaxY
end

-- safety checks if you want to loop over the grid but aren't sure if your value is in range
function GridUtil.CheckSquareToIsoValue(tx, ty)
    return nil ~= GridUtil._SquareToIsoLookup[tx] and nil ~= GridUtil._SquareToIsoLookup[tx][ty]
end

-- safety checks if you want to loop over the grid but aren't sure if your value is in range
function GridUtil.CheckIsoToSquareValue(tx, ty)
    return nil ~= GridUtil._SquareToIsoLookup[tx] and nil ~= GridUtil._SquareToIsoLookup[tx][ty]
end

-- check to see if two tiles in iso space have line of sight between them.
--  we do this by first figuring out the line, then iterating over the tiles to see if we
--  hit any walls.
function GridUtil.CheckLineOfSight(tx1, ty1, tx2, ty2, bWallsOnly)
    local tLineTiles = GridUtil.GetTilesForLine(tx1, ty1, tx2, ty2)
    
    local bClearPath = true
    
    for idx,coord in ipairs(tLineTiles) do
        local x = coord[1]
        local y = coord[2]
        
        -- this is a flavor choice, but we don't want to do wall checks for our end points
        --  because TECHNICALLY two walls facing eachother have line of sight
        if true ~= (x == tx1 and y == ty1) and true ~= (x == tx2 and y == ty2) then
            local tileValue = g_World._getTileValue(x,y)
            local rDoor = nil
            if tileValue == g_World.logicalTiles.DOOR then rDoor = ObjectList.getDoorAtTile(x,y) end
            if (bWallsOnly and tileValue == g_World.logicalTiles.WALL) or
               (not bWallsOnly and (tileValue == g_World.logicalTiles.WALL or Asteroid.isAsteroid(tileValue) or (rDoor and not rDoor:isOpen()))) then
                bClearPath = false
                break
            end
        end
    end
    
    return bClearPath
end

-- an example of a function that will operate amazingly on square coordinates.
--  takes iso tile locations and gives you back iso tile locations for all tiles
--  in a connecting line between two points.
function GridUtil.GetTilesForLine(tx1, ty1, tx2, ty2, bSquareInSquareOut)
    -- this is based on bresenham's line drawing algorithm
    
    local x1, y1
    local x2, y2
    if bSquareInSquareOut then
        x1, y1 = tx1, ty1
        x2, y2 = tx2, ty2
    else
        x1, y1 = GridUtil.IsoToSquare(tx1, ty1)
        x2, y2 = GridUtil.IsoToSquare(tx2, ty2)
    end
    
    local tLinePoints = {}
    if not x1 or not x2 then return tLinePoints end
    
    local delta_x = x2 - x1
    local ix = delta_x > 0 and 1 or -1
    delta_x = 2 * math.abs(delta_x)

    local delta_y = y2 - y1
    local iy = delta_y > 0 and 1 or -1
    delta_y = 2 * math.abs(delta_y)

    table.insert(tLinePoints, {x1, y1})

    local error
    
    if delta_x >= delta_y then
        error = delta_y - delta_x / 2

        while x1 ~= x2 do
            if (error >= 0) and ((error ~= 0) or (ix > 0)) then
                error = error - delta_x
                y1 = y1 + iy
            end

            error = error + delta_y
            x1 = x1 + ix

            table.insert(tLinePoints, {x1, y1})
        end
    else
        error = delta_x - delta_y / 2

        while y1 ~= y2 do
            if (error >= 0) and ((error ~= 0) or (iy > 0)) then
                error = error - delta_y
                x1 = x1 + ix
            end

            error = error + delta_x
            y1 = y1 + iy

            table.insert(tLinePoints, {x1, y1})
        end
    end

    if not bSquareInSquareOut then
        -- now convert from square tiles back to iso
        for i=1,#tLinePoints do
            local coord = tLinePoints[i]
            local tmpX, tmpY = GridUtil.SquareToIso(coord[1], coord[2])
            tLinePoints[i] = {tmpX, tmpY}
        end
    end
    
    return tLinePoints
end

-- actually calculate a square coordinate value given an iso tile location.
--  Also this is kind of slow, so you should really only use it if you're looking up
--  values that are outside of g_World.width/height
function GridUtil.CalculateIsoToSquare(tx,ty)
    local ns, we
    if ty % 2 == 0 then
        ns = tx+ty*.5
        we = g_World.width * .5 - ty*.5 + tx
    else
        ns = tx+ty*.5-.5
        we = g_World.width * .5 - ty*.5 + tx - .5
    end
    return ns,we
end

-- Analytically computes the intersection of two iso lines,
-- derived from the point-slope equation for a line.
-- Assumes that the first line has a negative slope
-- and the second line has a positive slope.
-- NOTE: this was originally in Docking, and is more specific than FindIsoTileIntersection below. Hopefully we can
--        consolidate them at some point.
function GridUtil.ComputeIsoIntersect(x1, y1, x2, y2)
    local x = (2 * x1 + y1 + 2 * x2 + -y2) / 4
    local y = (-2 * (x - x1)) + y1
    return math.floor(x+.5), math.floor(y+.5)
end

-- this function is now sort of a huge hack... internally it operates on world space diagonal lines,
--  while normally we only want to operate on tiles. Ideally we would just use ComputeIsoIntersect but
--  there are still some dependencies on how this thing works. Should refactor!
function GridUtil.FindIsoTileIntersection(x1,y1,x2,y2,bDownRightFirst)
    if x1 > x2 then
        local tx,ty = x1,y1
        x1,y1 = x2,y2
        x2,y2 = tx,ty
    end

    -- horrible hack... convert tiles to world to operate on world stuff.
    x1,y1 = g_World._getWorldFromTile(x1,y1)
    x2,y2 = g_World._getWorldFromTile(x2,y2)
    
    -- downward-right line from the left-most point.
    local x1p,y1p
    if bDownRightFirst then
        x1p,y1p = x1+g_World.tileWidth,y1-g_World.tileHeight
    else
        x1p,y1p = x1-g_World.tileWidth,y1-g_World.tileHeight
    end

    local x2p,y2p
    if bDownRightFirst then
        x2p,y2p = x2-g_World.tileWidth,y2-g_World.tileHeight
    else
        x2p,y2p = x2+g_World.tileWidth,y2-g_World.tileHeight
    end

    local xi,yi = DFMath.lineIntersection(x1,y1,x1p,y1p,x2,y2,x2p,y2p)
    assert(xi)
    
    -- undo the horrible hack and go back to tiles.
    xi,yi = g_World._getTileFromWorld(xi,yi)
    
    return xi,yi
end

function GridUtil.GetRectCorners(x1, y1, x2, y2)
	-- returns a table of a rect's corners
	local tBB = GridUtil.GetIsoBB(x1, y1, x2, y2)
    local tCorners = {}
	tCorners.leftX,tCorners.leftY = tBB[1][1],tBB[1][2]
    tCorners.bottomX,tCorners.bottomY = tBB[2][1],tBB[2][2]
    tCorners.rightX,tCorners.rightY = tBB[3][1],tBB[3][2]
    tCorners.topX,tCorners.topY = tBB[4][1],tBB[4][2]
	return tCorners
end

function GridUtil.GetLongestTileRow(tTiles, startX, startY, endX, endY)
	-- returns a list of tiles, pared-down to a single row/column
	-- based on tiles given and start/end defining range
	-- (used by Wall build tool)
	local newTiles = {}
	startX, startY = GridUtil.CalculateIsoToSquare(startX, startY)
	endX, endY = GridUtil.CalculateIsoToSquare(endX, endY)
	-- determine if X or Y dimension is larger
	local xLonger = math.abs(startX - endX) < math.abs(startY - endY)
	for addr,tile in pairs(tTiles) do
		local tx, ty = GridUtil.CalculateIsoToSquare(tile.x, tile.y)
		if xLonger and tx == startX then
			newTiles[addr] = tile
		elseif not xLonger and ty == startY then
			newTiles[addr] = tile
		end
	end
	return newTiles
end

-- get all the tiles for an iso metric rectangle
-- tTiles= { addr={x=tx,y=ty,edge=bEdge,addr=addr}, ... }
function GridUtil.GetTilesForIsoRectangle(x1, y1, x2, y2)
	local tCorners = GridUtil.GetRectCorners(x1, y1, x2, y2)
    local height = tCorners.topY - tCorners.leftY
    assert(height >= 0)
    assert(tCorners.leftX <= tCorners.bottomX)

	-- local vars for values this algo iterates
	local leftX, leftY = tCorners.leftX, tCorners.leftY
    local bYEdge = true
    local tTiles = {}
    while leftY >= tCorners.bottomY do
        local xOff,yOff = 0,0
        local bXEdge = true
        while yOff <= height do
			local tx,ty = leftX+xOff, leftY+yOff
            if g_World._isInBounds(tx,ty) then
                local addr = g_World.pathGrid:getCellAddr(tx, ty)
                tTiles[addr] = {x=tx, y=ty, edge=(bYEdge or bXEdge),addr=addr}
            end
			yOff = yOff+1
            if ((leftY + yOff) % 2) == 1 then
                xOff = xOff+1
            end
            bXEdge = yOff == height
        end
        leftY = leftY-1
        if ((leftY % 2) == 1) then
            leftX = leftX+1
        end
        bYEdge = leftY == tCorners.bottomY
    end

    return tTiles
end

-- get all the tiles for the outside edges of a circle. All tiles will be ~radius distance
--  from the center. Uses the midpoint circle algorithm.
function GridUtil.GetTilesForIsoCircleBorder(centerX, centerY, radius)
    
    local x0, y0 = GridUtil.IsoToSquare(centerX, centerY)
    
    local tPoints = {}
    
    local f = 1 - radius
    local ddF_x = 0
    local ddF_y = -2 * radius
    local x = 0
    local y = radius
    
    -- use hashing to avoid adding duplicates. kinda crummy but this might
    --  only get faster if we switch to C++.
    local function addPoint(tPoints, x, y)
    
        -- now convert from square tiles back to iso. We also need to remove duplicates from the table
        local key = x .. "_" .. y
        x,y = GridUtil.SquareToIso(x, y)
        if g_World._isInBounds(x,y) then
            tPoints[key] = {x=x, y=y}
        end
    end
    
    addPoint(tPoints, x0, y0 + radius)
    addPoint(tPoints, x0, y0 - radius)
    addPoint(tPoints, x0 + radius, y0)
    addPoint(tPoints, x0 - radius, y0)
    
    while x < y do
        if f >= 0 then 
            y = y - 1
            ddF_y = ddF_y + 2
            f = f + ddF_y
        end
        x = x + 1
        ddF_x = ddF_x + 2;
        f = f + ddF_x + 1;    

        addPoint(tPoints, x0 + x, y0 + y)
        addPoint(tPoints, x0 - x, y0 + y)
        addPoint(tPoints, x0 + x, y0 - y)
        addPoint(tPoints, x0 - x, y0 - y)
        addPoint(tPoints, x0 + y, y0 + x)
        addPoint(tPoints, x0 - y, y0 + x)
        addPoint(tPoints, x0 + y, y0 - x)
        addPoint(tPoints, x0 - y, y0 - x)
    end
    
    local tHashedPoints = tPoints
    tPoints = {}
    for idx,point in pairs(tHashedPoints) do
        table.insert(tPoints, point)
    end
    
    return tPoints
end

-- get all the tiles for a filled circle
function GridUtil.GetTilesForIsoCircle(centerX, centerY, radius)
    
    local topleftX = math.floor(centerX - radius)
    local topleftY = centerY
    
    local bottomrightX = math.ceil(centerX + radius)
    local bottomrightY = centerY
    
    -- TODO: actually get us a circle (for now just return a rectangle, whatever)
    return GridUtil.GetTilesForIsoRectangle(topleftX, topleftY, bottomrightX, bottomrightY)
end

-- since you can't just do normal distance formula with this crazy
--  iso grid (the odd row system means that y tiles are "twice
--  as close" as x tiles), we need a better equation.
function GridUtil.GetTileDistance(x1, y1, x2, y2)
    x1,y1 = GridUtil.IsoToSquare(x1,y1)
    x2,y2 = GridUtil.IsoToSquare(x2,y2)
    local dx,dy = x2-x1,y2-y1
    dx,dy=dx*dx,dy*dy
    return math.sqrt(dx+dy)
end

-- useful if you're doing a whole bunch of these checks, removes a sqrt call.
function GridUtil.GetTileDistanceSquared(x1, y1, x2, y2)
    x1,y1 = GridUtil.IsoToSquare(x1,y1)
    x2,y2 = GridUtil.IsoToSquare(x2,y2)
    local dx,dy = x2-x1,y2-y1
    dx,dy=dx*dx,dy*dy
    return dx+dy
end

function GridUtil.OffsetAddrByWorld(addr,worldXOff,worldYOff)
    local tx, ty = g_World.pathGrid:cellAddrToCoord(addr)        
    local wx,wy = g_World._getWorldFromTile(tx,ty) 
    wx,wy=wx+worldXOff,wy+worldYOff
    addr = g_World.pathGrid:getCellAddr(tx,ty)
    return addr
end

return GridUtil
