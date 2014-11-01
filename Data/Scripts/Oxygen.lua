local Class=require('Class')
local World=require('World')
local GameRules=require('GameRules')
local DFUtil = require('DFCommon.Util')
local Character=require('CharacterConstants')

local Oxygen = 
{
    tGenerators={},
    profilerName='Oxygen',
}

Oxygen.TILE_MAX = DFOxygenGrid.OXYGEN_TILE_MAX

Oxygen.VACUUM_THRESHOLD = 50
Oxygen.VACUUM_THRESHOLD2 = Oxygen.VACUUM_THRESHOLD * Oxygen.VACUUM_THRESHOLD 
Oxygen.VACUUM_THRESHOLD_END = 40
Oxygen.VACUUM_THRESHOLD_END2 = Oxygen.VACUUM_THRESHOLD_END * Oxygen.VACUUM_THRESHOLD_END
Oxygen.VACUUM_VEC_RESET = 180
Oxygen.COLOR_LOW = {1,0,0}
Oxygen.COLOR_HIGH = {0,1,0}

if g_Config:getConfigValue("colorblind") then
    Oxygen.COLOR_LOW = {0,0,1}
    Oxygen.COLOR_HIGH = {0,1,0.86}
end

function Oxygen.addGenerator(wx,wy,amt)
    local tileX, tileY = World._getTileFromWorld(wx,wy)
    local tileAddr = World.oxygenGrid:getCellAddr(tileX, tileY)
    if Oxygen.tGenerators[tileAddr] and amt > 0 then
        Print(TT_Error, "Attempt to place duplicate generator at",tileX,tileY)
        return
    end
    World.oxygenGrid:getMOAIGrid():setGenerator(tileX,tileY,amt)
    if amt == 0 then amt = nil end
    Oxygen.tGenerators[tileAddr] = amt
end

function Oxygen.removeGenerator(wx,wy)
    local tileX, tileY = World._getTileFromWorld(wx,wy)
    local tileAddr = World.oxygenGrid:getCellAddr(tileX, tileY)
    if not Oxygen.tGenerators[tileAddr] then
        Print(TT_Error, "Attempt to remove nonexistent generator at",tileX,tileY)
        return
    end
    Oxygen.tGenerators[tileAddr] = nil
    World.oxygenGrid:getMOAIGrid():setGenerator(tileX,tileY,0)
end

function Oxygen.reset()
    if World.oxygenGrid then
        for addr,amt in pairs(Oxygen.tGenerators) do
            World.oxygenGrid:getMOAIGrid():setGenerator(addr,0)
        end
    end
    Oxygen.tGenerators = {}    
end

function Oxygen.getOxygenScore(tTiles,nTiles)
    local totalO2,averageO2
    assertdev(tTiles)
    if nTiles == 0 then return 0,0,0 end -- spaceroom
    totalO2 = World.oxygenGrid:getMOAIGrid():getTotalOxygen(tTiles)
    averageO2=totalO2/nTiles
    return averageO2,totalO2,averageO2
end

-- Returns an averaged-over-time vacuum vector for this tile.
-- @return vx,vy, magnitude
function Oxygen.getVacuumVec(wx,wy)
    local tx, ty = World._getTileFromWorld(wx,wy)
    return Oxygen._getVacuumVec(tx,ty)
end

function Oxygen._getVacuumVec(tx,ty)
    return World.oxygenGrid:getMOAIGrid():getVacuum(tx,ty)
end

function Oxygen.getOxygen(wx,wy)
    local tileX, tileY = World._getTileFromWorld(wx,wy)
    return World.oxygenGrid:getOxygen(tileX,tileY)
end

function Oxygen.setOxygen(wx,wy,amt)
    local tileX, tileY = World._getTileFromWorld(wx,wy)
    return World.oxygenGrid:setOxygen(tileX,tileY,amt)
end

function Oxygen.onTick( dtGame )
    World.oxygenGrid:getMOAIGrid():tick(dtGame)
end

return Oxygen
