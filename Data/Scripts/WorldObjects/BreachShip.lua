local Class=require('Class')
local DFGraphics=require('DFCommon.Graphics')
local WorldObject=require('WorldObjects.WorldObject')
local Character=require('CharacterConstants')
local Renderer=require('Renderer')
local MiscUtil=require('MiscUtil')
local SoundManager = require('SoundManager')

local BreachShip = Class.create(WorldObject, MOAIProp.new)

BreachShip.FADE_TIME = 20
BreachShip.INV_FADE_TIME = 1/BreachShip.FADE_TIME
BreachShip.WORLD_Z = -8500

function BreachShip:init(wx,wy,tSaveData,nTeam)
    local tSpec={
        sClass='WorldObjects.BreachShip',
        sNameLinecode='OBJCTX001TEXT',
        sDescLinecode='OBJCTX002TEXT',
        sSpriteName='raider_spacebus',
        sSpriteSheetPath='Environments/Objects',
        sPortraitSpriteName='Env_BreachShip',
        sPortraitSpriteSheetPath='UI/Portraits',
        bHasConditions=false,
    }
    WorldObject.init(self, tSpec, 'WorldFloor', wx, wy, tSaveData, nTeam)
    --WorldObject.init(self, tSpec, Character.RENDER_LAYER, wx, wy, tSaveData, nTeam)
    self.nFlipX,self.nFlipY = 1,1
    self.vx,self.vy=0,0
    self:setLoc(wx,wy,BreachShip.WORLD_Z)
    SoundManager.playSfx('spacetaxi', wx, wy, 0)
    self.rLoopingSound = SoundManager.playSfx3D('raiderengineloop', wx, wy, 0)

    self.rOutlineCopy = DFGraphics.newSprite(tSpec.sSpriteName, Renderer.getRenderLayer(Character.BACKGROUND_RENDER_LAYER), tSpec.sSpriteSheetPath, 0,0, 0)
    MiscUtil.setTransformVisParent(self.rOutlineCopy,self)
    WorldObject.tTickers[self] = 1
end

function BreachShip:setFacingVec(vx,vy)
    local dir = g_World.getCardinalOrOrdinalDirectionToVector(vx,vy)
    self:setFacingDir(dir)
end

function BreachShip:setFacingDir(dir)
    local bFlipX=false
    local bFlipY=false
    self.sSpriteName = 'raider_spacebus'
    if dir == g_World.directions.NE or dir == g_World.directions.E or dir == g_World.directions.SE then
        bFlipX = true
    end
    if dir == g_World.directions.N or dir == g_World.directions.NE or dir == g_World.directions.NW then
        --bFlipY = true
        self.sSpriteName = 'raider_spacebus_back'
    end
    self.nFlipX = (bFlipX and -1) or 1
    self.nFlipY = (bFlipY and -1) or 1

    DFGraphics.alignSprite(self.rSpriteSheet, self.sSpriteName, "center", "center")
    self:setIndex(self.rSpriteSheet.names[self.sSpriteName])
    self:setScl(self.nFlipX, self.nFlipY, 1)
end

function BreachShip:fadeAway(nTime)
    --WorldObject.tTickers[self] = 1
    self.nRemainingFadeTime = nTime or BreachShip.FADE_TIME
end

-- tile "radius". Hideously approximate since horiz and vert tiles are different, so we probably should use
-- the hit radius instead. But for now it's just used to give turrets a slightly longer range so it's fine.
function BreachShip:getTileRadius()
    return 3
end

-- worldspace hit enlargement.
function BreachShip:getHitRadius()
    return 210
end

function BreachShip:setIndex(n)
    self._UserData.setIndex(self,n)
    if self.rOutlineCopy then
        self.rOutlineCopy:setIndex(n)
    end
end

