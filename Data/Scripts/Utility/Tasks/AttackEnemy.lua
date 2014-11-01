local Task=require('Utility.Task')
local DFMath=require('DFCommon.Math')
local World=require('World')
local Class=require('Class')
local Base=require('Base')
local Log=require('Log')
local DFUtil = require('DFCommon.Util')
local DFMath = require('DFCommon.Math')
local Topics=require('Topics')
local ObjectList=require('ObjectList')
local GameRules=require('GameRules')
local MiscUtil=require('MiscUtil')
local Character=require('CharacterConstants')
local Projectile=require('Projectile')
local Room=require('Room')
local Pathfinder=require('Pathfinder')
local GridUtil=require('GridUtil')

local AttackEnemy = Class.create(Task)

--AttackEnemy.emoticon = 'alert'
AttackEnemy.GRAPPLE_DURATION = 3

AttackEnemy.SHOOT_AIM_TIME_RANGE = {0.35,.65}
AttackEnemy.SHOOT_COOLDOWN_RANGE = {0.1,.4}

AttackEnemy.RANGED_ATTACK_SHOOT = 'shoot'
AttackEnemy.RANGED_ATTACK_IDLE = 'patrol_idle'

function AttackEnemy:init(rChar, tPromisedNeeds, rActivityOption)
    Task.init(self,rChar,tPromisedNeeds,rActivityOption)

    self.rVictim = rActivityOption.tData.rVictim
    self.duration = Task.DURATION_UNKNOWN_LONG
    local bBrawling = self.rChar:isBrawling(self.rVictim)
    -- post an alert about the brawl if it's new
    if bBrawling then
        local wx,wy = self.rChar:getLoc()
        local tEventData = { wx=wx, wy=wy }
        local rRoom = self.rChar:getRoom()
        if rRoom and rRoom ~= Room.rSpaceRoom then
            tEventData.sRoom = rRoom.uniqueZoneName
        end
        if not Base._getRelatedEvent(Base.EVENTS.CitizensBrawling, tEventData) then
            Base.eventOccurred(Base.EVENTS.CitizensBrawling, tEventData)
        end
        -- start brawl log
        local tLogData = { sOpponent = self.rVictim.tStats.sName }
        Log.add(Log.tTypes.ENTER_BRAWL, self.rChar, tLogData)
        self.rChar:setWeaponDrawn(false)
    else
        self.rChar:setWeaponDrawn(true,self.rVictim)
        if self.rChar:getJob() == Character.EMERGENCY then        
            self.HELMET_REQUIRED = true
            self.rChar:showHelmet()
        end        
    end
    
    self.nShootingTimeElapsed = 0
	
	-- play startle anim
    if self.rChar:getJob() == Character.EMERGENCY and (self.rChar:onDuty() or self.rChar.tStatus.bOldTaskWorkShift) then
        -- no startle anim for emergency folks doing emergency stuff.
    elseif self.rChar:getJob() == Character.RAIDER then
        -- no startle anim for raiders
	elseif not bBrawling and self.rChar.tStats.nRace ~= Character.RACE_MONSTER and self.rChar.tStats.nRace ~= Character.RACE_KILLBOT and math.random() < Character.STARTLE_CHANCE then
        if not self.rChar:retrieveMemory(Character.MEMORY_STARTLED_RECENTLY) then
            self.rChar:playAnim('startle', true)
            self.rChar:storeMemory(Character.MEMORY_STARTLED_RECENTLY, true, Character.MEMORY_STARTLED_RECENTLY_DURATION) 
        end
	end
	
	-- if we haven't attacked recently, log "entering combat"
    if not bBrawling and not self.rChar:retrieveMemory(Character.MEMORY_ENTERED_COMBAT_RECENTLY) then
		self.rChar:storeMemory(Character.MEMORY_ENTERED_COMBAT_RECENTLY, true, 15)
		local logType
		local tLogData = {}
		-- attacking a person?
		if self.rVictim.tStats then
			tLogData.sAttackTarget = self.rVictim:getUniqueID()
		end
        local nAttackType = self.rChar:getAttackType()
		-- raiders
		if self.rChar:isHostileToPlayer() then
			-- attacking a door?
			if self.rVictim.sUniqueName then
				logType = Log.tTypes.RAIDER_ATTACK_DOOR
			else
				logType = Log.tTypes.ENTER_COMBAT_RAIDER
			end
		elseif nAttackType == Character.ATTACK_TYPE.Ranged then
			logType = Log.tTypes.ENTER_COMBAT_RANGED
		else
			logType = Log.tTypes.ENTER_COMBAT_MELEE
		end
		Log.add(logType, self.rChar, tLogData)
	end
end

function AttackEnemy:_updateAttack(dt)
    if self.bGrappling then
        return self:_updateGrapple(dt)
    elseif self.bShooting then
        return self:_updateShoot(dt)
    end
end

