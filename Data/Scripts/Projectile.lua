local Class=require('Class')
local World=require('World')
local Renderer=require('Renderer')
local Entity=require('Entity')
local Room=require('Room')
local MiscUtil=require('MiscUtil')
local DFUtil = require('DFCommon.Util')
local DFGraphics = require('DFCommon.Graphics')
local DFMath = require('DFCommon.Math')
local Effect = require('Effect')
local ObjectList = require('ObjectList')
local Asteroid = require('Asteroid')
local Fire = require('Fire')
local GameRules = require('GameRules')

local Projectile = Class.create(nil, MOAIProp.new)

Projectile.RENDER_LAYER = 'WorldWall'
Projectile.DEFAULT_SPEED = 600
Projectile.prtImpactParticle = 'Effects/Props/RifleImpact01'
Projectile.nChanceToCauseFire = .1
Projectile.tProjectiles = {}

function Projectile.onTick(dt)
	for rProj,_ in pairs(Projectile.tProjectiles) do
		rProj:onUpdate(dt)
	end
end

function Projectile.reset()
	Projectile.tProjectiles = {}
end

function Projectile:init(wx,wy, sLayerName, bHitWalls,nSpeed)
    self.rLayer = Renderer.getRenderLayer(sLayerName or Projectile.RENDER_LAYER)
    local z = World.getHackySortingZ(wx,wy-g_World.tileHeightH)
    self:setLoc(wx,wy,z)
    self.x,self.y,self.z = wx,wy,z
    self.rLayer:insertProp(self)
    self.bHitWalls = bHitWalls
    self.nSpeed = nSpeed or Projectile.DEFAULT_SPEED
    self.nSpeed2 = self.nSpeed*self.nSpeed
    self.tMissedTargets = {}
end

function Projectile:setSprite(sName,sSheet)

    self.rDeck = DFGraphics.loadSpriteSheet(sSheet)
    DFGraphics.alignSprite(self.rDeck, sName, "center", "center")
	self:setDeck(self.rDeck)
	self:setIndex(self.rDeck.names[sName])

	--[[
	self.rSprite,self.rDeck = DFGraphics.newSprite3D(sName,self.rLayer,sSheet)
    DFGraphics.alignSprite(self.rDeck, self.rSprite.spritePath, "center", "center")
    self.rSprite:setAttrLink( MOAITransform.INHERIT_TRANSFORM, self, MOAITransform.TRANSFORM_TRAIT )
	]]--
end

-- When the projectile checks for collisions it will only check against tiles along the constrained path
function Projectile:setPathConstraint(tOffset, tConstrainedPath)
    self.tOffset = tOffset
    self.tConstrainedPath = tConstrainedPath
end

function Projectile:fireAtTarget(rTarget, rOwner, tDamage, bLeadTarget, wxOverride, wyOverride)
	Projectile.tProjectiles[self] = 1
    self.rTarget = rTarget
    self.rOwner = rOwner
    self.tDamage = tDamage
    self.bLeadTarget = bLeadTarget
    self.targetWX = wxOverride
    self.targetWY = wyOverride
    self:_orientToTarget()
end

--[[
function Projectile:fireAtLoc(tx,ty, rOwner, tDamage)
	Projectile.tProjectiles[self] = 1
    self.targetWX,self.targetWY = tx,ty
    self.rOwner = rOwner
    self.tDamage = tDamage
    self:_orientToTarget()
end
]]--

