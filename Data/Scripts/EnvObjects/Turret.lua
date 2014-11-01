local Class=require('Class')
local EnvObject=require('EnvObjects.EnvObject')
local CharacterManager=require('CharacterManager')
local GridUtil=require('GridUtil')
local Room=require('Room')
local EmergencyBeacon=require('Utility.EmergencyBeacon')
local Projectile=require('Projectile')
local Base=require('Base')
local ObjectList=require('ObjectList')
local Asteroid=require('Asteroid')
local Cursor=require('UI.Cursor')
local DFMath=require('DFCommon.Math')
local MiscUtil=require('MiscUtil')
local WorldObject=require('WorldObjects.WorldObject')
local Character=require('CharacterConstants')
local GameRules=require('GameRules')
local SoundManager = require('SoundManager')

local Turret = Class.create(EnvObject, MOAIProp.new)

-- range in tiles
Turret.FIRE_RANGE_TILES = 16
Turret.FIRE_RANGE_WORLD = 16*128
-- firing arc, in degrees
Turret.FIRE_ANGLE = 150
Turret.FIRE_ANGLE_MIN = -Turret.FIRE_ANGLE * .5
Turret.FIRE_ANGLE_MAX = Turret.FIRE_ANGLE * .5
Turret.FIRE_COOLDOWN = 1.5
Turret.HIT_POINTS = 250
Turret.FIRE_DAMAGE = 30
Turret.ATTACK_TYPE = Character.ATTACK_TYPE.Ranged
Turret.DAMAGE_TYPE = Character.DAMAGE_TYPE.Laser

-- MTF NOTE: this might as well be 0, as this will cause a tick every other frame.
Turret.VISUAL_TICK_RATE = 0.025

-- debug only: follow mouse cursor to test tracking
Turret.bDebugFollowMouse = false
Turret.bDebugInfo = false

-- rotation frames: turret faces SE, rotates clockwise
Turret.tFrames = {
	{ nMin = 0-180, sSprite = 'turret_frames0005' },
	{ nMin = 45-90, sSprite = 'turret_frames0004' },
	{ nMin = 75-90, sSprite = 'turret_frames0003' },
	{ nMin = 105-90, sSprite = 'turret_frames0002' },
	{ nMin = 135-90, sSprite = 'turret_frames0001' },
	{ nMin = 270-90, sSprite = 'turret_frames0005' },
}
Turret.sDeadFrame = 'turret_destroyed'

function Turret.reset()
	Turret.tTurrets = {}
	Turret.nLastUpdated = 1
end

function Turret:updateActivityOptionList()
    EnvObject.updateActivityOptionList(self)
end

function Turret.addTurret(rTurret)
	table.insert(Turret.tTurrets, rTurret)
end

function Turret.removeTurret(rTurret)
	for i,rOther in pairs(Turret.tTurrets) do
		if rOther == rTurret then
			table.remove(Turret.tTurrets, i)
			break
		end
	end
end

