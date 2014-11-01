local Class=require('Class')
local Room=require('Room')
local Base = require('Base')
local ObjectList=require('ObjectList')
local GameRules=require('GameRules')
local GridUtil=require('GridUtil')
local DFUtil = require('DFCommon.Util')
local SoundManager = require('SoundManager')

local Fire = {}

Fire.DISABLED = false

-- seconds between ticks
Fire.TIME_BETWEEN_UPDATES = 1
Fire.SPREAD_PROBABILITY_DEFAULT = 0.075
Fire.SPREAD_PROBABILITY_LOW = 0.025
Fire.SPREAD_PROBABILITY_HIGH = 0.15
Fire.CITIZEN_SPREAD_PROBABILITY_DEFAULT = 0.2
Fire.CITIZEN_SPREAD_PROBABILITY_LOW = 0.1
Fire.CITIZEN_SPREAD_PROBABILITY_HIGH = 0.3
Fire.DAMAGE_HEALTHY_TILE_PROBABILITY = .85
Fire.DAMAGE_HURT_TILE_PROBABILITY = .15
Fire.OXYGEN_PER_SECOND = 200
Fire.LOW_OXYGEN_THRESHOLD = 500
Fire.NO_OXYGEN_THRESHOLD = 25
Fire.LOW_OXYGEN_DOUSE_RATE = 10
Fire.NO_OXYGEN_DOUSE_RATE = 100

-- Fire intensity
Fire.INTENSITY_DEFAULT = 10
Fire.INTENSITY_THRESHOLD_LOW = 5
Fire.INTENSITY_THRESHOLD_HIGH = 15

-- "heat" of a tile; at >= 1 it gets a flame.
Fire.tTiles = {}
-- Flame refs.
Fire.tFlames = {}
Fire.timeUntilNextUpdate = Fire.TIME_BETWEEN_UPDATES
Fire.wasOnFire = false

function Fire.reset()
    for addr,rFlame in pairs(Fire.tFlames) do
        rFlame:remove()
    end
    Fire.tFlames = {}
    Fire.tTiles = {}
    Fire.timeUntilNextUpdate = Fire.TIME_BETWEEN_UPDATES    
end

-- Bookkeeping function. Call rFlame:extinguish instead.
function Fire._flameRemoved(wx,wy,flame,flameAttachedTo)
    if not flameAttachedTo then
        local tileX, tileY = g_World._getTileFromWorld(wx,wy)
        local addr = g_World.pathGrid:getCellAddr(tileX, tileY)
        Fire.tTiles[addr] = nil

        if Fire.tFlames[addr] ~= flame then
            Print(TT_Error, 'Bad flame bookkeeping.')
            return
        end

        Fire.tFlames[addr] = nil
    end
end

function Fire.extinguish(wx,wy)
    local tileX, tileY = g_World._getTileFromWorld(wx,wy)
    Fire.extinguishTile(tileX, tileY)
end

function Fire.isFireAtWorld(wx,wy)
    local tileX, tileY = g_World._getTileFromWorld(wx,wy)
    local addr = g_World.pathGrid:getCellAddr(tileX, tileY)
    return Fire.tFlames[addr] ~= nil
end
    
function Fire.extinguishTile(tileX, tileY)
    local addr = g_World.pathGrid:getCellAddr(tileX, tileY)
    local rFlame = Fire.tFlames[addr]
    if rFlame then rFlame:extinguish() end
    local rRoom = Room.getRoomAtTile(tileX,tileY,1)
    if rRoom then
        rRoom:updateHazardStatus()
    end
end

function Fire.douseTile(tileX, tileY, nDouseAmount)
    local addr = g_World.pathGrid:getCellAddr(tileX, tileY)
    local rFlame = Fire.tFlames[addr]
    local bExtinguished = false
    if rFlame then
        if rFlame:douse(nDouseAmount) then
            Fire.extinguishTile(tileX, tileY)
            bExtinguished = true
        end
    else
        bExtinguished = true
    end
    
    return bExtinguished
end

function Fire.getNearbyFire(wx,wy)
    local tileX, tileY = g_World._getTileFromWorld(wx,wy)
    for i=1,9 do
        local tx,ty = g_World._getAdjacentTile(tileX,tileY,i)
        local addr = g_World.pathGrid:getCellAddr(tx, ty)
        if Fire.tTiles[addr] then
            return g_World._getWorldFromTile(tx,ty) 
        end
    end
end