function Projectile:onUpdate(dt)

    if not World.isInBounds(self:getLoc()) then
        self:destroy()
	end

    local targetX,targetY = self.targetWX,self.targetWY
    if self.rTarget then
        targetX,targetY = self.rTarget:getLoc()
    end
    
    if targetX then
    
        -- Get the tile location of the target. Note, do this before applying the offset, so we ensure we get the correct tile
        local tTileX, tTileY = World._getTileFromWorld(targetX,targetY)
        
        -- If we have an offset, add it to the target, so we don't shoot at feet
        local tOffsetX, tOffsetY = targetX,targetY
        if self.tOffset then tOffsetX, tOffsetY = targetX+self.tOffset[1], targetY+self.tOffset[2] end
        local x,y,z = self:getLoc()
        local d2 = DFMath.distance2DSquared( x,y, tOffsetX,tOffsetY )
        local vx,vy
        local nHitRadius = (self.rTarget and self.rTarget.getHitRadius and self.rTarget:getHitRadius()) or 0
        local nHitRadius2 = nHitRadius*nHitRadius
        
        if d2 < self.nSpeed2*dt*dt+nHitRadius2 or d2 < 0.001+nHitRadius2 then
            local wz = World.getHackySortingZ(tOffsetX,tOffsetY-g_World.tileHeightH)
            self.rHitTarget = self.rTarget
			self:_attemptToHitTarget()
        else
            if not self.vx then self.vx,self.vy = DFMath.normalize(tOffsetX-x, tOffsetY-y) end -- only update the velocity vector once, so we don't have curving bullets
            local vx,vy = dt * self.nSpeed * self.vx, dt * self.nSpeed * self.vy

            local newX,newY = x+vx,y+vy
            local wz = World.getHackySortingZ(newX,newY-g_World.tileHeightH)
            self:setLoc(newX,newY,wz)
            
            if not self.bOriented then self:_orientToTarget(vx,vy) end
            -- If we are on a constrained path, figure out what tile we are closest to
            local constrainedTileX, constrainedTileY
            if self.tConstrainedPath then
                -- dist from our loc to the next two tile constraints
                local nDist2 = DFMath.distance2DSquared(newX,newY,g_World._getWorldFromTile(self.tConstrainedPath[1][1],self.tConstrainedPath[1][2]))
                if self.tConstrainedPath[2] then
                    local nNextDist2 = DFMath.distance2DSquared(newX,newY,g_World._getWorldFromTile(self.tConstrainedPath[2][1],self.tConstrainedPath[2][2]))
                    -- if we're closer to the 2nd tile than the first, nuke the 2nd.
                    if nNextDist2 < nDist2 then
                        table.remove(self.tConstrainedPath,1)
                    end
                else
                    -- detect if we're done with the path. Determined by whether we're getting further from the last tile.
                    if self.nLastConstrainedDist2 and nDist2 > self.nLastConstrainedDist2 then
                        self.tConstrainedPath=nil
                    else
                        self.nLastConstrainedDist2 = nDist2
                    end
                end
                if self.tConstrainedPath then
                    constrainedTileX,constrainedTileY = self.tConstrainedPath[1][1],self.tConstrainedPath[1][2]
                end
            end
            
            -- Check to see if we should hit our primary target
            if constrainedTileX and constrainedTileY and constrainedTileX == tTileX and constrainedTileY == tTileY and self:_canHitTarget(self.rTarget) then
                self.rHitTarget = self.rTarget
                self:_attemptToHitTarget()                
            end
            
            -- If we didn't hit the primary target, check to see if there's another character here we can hit
            if not self.bDone then
                local tileX, tileY = constrainedTileX,  constrainedTileY
                if not tileX then tileX, tileY = World._getTileFromWorld(newX,newY) end
                local rChar = ObjectList.getObjAtTile(tileX,tileY,ObjectList.CHARACTER)
                if rChar and self.rOwner and self.rOwner.shouldTargetForAttack and self.rOwner:shouldTargetForAttack(rChar) and self:_canHitTarget(rChar) then
                    self.rHitTarget = rChar
                    self:_attemptToHitTarget()
                end
            end
            
            -- If we didn't hit anything else, did we hit a wall?
            if not self.bDone and self.bHitWalls then
                if constrainedTileX and constrainedTileY then
                    if self:_tileBlocksProjectile(constrainedTileX,constrainedTileY) then self:_attemptToHitTarget(constrainedTileX, constrainedTileY, {self.vx, self.vy}) end
                else
                    local tileX, tileY = World._getTileFromWorld(newX,newY)
                    if self:_tileBlocksProjectile(tileX,tileY) then
                        self:_attemptToHitTarget(tileX, tileY, {self.vx, self.vy})
                    end
                end
            end
        end
    end
end