function Turret.tick(dt)
	-- update the turret who updated least recently
	if not next(Turret.tTurrets) then
		return
	end
	Turret.nLastUpdated = (Turret.nLastUpdated + 1) % (#Turret.tTurrets + 1)
	local rTurret = Turret.tTurrets[Turret.nLastUpdated]
	if rTurret then
		rTurret:calcTargetTiles()
	end
end

function Turret:isExternal()
    return self.bExternal
end

function Turret:charShouldAttack(rChar)
    if not self:isHostileTo(rChar) then return false end
        if self:isExternal() and not rChar:spacewalking() then
            return false, 'Character will not go outside to fight a turret.'
        end
        if self:isExternal() and rChar:getAttackType() ~= Character.ATTACK_TYPE.Ranged then
            return false, 'Characters do not melee external turrets.'
        end
        if not rChar:hasCombatAwarenessIn(rChar:getRoom()) then
            return false, 'Character has no combat awareness of turret.'
        end
        if Base.isFriendly(self,rChar) and not self:_fireOnEveryone() then
            return false, 'same team'
        end
        return true
end

-- Override to maintain power while sabotaged.
function Turret:hasPower()
    return self.bActive and (not self.tData.nPowerDraw or self.tData.nPowerDraw == 0 or (self.bHasPower or g_PowerHoliday))
end

function Turret:_fireOnEveryone()
    return self.bFireOnEveryone or self:_isSabotaged()
end

function Turret:init(sName, wx, wy, bFlipX, bFlipY, bForce, tSaveData, nTeam)
    if not bFlipY then
        self.bSortDownOneTile = true
    end
    
	EnvObject.init(self,sName, wx, wy, bFlipX, bFlipY, bForce, tSaveData, nTeam)
    
	self.nAngle = 0
	self.nVisualTimer = 0
	self.nFireCooldownTimer = 0
	self.sLastTargetFiredAtID = nil
	self:calcTargetTiles()
	-- attack only hostiles or everyone?
	self.bFireOnEveryone = (tSaveData and tSaveData.bFireOnEveryone)
    local tData = {}
	tData.rVictim = self
	tData.utilityGateFn = function(rChar)
        return self:charShouldAttack(rChar)
    end
    tData.rTargetObject = self
	self.rAttackOption = g_ActivityOption.new('AttackThreat',tData)

    tData = {}
	tData.rVictim = self
	tData.utilityGateFn = function(rChar)
        return self:charShouldAttack(rChar)
    end
    tData.rTargetObject = self
	self.rAttackOption = g_ActivityOption.new('RangedAttackThreat',tData)
	
	Turret.addTurret(self)
	
	-- debug info box
	if Turret.bDebugInfo then
		local ObjectDebugInfo = require('UI.ObjectDebugInfo')
		self.rDebugLabel = ObjectDebugInfo.new('Cursor', self)
		self.rDebugLabel:show(50)
	end
end

function Turret:getAngleFromTarget(targetX, targetY, bSquareIn)
	-- returns angle from base turret facing to target
	if not bSquareIn then
		targetX,targetY = GridUtil.IsoToSquare(targetX, targetY)
		if not targetX then targetX = 0 end
		if not targetY then targetY = 0 end
	end
	local tx,ty = GridUtil.IsoToSquare(self:getTileLoc())
    local dx, dy = targetX - tx, -(targetY - ty)
    local facingX,facingY = MiscUtil.isoDirToCartesian(self:getFacing())
    local nAngle = DFMath.getAngleBetween(facingX,facingY,dx,dy)
    -- remap to range -180 to 180 for easier use.
    while nAngle > 180 do nAngle = nAngle-360 end
    while nAngle < -180 do nAngle = nAngle+360 end
    return nAngle
end

function Turret:calcTargetTiles()
    local txInFront, tyInFront = self:getTileInFrontOf()
    self.bExternal = g_World._getTileValue(txInFront,tyInFront) == g_World.logicalTiles.SPACE    

	-- (re)calculates the tiles this turret can reach: in range, in FoV, in LoS
	self.tTiles = {}
	-- convert to square tiles, do everything in that, convert back at the end
	local tx,ty = GridUtil.IsoToSquare(self:getTileLoc())
    if not tx then return end

	local minX, minY = tx - self.FIRE_RANGE_TILES, ty - self.FIRE_RANGE_TILES
	local maxX, maxY = tx + self.FIRE_RANGE_TILES, ty + self.FIRE_RANGE_TILES
	local nMinAngle = self.FIRE_ANGLE_MIN
	local nMaxAngle = self.FIRE_ANGLE_MAX
    
    local selfIsoTX,selfIsoTY = self:getTileLoc()
    local addr = g_World.pathGrid:getCellAddr(selfIsoTX,selfIsoTY)
    self.tTiles[addr] = {x=selfIsoTX, y=selfIsoTY}
	
    for x=minX,maxX do
		for y=minY,maxY do
            if x ~= minX and x ~= maxX and y ~= minY and y ~= maxY then
                -- nothing. just calc edge tiles.
            else
			    local nAngle = math.abs(self:getAngleFromTarget(x,y,true))
			    if nAngle > nMinAngle and nAngle < nMaxAngle then
                    local tLine = GridUtil.GetTilesForLine(tx, ty, x, y, true)
                    for idx,coord in ipairs(tLine) do
                        if idx == 1 then
			            elseif DFMath.distance2D(tx, ty, coord[1],coord[2]) <= self.FIRE_RANGE_TILES then
                            local isoTX,isoTY = GridUtil.SquareToIso(coord[1], coord[2])
                            if isoTX then
                                local tileValue = g_World._getTileValue(isoTX,isoTY)
                                local rDoor = nil
                                if tileValue == g_World.logicalTiles.DOOR then rDoor = ObjectList.getDoorAtTile(isoTX,isoTY) end
                                if tileValue ~= g_World.logicalTiles.WALL and not Asteroid.isAsteroid(tileValue) and (not rDoor or rDoor:isOpen()) then
                                    addr = g_World.pathGrid:getCellAddr(isoTX,isoTY)
                                    self.tTiles[addr] = {x=isoTX, y=isoTY}
                                else
                                    break
                                end
                            end
                        else
                            break
                        end
                    end
                end
            end
		end
	end
end

function Turret:getValidTargetList()
    --local stx,sty = self:getTileLoc()
    local swx,swy = self:getLoc()
	local tTargetChars
	if self:_fireOnEveryone() then
		tTargetChars = CharacterManager.getLivingCharactersInRange(swx, swy, self.FIRE_RANGE_WORLD)
	else
		tTargetChars = CharacterManager.getHostileCharactersInRange(swx, swy, self.FIRE_RANGE_WORLD, self)
	end
    local tTargetWorldObjects = WorldObject.getHostileObjectsInRange(swx, swy, self.FIRE_RANGE_WORLD, self)
    local t = {}
    for _,v in ipairs(tTargetChars) do
        if self:isHostileTo(v.rEnt) then
            table.insert(t,v)
        end
    end
    for _,v in ipairs(tTargetWorldObjects) do
        table.insert(t,v)
    end
	-- sort ranges, /lowest/ first
	local f = function(x,y) return x.nDist2 < y.nDist2 end
	table.sort(t, f)
	return t
end

-- Can we hit that tile?
-- First we test our target tile list, and early-out if that fails.
-- Then, not sure on the heuristic for turrets shooting to other levels, e.g. shooting at worldships under the base etc.
-- For now, I'm doing:
-- * is it on level 1, the main level? If so, line-of-sight checks already handled that, so return true.
-- * Is this an external turret? If so, assume it can shoot up and down.
-- * Is this a space tile? If so, assume it can shoot through the room floor breach into space.
-- * Otherwise, false.
function Turret:_canHit(tx,ty,tw)
    local addr = g_World.pathGrid:getCellAddr(tx, ty)
    if self.tTiles[addr] then
        if tw == 1 then
            return true
        else
            if self.bExternal then
                return true
            end
            if g_World._getTileValue(tx,ty) == g_World.logicalTiles.SPACE then
                return true
            end
        end
    end
    return false
end

function Turret:updateCurrentTarget()
    -- bWasFriendly is a flag to prevent once-friendly turrets from stopping the player from claiming a room.
    -- Once-friendly turrets will NOT fire on a player even if the room has been unclaimed, unless they're set
    -- to "fireOnEveryone."
    if not self.bWasFriendly and self:getTeam() == Character.TEAM_ID_PLAYER and not self:_fireOnEveryone() then
        self.bWasFriendly = true
    end

	local tRanges = self:getValidTargetList()
    local x,y = self:getLoc()
    local rEnt = nil
    local wxOverride,wyOverride = nil,nil

	-- find closest hostile in the (precomputed) list of tiles we can see
    local tTestPoints = {}
    
	for _,tTarget in ipairs(tRanges) do
        if Room.getVisibilityAtTile(tTarget.rEnt:getTileLoc()) ~= g_World.VISIBILITY_FULL then break end
        for i=1,5 do
            local wx,wy,wz,nLevel = tTarget.rEnt:getLoc()
            local bOverride = i~=1
            if i == 2 then
                wx=wx+tTarget.rEnt:getHitRadius()*.5
            elseif i == 3 then
                wx=wx-tTarget.rEnt:getHitRadius()*.5
            elseif i == 4 then
                wy=wy+tTarget.rEnt:getHitRadius()*.5
            elseif i == 5 then
                wy=wy-tTarget.rEnt:getHitRadius()*.5
            end

            -- lead the target, if we can.
            if tTarget.rEnt.getVelocity then
                local targetVelX,targetVelY = tTarget.rEnt:getVelocity()
                local wxLead,wyLead = MiscUtil.leadTarget(x, y, Projectile.DEFAULT_SPEED, wx, wy, targetVelX, targetVelY)
                local txLead,tyLead = g_World._getTileFromWorld(wxLead,wyLead)
                if self:_canHit(txLead,tyLead,nLevel) then
                    wx,wy = wxLead,wyLead
                end
            end

            local tx,ty = g_World._getTileFromWorld(wx,wy)
            if self:_canHit(tx,ty,nLevel) then
                rEnt = tTarget.rEnt
                wxOverride = wx
                wyOverride = wy
                break
            end
            if not tTarget.rEnt.getHitRadius then break end
        end
        if rEnt then
            break
        end
    end
    self.rCurrentTarget = rEnt
    self.wxOverride,self.wyOverride = wxOverride,wyOverride
end

function Turret:isHostileTo(rChar)
    if rChar:isDead() then return false end
    if not self:isFunctioning() then return false end
    if self:_fireOnEveryone() then return true end
    if Base.isFriendly(self,rChar) then return false end
    if rChar.tStatus.bCuffed then return false end
    if rChar:inPrison() then
        return false 
    end
    if self.bWasFriendly and Base.isFriendlyToPlayer(rChar) then return false end

    return true
end


function Turret:fire(rTarget, wxOverride, wyOverride)
	--print('firing on target '..rTarget.tStats.sUniqueID)
	local targetX,targetY,targetW = rTarget:getLoc()
    if wxOverride then
        targetX = wxOverride
        targetY = wyOverride
    end
	local targetTX,targetTY = g_World._getTileFromWorld(targetX,targetY)
	-- don't wait until next tick to set facing
	self:updateVisuals()
	
	--Projectile:init(wx,wy, sLayerName, bHitWalls,nSpeed,impactCB)
    local swx,swy = self:getLoc()
	local bullet = Projectile.new(swx, swy, nil, true, nil)
    local tDamage = {}
	tDamage.nDamage = self.FIRE_DAMAGE
	tDamage.nAttackType = self.ATTACK_TYPE
    tDamage.nDamageType = self.DAMAGE_TYPE
	local sSpriteName = Character.SPRITE_NAME_FRIENDLY_RIFLE
	SoundManager.playSfx3D('turretgunfire', swx, swy, 0)
	bullet:setSprite(sSpriteName,'SpriteAnims/Effects')
    -- Constrain to path
    local stx,sty = self:getTileLoc()
	local tLineTiles = GridUtil.GetTilesForLine(stx, sty, targetTX,targetTY)
	-- JPL TODO: find out why uncommenting this makes the projectile hit its
	-- target instantly!
    -- MTF: because our projectile code need to be rewritten.
    --bullet:setPathConstraint({self.wx-targetX, self.wy-targetY}, tLineTiles)
    bullet:fireAtTarget(rTarget, self, tDamage, nil, self.wxOverride, self.wyOverride)
	self.nFireCooldownTimer = self.FIRE_COOLDOWN
	
	--Room.spreadCombatAwareness(self.tx, self.ty, 0)
end

function Turret:hover(hoverTime)
	EnvObject.hover(self,hoverTime)
	-- show radius in red if deactivated
	local bGreenNotRed = self:isFunctioning()
	-- clear any tiles that might be on from previous frames
	g_World.layers.cursor.grid:fill(0)
	-- draw coverage area as yellow tiles
	Cursor.drawTiles(self.tTiles, bGreenNotRed, true, false)
end

function Turret:unHover()
	EnvObject.unHover(self)
	g_World.layers.cursor.grid:fill(0)
	Cursor.drawTiles(self.tTiles, false, false)
end

function Turret:getSpriteFromAngle(nAngle)
	-- get sprite from Turret.tFrames based on angle
	local sSprite = self.tFrames[1].sSprite
    -- reverse check if bFlipX
    if self.bFlipX then nAngle = -nAngle end
    if self.bFlipY then nAngle = -nAngle end
	for i,tFrame in ipairs(self.tFrames) do
		if nAngle >= tFrame.nMin then
            sSprite = tFrame.sSprite
		end
	end
    if self.bFlipY then
        sSprite = sSprite .. '_flipY'
    end
	return sSprite
end

function Turret:updateVisuals()
	if self:isDead() then
		self:setIndex(self.spriteSheet.names[self.sDeadFrame])
		return
	end
	-- turn towards target
	local sSprite = MiscUtil.randomValue(self.tFrames)
	local rTrackTarget = self.rCurrentTarget
	local nAngle
	if rTrackTarget then
		-- get angle to target, 0 to FIRE_ANGLE
        local tx,ty = rTrackTarget:getTileLoc()
		nAngle = self:getAngleFromTarget(tx,ty)
	else
		-- scan back and forth if no target
		local nScanRate = .33
		nAngle = math.sin(GameRules.elapsedTime * nScanRate)
		nAngle = math.abs(nAngle * self.FIRE_ANGLE)
	end
	if Turret.bDebugFollowMouse then
		local cx, cy = g_World.getWorldRenderLayer():wndToWorld(GameRules.cursorX, GameRules.cursorY)
		cx,cy = g_World._getTileFromWorld(cx,cy)
		nAngle = self:getAngleFromTarget(cx, cy)
	end
	sSprite = self:getSpriteFromAngle(nAngle)
    -- just storing this for debug display.
	self.nAngle = nAngle
	self:setIndex(self.spriteSheet.names[sSprite])
end

function Turret:onTick(dt)
    EnvObject.onTick(self, dt)
	
	if Turret.bDebugInfo then
		self.rDebugLabel:refresh()
	end
	
	if self:isDead() or not self:isFunctioning() then
		return
	end

    local bUpdatedTarget = false
	if self.nVisualTimer > 0 then
		self.nVisualTimer = self.nVisualTimer - dt
	else
		self.nVisualTimer  = self.nVisualTimer + self.VISUAL_TICK_RATE
        self:updateCurrentTarget()
        bUpdatedTarget = true
		self:updateVisuals()
	end
	if self.nFireCooldownTimer > 0 then
		self.nFireCooldownTimer = self.nFireCooldownTimer - dt
		return
	end
    if not bUpdatedTarget then
        self:updateCurrentTarget()
        bUpdatedTarget = true
    end
	if self.rCurrentTarget then
		self:fire(self.rCurrentTarget, self.wxOverride, self.wyOverride)
		self.sLastTargetFiredAtID = self.rCurrentTarget:getUniqueID()
	end
end

function Turret:getAvailableEnemyActivities()
	local tActivities = EnvObject.getAvailableEnemyActivities(self)
    if self.rAttackOption and not self:isDead() then
		table.insert(tActivities, self.rAttackOption)
    end
    return tActivities
end

function Turret:getAvailableActivities()
	local tActivities = EnvObject.getAvailableActivities(self)
    if self.rAttackOption and not self:isDead() then
		table.insert(tActivities, self.rAttackOption)
    end
    return tActivities
end

function Turret:remove()
	self:unHover()
	Turret.removeTurret(self)
	EnvObject.remove(self)
end

function Turret:getSaveTable(xShift,yShift)
    local t = EnvObject.getSaveTable(self,xShift,yShift)
	t.bFireOnEveryone = self.bFireOnEveryone
    return t
end

function Turret:getThreatLevel()
    return Character.THREAT_LEVEL.Turret
end

function Turret:getZ(wx,wy)
    -- fudge the z a little to draw the turret barrel in front of adjacent walls.
    local tx, ty = g_World._getTileFromWorld(self:getLoc())
    tx,ty = g_World._getAdjacentTile(tx,ty, g_World.directions.SW)
    wx,wy = g_World._getWorldFromTile(tx,ty)
    return g_World.getHackySortingZ(wx,wy-5)
end

return Turret
