local Class=require('Class')
local DFUtil = require("DFCommon.Util")
local DFMath = require("DFCommon.Math")
local EnvObject=require('EnvObjects.EnvObject')
local GridUtil=require('GridUtil')
local Cursor = require('UI.Cursor')

local AirScrubber = Class.create(EnvObject, MOAIProp.new)

function AirScrubber:init(sName, wx, wy, bFlipX, bForce, tSaveData, nTeam)
    EnvObject.init(self,sName, wx, wy, bFlipX, bForce, tSaveData, nTeam)
end

function AirScrubber:setLoc(x,y,nLevel)
    EnvObject.setLoc(self,x,y,nLevel)
    local tx,ty,tw = self:getTileLoc()
    local nRange = self.tData.nRange
	-- determine affected tiles
    self.tTiles = {}
	local gtx,gty = GridUtil.IsoToSquare(tx, ty)
	local minX, minY = gtx - nRange, gty - nRange
	local maxX, maxY = gtx + nRange, gty + nRange
	for x=minX,maxX do
		for y=minY,maxY do
			-- in range?
			if DFMath.distance2D(gtx, gty, x, y) <= nRange then
				local bx,by = GridUtil.SquareToIso(x, y)
				local addr = bx and by and g_World.pathGrid:getCellAddr(bx, by)
                if addr then
                    self.tTiles[addr] = {x=bx, y=by}
                end
			end
		end
	end
end

function AirScrubber:hover(hoverTime)
	EnvObject.hover(self,hoverTime)
	-- show radius in red if deactivated
	local bGreenNotRed = self:isFunctioning()
	-- clear any tiles that might be on from previous frames
	g_World.layers.cursor.grid:fill(0)
	-- draw coverage area as yellow tiles
	Cursor.drawTiles(self.tTiles, bGreenNotRed, true, false)
end

function AirScrubber:unHover()
	EnvObject.unHover(self)
	Cursor.drawTiles(self.tTiles, false, false)
end

return AirScrubber