function AttackEnemy:handleGenericAnimEvent(sAnimEventName, tParameters)
    if sAnimEventName == "FireProjectile" then
        local sJointName = Character.DEFAULT_PROJECTILE_ATTACH_JOINT
        if tParameters and tParameters.sJointName then sJointName = tParameters.sJointName end
        
        local tOffset = Character.DEFAULT_PROJECTILE_ATTACH_OFFSET
        if tParameters and tParameters.tOffset then tOffset = tParameters.tOffset end
    
        self:_fireProjectile(sJointName, tOffset)
    end
end

function AttackEnemy:_fireProjectile(sAttachJointName, tOffset)
    self.rChar:shootAt(self.rVictim, sAttachJointName, tOffset)
    
    -- Spread Combat Awareness
    self:_spreadCombatAwareness()
end

function AttackEnemy:_shoot()
    -- look at target
    local tx,ty = self.rVictim:getLoc()
    self.rChar:playAnim(AttackEnemy.RANGED_ATTACK_SHOOT, true)
    self.rChar:faceWorld(tx,ty, false)
    --self.bShooting = true
    --self.nShootingTimeElapsed = 0
end

function AttackEnemy:_updateShoot(dt)
    -- Play idle if we aren't playing shoot
    if not self.rChar:isPlayingAnim(self.RANGED_ATTACK_SHOOT) then self.rChar:playAnim(self.RANGED_ATTACK_IDLE) end
        
    local bCoolingDown = self.nShootingTimeElapsed > self.nNextShootAimTime
    self.nShootingTimeElapsed = self.nShootingTimeElapsed + dt

    if bCoolingDown then
        if self.nShootingTimeElapsed > self.nNextShootAimTime + self.nNextShootCooldownTime then
            self.bShooting = false
        end
    elseif not bCoolingDown and self.nShootingTimeElapsed > self.nNextShootAimTime then
        -- Re-check LoS
        if self:_lineOfSight(self.rChar,self.rVictim) then
            self:_shoot()
        else
            self.bShooting = false
        end
    end

    return true
end

function AttackEnemy:_updateGrapple(dt)
    if self.nAttackDuration and self.nAttackDuration > 0 then
        self.nAttackDuration = self.nAttackDuration - dt
        if self.nAttackDuration <= 0 then
            self.bGrappling = false
            if self.bPuppeteering then
                -- verify we still have the victim before we assign damage.
                self.bPuppeteering = self.rVictim and self.rVictim:getCurrentTaskName() == 'Puppet'
            end
            if self.bPuppeteering or self.rChar:isAdjacentToObj(self.rVictim) then
                self:_assignDamage()
            end
            if self.bPuppeteering then
                self:_releasePuppet()
            end
        end
        return true
    end
    return false
end

function AttackEnemy:_assignDamage()
        self.rVictim:takeDamage(self.rChar, self.rChar:getAttackDamage())
        if self.bTargetFighting then
            self.rChar:takeDamage(self.rVictim, self.rVictim:getAttackDamage())
        end
    
    -- Spread Combat Awareness
    self:_spreadCombatAwareness()
end

function AttackEnemy:_attemptGrapple(dt)
    if self.rChar:isAdjacentToObj(self.rVictim) then
        local tx,ty = self.rVictim:getLoc()
        self.rChar:playAnim('melee')
        self.rChar:faceWorld(tx,ty)
        self.nAttackDuration = self.GRAPPLE_DURATION
        self.bGrappling = true

        if ObjectList.getObjType(self.rVictim) == ObjectList.CHARACTER and self.rVictim:canMelee() and self.rVictim:forcePuppet(self.rChar) then
            local cx,cy = self.rChar:getLoc()
            self.rVictim:faceWorld(cx,cy)

            if self.rVictim.tStats.tPersonality.nBravery > .4 then
                self.bTargetFighting = true
                self.rVictim:playAnim('melee')
            else
                self.rVictim:playAnim('cower')
            end

            self.bPuppeteering = true
        end
        return true
    end
end

function AttackEnemy:_lineOfSight(rChar,rTarget)
    local cx,cy,cw = rChar:getTileLoc()
    local tx,ty,tw = rTarget:getTileLoc()
    return cw == tw and MiscUtil.isoDist(cx,cy,tx,ty) < rChar:getAttackRange(rTarget) and (cx ~= tx or cy ~= ty) and GridUtil.CheckLineOfSight(cx,cy,tx,ty)
end

function AttackEnemy:_attemptRangedAttack()
    local cx,cy = self.rChar:getLoc()
    local cTileX, cTileY = World._getTileFromWorld(cx,cy)
    local tx,ty = self.rVictim:getLoc()
    local tTileX, tTileY = World._getTileFromWorld(tx,ty)
    
    if self:_lineOfSight(self.rChar,self.rVictim) then
        -- Ranged attack valid
        if not self.rChar:isPlayingAnim(self.RANGED_ATTACK_SHOOT) then self.rChar:playAnim(self.RANGED_ATTACK_IDLE) end
        self.rChar:faceWorld(tx,ty, false)
        self.bShooting = true
        self.nShootingTimeElapsed = 0
        self.nNextShootAimTime = DFMath.randomFloat(self.SHOOT_AIM_TIME_RANGE[1],self.SHOOT_AIM_TIME_RANGE[2])
        self.nNextShootCooldownTime = DFMath.randomFloat(self.SHOOT_COOLDOWN_RANGE[1],self.SHOOT_COOLDOWN_RANGE[2])
        return true
    end