function Fire.onTick( dt )
    if Fire.DISABLED then
        return
    end
   
    Fire.timeUntilNextUpdate = Fire.timeUntilNextUpdate - dt
    if Fire.timeUntilNextUpdate > 0 then
        return
    else
        Fire.timeUntilNextUpdate = Fire.TIME_BETWEEN_UPDATES
    end

    local isOnFire = false
    local numX, numY, sumX, sumY = 0, 0, 0, 0
    for addr,_ in pairs(Fire.tTiles) do
        local rFlame = Fire.tFlames[addr]
        
        if rFlame then
            isOnFire = true
            local bExtinguished = false
            local tileX, tileY = g_World.pathGrid:cellAddrToCoord(addr)        
            numX = numX + 1
            numY = numY + 1
            sumX = sumX + tileX
            sumY = sumY + tileY
            
            local oxygen = g_World.oxygenGrid:getOxygen(tileX,tileY)
            if oxygen < Fire.NO_OXYGEN_THRESHOLD then bExtinguished = Fire.douseTile(tileX, tileY, Fire.NO_OXYGEN_DOUSE_RATE*dt)
            elseif oxygen < Fire.LOW_OXYGEN_THRESHOLD then bExtinguished = Fire.douseTile(tileX, tileY, Fire.LOW_OXYGEN_DOUSE_RATE*dt) end
            
            if not bExtinguished then
                if math.random() < Fire:getSpreadProbability(rFlame.nIntensity) then
                    local tx,ty = g_World._getAdjacentTile(tileX,tileY,math.random(2,9))
                    if Fire._attemptFireTile(tx,ty) then
                        return 
                    end
                end
                if math.random() < Fire:getCitizenSpreadProbability(rFlame.nIntensity) then
                    local CharacterManager = require('CharacterManager')
                    local tCharacters = CharacterManager.getCharacters()
                    for _,char in pairs(tCharacters) do
                        local charX, charY = g_World._getTileFromWorld(char:getLoc())
                        if not char:isDead() and not char.onFire and tileX == charX and tileY == charY then
                            char:catchFire()
                        end
                    end
                end
                
                -- different probabilities to damage an undamaged thing vs. a damaged thing
                local probDamage = Fire.DAMAGE_HEALTHY_TILE_PROBABILITY
                local tHealthDetails = g_World.getTileHealth(tileX, tileY)
                
                if tHealthDetails and tHealthDetails.nHealth < g_World.TILE_DAMAGE_HEALTHY then
                    probDamage = Fire.DAMAGE_HURT_TILE_PROBABILITY
                end
                
                if math.random() < probDamage then
                    Fire.tTiles[addr] = Fire.tTiles[addr] + .4
                    
                    local tDamage = {
                        nDamage = 5.0,
                        nDamageType = require("CharacterConstants").DAMAGE_TYPE.Fire
                    }
                    
                    -- MTF TEMP HACK:
                    -- reduce breach frequency until we fix repair AI
                    --[[
                    g_World.damageTile(tileX, tileY, 1, tDamage)
                    
                    -- TEMP: Damage walls by fire without actually setting them on fire
                    for i=2,9 do
                        local tx,ty = g_World._getAdjacentTile(tileX,tileY,i)
                        local tileValue = g_World._getTileValue(tx, ty)
                        if tileValue == g_World.logicalTiles.WALL then
                            local nResult = g_World.damageTile(tx, ty, 1, tDamage)
                            if nResult == g_World.logicalTiles.WALL_DESTROYED then
                                g_World.playExplosion(g_World._getWorldFromTile(tx,ty,1))
                            end
                        end
                    end
                    ]]--
                end
            end
        end
    end
    
    if Fire.wasOnFire ~= isOnFire then
        if isOnFire then            
            Fire.fireSound = SoundManager.playSfx3D("fireloop")
        else
            Fire.fireSound:stop()
            Fire.fireSound = nil
        end        
        Fire.wasOnFire = isOnFire
    end
    
    if Fire.fireSound then
        local avgX, avgY = sumX/numX, sumY/numY
        Fire.fireSound:setLoc( avgX, avgY )
    end
end

function Fire._attemptFireTile(tx,ty)
    local addr = g_World.pathGrid:getCellAddr(tx, ty)
    local tileValue = g_World._getTileValue(tx, ty)

    if not Fire.tFlames[addr] and (not Fire.tTiles[addr] or Fire.tTiles[addr] < 1) then
-- MTF TEMP: removing fire spreading to doors and walls, because dudes currently don't handle well, and generally never extinguish it.
        if false and (tileValue == g_World.logicalTiles.WALL or tileValue == g_World.logicalTiles.DOOR) then
            if not Fire.tTiles[addr] then
                Fire.tTiles[addr] = .4
            else 
                Fire.tTiles[addr] = Fire.tTiles[addr] + .4
            end
        elseif g_World.countsAsFloor(tileValue) then
            Fire.tTiles[addr] = 1
        end

        if Fire.tTiles[addr] and Fire.tTiles[addr] >= 1 then
            Fire._addToTile(tx,ty)
            return 1
        end
    end
end

