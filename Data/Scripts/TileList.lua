local Class=require('Class')
local World=require('World')
local CommandObject=require('Utility.CommandObject')

local TileList = Class.create()

function TileList:init()
    self.tTiles={}
end

function TileList:addCoord(tx,ty)
    local addr = g_World.pathGrid:getCellAddr(tx, ty)
    self.tTiles[addr] = {x=tx,y=ty}
    self.len=self.len+1
end

function TileList:addAddr(addr)
    local tx,ty = g_World.pathGrid:cellAddrToCoord(addr)
    self.tTiles[addr] = {x=tx,y=ty}
    self.len=self.len+1
end

function TileList:add3(addr,tx,ty)
    self.tTiles[addr] = {x=tx,y=ty}
    self.len=self.len+1
end



return TileList