function Projectile:_orientToTarget(vx,vy)
    if vx then -- align to the corresponding vector
        local rot = DFMath.getAngleBetween( 0, 1, vx,vy)
        self:setRot(0,0,rot)
        self.bOriented = true
        return
    end
    
    if not self.bOriented then
        local targetX,targetY
        local x,y,z = self:getLoc()
        if self.targetWX then
            targetX,targetY = self.targetWX,self.targetWY
        elseif self.rTarget then
            if self.bLeadTarget then
                local wxTarget,wyTarget = self.rTarget:getLoc()
                local targetVelX,targetVelY = 0,0
                if self.rTarget.getVelocity then
                    targetVelX,targetVelY = self.rTarget:getVelocity()
                end
                targetX,targetY = MiscUtil.leadTarget(x, y, self.nSpeed, wxTarget, wyTarget, targetVelX, targetVelY)
            else
                targetX,targetY = self.rTarget:getLoc()
            end
            if self.tOffset then targetX,targetY = targetX+self.tOffset[1],targetY+self.tOffset[2] end
        end
        self.vx,self.vy = DFMath.normalize(targetX-x,targetY-y)
    
        local rot = DFMath.getAngleBetween(0, 1, self.vx, self.vy)
        self:setRot(0,0,rot)
        self.bOriented = true
    end
end

function Projectile:_canHitTarget(rTargetToHit)
    return not self.tMissedTargets or not self.tMissedTargets[rTargetToHit]
end

function Projectile:_attemptToHitTarget(tx, ty, dir)
    -- Check to see if we actually hit the object
    local nDodgeChance = -1
    if self.rHitTarget and self.rHitTarget.dodgeAttackChance then nDodgeChance = self.rHitTarget:dodgeAttackChance() end
    
    -- Check for a hit
    if math.random() > nDodgeChance then
        self:impact()
        if self.rHitTarget and self.rHitTarget.takeDamage then
            self.rHitTarget:takeDamage(self.rOwner, self.tDamage)
        else
            -- what we hit doesn't take damage, for fun let's start a fire instead
            if tx and ty then
                local logicalValue = World._getTileValue(tx, ty)
                if logicalValue == World.logicalTiles.WALL then
                    -- you hit a wall
                    World.damageTile(tx, ty, 1, self.tDamage)
                end
                                
                if dir and math.random() < Projectile.nChanceToCauseFire then
                    local direction = World.getCardinalOrOrdinalDirectionToVector(dir[1],dir[2])
                    local adjTileX, adjTileY = World._getAdjacentTile(tx, ty, direction)
                    Fire.startFire(World._getWorldFromTile(adjTileX, adjTileY))
                end
            end
        end
        self:destroy()
        return 
    else
        self.tMissedTargets[self.rHitTarget] = 1
        self.rHitTarget = nil 
    end
end

function Projectile:_tileBlocksProjectile(tx,ty)
    local tileValue = World._getTileValue(tx, ty)
    local rDoor = nil
    if tileValue == g_World.logicalTiles.DOOR then rDoor = ObjectList.getDoorAtTile(tx,ty) end
    return self.bHitWalls and (tileValue == World.logicalTiles.WALL or Asteroid.isAsteroid(tileValue) or (rDoor and not rDoor:isOpen()))
end

function Projectile:impact()
    --impact effect
    local rAttach = nil
    local tOffset = self.tOffset or {}
    local wx,wy = self:getLoc()
    tOffset[1] = tOffset[1] or 0
    tOffset[2] = tOffset[2] or 180
    tOffset[3] = tOffset[3] or 100
    if self.rHitTarget then
        rAttach = self.rHitTarget.tHackEntity
        if not rAttach then
            rAttach = Entity.new(self.rHitTarget, self.rLayer, "ParticleStandin")
        end
        if ObjectList.getObjType(self.rHitTarget) == ObjectList.CHARACTER then
            tOffset[1] = 0
            tOffset[2] = 180
            tOffset[3] = 100
        end
        wx,wy = 0,0
    end

    local e = Effect.new(self.prtImpactParticle, wx,wy, rAttach, nil, tOffset)
    local ewx,ewy = e:getLoc()
    local etx,ety = g_World._getTileFromWorld(ewx,ewy)
    Effect.new('Effects/Props/RifleImpactSparkFlash', wx,wy, rAttach, nil, tOffset) --this is a hack till we get multi-stage effects merged in.

    Room.spreadCombatAwareness(self.rOwner, g_World._getTileFromWorld(self:getLoc())) 
    --impact sound goes here??
end

function Projectile:destroy()
    self.targetWX, self.targetWY = nil, nil
    self.vx,self.vy = nil,nil
    self.rTarget, self.rHitTarget = nil, nil
    self.tMissedTargets = {}
    self.tConstrainedPath = {}
    self.tOffset, self.nLastConstrainedDistance2 = nil
    self.rLayer:removeProp(self)
    self.bDone = true
    --self.rLayer:removeProp(self.rSprite)
	Projectile.tProjectiles[self] = nil
end

return Projectile