function Fire._addToTile(tx,ty,bLoading,nIntensity)
    local wx,wy = g_World._getWorldFromTile(tx,ty)
    local addr = g_World.pathGrid:getCellAddr(tx, ty)

    if Fire.tFlames[addr] then
        Print(TT_Error, 'Attempt to add a flame where there is already a flame.')
        return
    end
    --assert(not Fire.tFlames[addr])
    local flame = require('Flame').new(wx,wy, nil, nIntensity or Fire.INTENSITY_DEFAULT)
    Fire.tFlames[addr] = flame

    local prop = ObjectList.getObjAtTile(tx,ty)
    if prop then
        prop:onFire()
        if not bLoading then SoundManager.playSfx3D("firestart", wx, wy) end
    end

    local rRoom = Room.getRoomAtTile(tx,ty,1)
    if rRoom then
        rRoom:onFire()
        if not bLoading then SoundManager.playSfx3D("firestart", wx, wy) end
    end
end

function Fire.debugStartFire()
    local tc = require('CharacterManager').getCharacters()
    if tc[1] then
        Fire.startFire(tc[1]:getLoc())
    else
        Fire.startFire(0,0)
    end
end

function Fire.startFire(wx,wy)
    local tx, ty = g_World._getTileFromWorld(wx,wy)
    Fire._attemptFireTile(tx,ty)
    --alert
    local rRoom = Room.getRoomAtTile(tx,ty,1)
    if rRoom then
        Base.eventOccurred(Base.EVENTS.Fire, {wx=wx,wy=wy,rRoom=rRoom})
    end
end

function Fire.testFire()
    -- starts a fire under the cursor
    local DFInput = require('DFCommon.Input')
    local x,y = DFInput.m_x, DFInput.m_y
    local worldLayer = g_World.getWorldRenderLayer()
    local wx, wy = worldLayer:wndToWorld(x, y)
    local tx, ty = g_World._getTileFromWorld(wx,wy)
    local addr = g_World.pathGrid:getCellAddr(tx,ty)
    
    local rChar = ObjectList.getObjAtTile(tx,ty,ObjectList.CHARACTER)
    if not rChar then
        if Fire.tFlames[addr] then
            Fire.extinguish(wx,wy)    
        else
            Fire.startFire(wx,wy)
        end
    else
        -- we are on a citizen, set them on fire instead of the tileValue
        if not rChar:isDead() and not rChar.onFire then
            rChar:catchFire()
        end
    end
end

function Fire.getSaveTable(worldXOff,worldYOff)
    local tData = {tTiles={},tFlames={}}
    worldXOff,worldYOff = worldXOff or 0, worldYOff or 0
    for addr,nHeat in pairs(Fire.tTiles) do
        addr = GridUtil.OffsetAddrByWorld(addr, worldXOff,worldYOff)
        tData.tTiles[addr] = nHeat
    end
    for addr,rFlame in pairs(Fire.tFlames) do
        if rFlame.nIntensity > 0 then
            addr = GridUtil.OffsetAddrByWorld(addr, worldXOff,worldYOff)
            tData.tFlames[addr] = rFlame.nIntensity
        end
    end
    return tData
end

function Fire.fromSaveTable(tData, worldXOff,worldYOff,nTeam)
    if not tData or not tData.tTiles then return end 

    worldXOff,worldYOff = worldXOff or 0, worldYOff or 0
    Fire.tTiles = {}
    Fire.tFlames = {}

    for addr,nHeat in pairs(tData.tTiles) do
        addr = GridUtil.OffsetAddrByWorld(addr, worldXOff,worldYOff)
        Fire.tTiles[addr] = nHeat
    end
    for addr,nIntensity in pairs(tData.tFlames) do
        addr = GridUtil.OffsetAddrByWorld(addr, worldXOff,worldYOff)
        local tx,ty = g_World.pathGrid:cellAddrToCoord(addr)        
        Fire._addToTile(tx,ty,true,nIntensity)
    end
end

function Fire:getSpreadProbability(nIntensity)
    if nIntensity < Fire.INTENSITY_THRESHOLD_LOW then return Fire.SPREAD_PROBABILITY_LOW
    elseif nIntensity > Fire.INTENSITY_THRESHOLD_HIGH then return Fire.SPREAD_PROBABILITY_HIGH
    else return Fire.SPREAD_PROBABILITY_DEFAULT end
end

function Fire:getCitizenSpreadProbability(nIntensity)
    if nIntensity < Fire.INTENSITY_THRESHOLD_LOW then return Fire.CITIZEN_SPREAD_PROBABILITY_LOW
    elseif nIntensity > Fire.INTENSITY_THRESHOLD_HIGH then return Fire.CITIZEN_SPREAD_PROBABILITY_HIGH
    else return Fire.CITIZEN_SPREAD_PROBABILITY_DEFAULT end
end

return Fire
