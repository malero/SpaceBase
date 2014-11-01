local Class=require('Class')
local GameRules=require('GameRules')
local DFMath = require('DFCommon.Math')

-- Singleton utility class.
-- Primarily operates on the world grid, which actually stores the data.

local Asteroid = {}

-- low, med, high. Lerps between MIN & MAX based on the seed
Asteroid.MIN_NUM_TO_SPAWN = {16,24,32}
Asteroid.MAX_NUM_TO_SPAWN = {24,32,40}
-- low, med, high, +/-
Asteroid.VARIANCE_PER_LEVEL = {1, 2, 3}
Asteroid.THRESHOLD_MED_LOW = 0.33 -- 0 to 1, must be lower than THRESHOLD_MED_HIGH
Asteroid.THRESHOLD_MED_HIGH = 0.66 -- 0 to 1

Asteroid.NUM_DECAY_LEVELS = 2
Asteroid.spriteNames={
    'asteroid01',
    'asteroid01_b',
}
-- cutaway versions: should have same # of entries as spriteNames table above
Asteroid.cutawaySpriteNames={
    'asteroid01_bottom',
    'asteroid01_bottom',
}

function Asteroid.spawnAsteroids(asteroidSeed)
    asteroidSeed = asteroidSeed or math.random()
    
    local nThreshold = 1 -- low = 1, med = 2, high = 3
    if asteroidSeed > Asteroid.THRESHOLD_MED_HIGH then nThreshold = 3
    elseif asteroidSeed > Asteroid.THRESHOLD_MED_LOW then nThreshold = 2 end
    
    local t = asteroidSeed / math.max(Asteroid.THRESHOLD_MED_LOW, 0.01)
    if nThreshold == 2 then t = (asteroidSeed - Asteroid.THRESHOLD_MED_LOW) / (Asteroid.THRESHOLD_MED_HIGH - Asteroid.THRESHOLD_MED_LOW)
    elseif nThreshold == 3 then t = (asteroidSeed - Asteroid.THRESHOLD_MED_HIGH) / (1-Asteroid.THRESHOLD_MED_HIGH) end
    
    local numToSpawn = DFMath.lerp(Asteroid.MIN_NUM_TO_SPAWN[nThreshold], Asteroid.MAX_NUM_TO_SPAWN[nThreshold], t)
    numToSpawn = DFMath.roundDecimal(numToSpawn + DFMath.lerp(-Asteroid.VARIANCE_PER_LEVEL[nThreshold], Asteroid.VARIANCE_PER_LEVEL[nThreshold], math.random()))
    for i=1,numToSpawn do
        local tModuleData = GameRules.loadRandomFromSet("asteroidModules")
        local tileX,tileY = math.random(1,g_World.width-tModuleData.tileWidth),math.random(1,g_World.height-tModuleData.tileHeight)
        GameRules.placeModule(tModuleData, tileX, tileY)
    end
end

function Asteroid.getSpriteName(logicalValue)
    if logicalValue >= g_World.logicalTiles.ASTEROID_VALUE_START and logicalValue < g_World.logicalTiles.ASTEROID_VALUE_START + Asteroid.NUM_DECAY_LEVELS then
		local index = logicalValue - g_World.logicalTiles.ASTEROID_VALUE_START + 1
		if GameRules.cutawayMode then
			return Asteroid.cutawaySpriteNames[index]
		else
			return Asteroid.spriteNames[index]
		end
    end
end

-- Edit-mode command. Kills fog in the area.
function Asteroid.placeAsteroid(tx,ty)
    g_World._setTile(tx,ty,g_World.logicalTiles.ASTEROID_VALUE_START)
    g_World.pathGrid:clearTileFlag(tx, ty, MOAIGridSpace.TILE_DIM)
end

function Asteroid.isAsteroid(tileValue)
    if tileValue >= g_World.logicalTiles.ASTEROID_VALUE_START and tileValue <= g_World.logicalTiles.ASTEROID_VALUE_END then
        return true
    end
end

function Asteroid.vaporizeTile(tx,ty,tileValue,bCompletely)
    if tileValue >= g_World.logicalTiles.ASTEROID_VALUE_START and tileValue <= g_World.logicalTiles.ASTEROID_VALUE_END then
        local newVal
        if bCompletely then 
            newVal = g_World.logicalTiles.SPACE
        else
            newVal = tileValue+1
            if newVal >= g_World.logicalTiles.ASTEROID_VALUE_START+Asteroid.NUM_DECAY_LEVELS then
                newVal = g_World.logicalTiles.SPACE
            end
        end
        g_World._setTile(tx,ty,newVal)
        return true,newVal
    end
    return false,tileValue
end

return Asteroid