function BreachShip:onTick(dt)
    local tx,ty = self:getTileLoc()
    if g_World._getTileValue(tx,ty) == g_World.logicalTiles.SPACE then
        self.rOutlineCopy:setVisible(false)
    else
        self.rOutlineCopy:setVisible(true)
    end
    
    if self.rLoopingSound then
        local wx,wy = self:getLoc()
        self.rLoopingSound:setLoc(wx,wy,BreachShip.WORLD_Z)
    end
    
    if self.nRemainingFadeTime then
        self.nRemainingFadeTime = self.nRemainingFadeTime - dt
        if self.nRemainingFadeTime <= 0 then
            self:remove()
        else
			local wx,wy = self:getLoc()
			self:setLoc(wx + 1 * -self.nFlipX, wy + 1 * self.nFlipY,BreachShip.WORLD_Z)
            self:setScl(self.nFlipX * self.nRemainingFadeTime*BreachShip.INV_FADE_TIME, self.nFlipY * self.nRemainingFadeTime*BreachShip.INV_FADE_TIME, 1)
        end
    end
end

-- get/set velocity are for Projectile leading code. The BreachShip has no concept of velocity, but events & other
-- users can set a "velocity" for the ship to report.
function BreachShip:setVelocity(vx,vy)
    self.vx,self.vy = vx,vy
end

function BreachShip:getVelocity()
    return self.vx,self.vy
end

function BreachShip:takeDamage(rSource, tDamage)
    -- right now we don't mitigate based on damage type. Just like take some damage dude.
    local nDamage = tDamage.nDamage or 1

    -- armor!
    nDamage = math.max(1,nDamage*.5)
	
	g_World.playExplosion(self:getLoc())
	
    self:_setCondition(self.nCondition - nDamage)
    if self.nCondition <= 0 then
        self:explode()
    end
end

function BreachShip:getContentsText()
    return g_LM.line('DOCKUI144TEXT')
end

function BreachShip:getRaiderStats(nBaseNumToSpawn)
    local tRaiders = {}
    local nNonInjuryChance = self.nCondition/100
    for i=1,nBaseNumToSpawn do
        local nRoll = math.random()
        local nNumInjuries = math.min(2,math.floor(nRoll/nNonInjuryChance))
        local dmg = 0
        for i=1,nNumInjuries do
            dmg = dmg + math.random() * Character.STARTING_HIT_POINTS
        end
        dmg = math.floor(dmg+.5)
        if dmg >= Character.STARTING_HIT_POINTS then
        else
            table.insert(tRaiders, { tStats = { nHitPoints = Character.STARTING_HIT_POINTS - dmg } } )
        end
    end
    if #tRaiders == 0 then
        -- oops they all died. Let's put one banged-up one in there.
        table.insert(tRaiders, { tStats = { nHitPoints = 1 + Character.STARTING_HIT_POINTS * nNonInjuryChance } } )
    end
    return tRaiders
end

function BreachShip:explode()
	g_World.playExplosion(self:getLoc())
	-- count stat only if another turret hasn't already destroyed us
	if not self.bExploded then
		require('Base').incrementStat('nBreachShipsDestroyed')
	end
    self.bExploded = true
    self:remove()
end

function BreachShip:remove()
    Renderer.getRenderLayer(Character.BACKGROUND_RENDER_LAYER):removeProp(self.rOutlineCopy)
    if self.rLoopingSound then
        self.rLoopingSound:stop()
        self.rLoopingSound = nil
    end
    WorldObject.remove(self)
end

function BreachShip:getSaveTable(xShift,yShift)
    local t = WorldObject.getSaveTable(self,xShift,yShift)
    if self.nRemainingFadeTime then
        t.nRemainingFadeTime = self.nRemainingFadeTime
    end
end

function BreachShip.fromSaveTable(t, xOff, yOff, nTeam)
    local bs = BreachShip.new(t.wx+xOff, t.wy+yOff, t, nTeam or t.nTeam)
    if t.nRemainingFadeTime then
        bs:fadeAway(bs.nRemainingFadeTime)
    end

    return bs
end

return BreachShip