end

function AttackEnemy:_attemptAttack(dt)
    if not self.rVictim then return false end
    local _,_,vw = self.rVictim:getTileLoc()
    local _,_,w = self.rChar:getTileLoc()
    if w and vw and w ~= vw then return false end

    local bAttacked=false

    -- Keep this up to date in case our lethality settings, inventory, etc. have changed
    self.rChar:setWeaponDrawn(true,self.rVictim)

    local nAttackType = self.rChar:getAttackType()
    if nAttackType == Character.ATTACK_TYPE.Grapple then
        bAttacked = self:_attemptGrapple()
    elseif nAttackType == Character.ATTACK_TYPE.Ranged then
        bAttacked = self:_attemptRangedAttack()
    else
        assert(false)
    end
    if bAttacked and self.rChar:getTeam() == Character.TEAM_ID_PLAYER then
        Room.visibilityBlip(self.rVictim:getTileLoc())
    end
    return bAttacked
end

function AttackEnemy:_followTarget(dt)
    if self.tPath then
        local bDone, obsTX,obsTY = self:tickWalk(dt)
        
        -- constantly recalc the space paths, since we haven't implemented proper following.
        if self.tPath and self.tPath.bSpacewalkingPath and GameRules.elapsedTime - self.tPath.nStartTime > 4 then
            bDone = true
        end
        
        if bDone then
            self.tPath = nil
        end
    else
        local cx,cy,_,cw = self.rChar:getLoc()
        local targetX,targetY,_,targetW = self.rVictim:getLoc()
        local ctx,cty = self.rChar:getTileLoc()
        local targetTX,targetTY = self.rVictim:getTileLoc()

        -- We haven't 3d-ified pathfinding dests, so for this case (elevated target) we just beeline spacewalk to our target.
        if targetW and targetW ~= 1 then 
            if self.rChar:spacewalking() and g_World._getTileValue(ctx,cty) == g_World.logicalTiles.SPACE then
                local tPath = Pathfinder.createSpacewalkPath(cx,cy,targetX,targetY,self.rChar)
                if tPath then
                    tPath.bSpacewalkingPath = true
                    tPath.nStartTime = GameRules.elapsedTime
                    self:setPath(tPath)
                    return true
                end
            end
        end

        local bAllowAdjacent=true
        if ctx == targetTX and cty == targetTY then
            -- we don't want to be on the same tile
            bAllowAdjacent=false
            local bFound = false
            for i=2,9 do 
                local atx,aty = g_World._getAdjacentTile(targetTX,targetTY,i)
                if g_World._isPathable(atx,aty) then 
                    targetX,targetY = g_World._getWorldFromTile(atx,aty,targetW)
                    bFound=true
                    break
                end
            end
            if not bFound then return false end
        end

        if not self:createPath(cx,cy,targetX,targetY,bAllowAdjacent,true) then
            return false
        end
    end
    return true
end

function AttackEnemy:_spreadCombatAwareness(tx,ty,tw)
    Room.spreadCombatAwareness(self.rChar, self.rChar:getTileLoc())
    if self.rChar:hasUtilityStatus(Character.STATUS_RAMPAGE_VIOLENT) and self.rChar:getTeam() == self.rVictim:getTeam() then
        -- On a rampage, and now everybody knows it.
        -- Avoiding the memory system for now, since it doesn't seem like it'd be reasonably forgotten over the short term.
        self.rChar.tStatus.bRampageObserved = true
    end
end

function AttackEnemy:_releasePuppet()
    -- The extra tests here are because some things can break the character out, e.g. vacuum or getting a broken leg.
    if self.bPuppeteering and self.rVictim and self.rVictim:getCurrentTaskName() == 'Puppet' then
        self.rVictim:releasePuppet()
    end
    self.bPuppeteering = false        
end

function AttackEnemy:onComplete(bSuccess)
    self:_releasePuppet()
    self.rChar:setWeaponDrawn(false)
    Task.onComplete(self,bSuccess)
end

function AttackEnemy:onUpdate(dt)
    if self.rVictim then
        if ObjectList.getObjType(self.rVictim) == ObjectList.CHARACTER then
            if not self.rChar:shouldTargetForAttack(self.rVictim) then 
                self.rChar:clearMemory('sLastAttackEnemyName')
                return true
            end
        elseif ObjectList.getObjType(self.rVictim) == ObjectList.ENVOBJECT then
            if self.rVictim.nCondition <= 0 or self.rVictim.bDestroyed then
                self.rChar:clearMemory('sLastAttackEnemyName')
                return true
            end
        end
    end
	
	if self.rChar:isPlayingAnim('startle') then
    elseif self:_updateAttack(dt) then
    elseif self:_attemptAttack(dt) then
    elseif self:_followTarget(dt) then
    else
        self.rChar:storeMemory('sLastAttackEnemyName', self.rVictim:getUniqueID())
        self:interrupt("Can't attack/reach enemy.")
    end
end

return AttackEnemy
