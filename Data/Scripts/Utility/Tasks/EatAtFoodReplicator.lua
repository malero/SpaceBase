local Task=require('Utility.Task')
local Class=require('Class')
local Log=require('Log')
local Room = require('Room')
local Malady = require('Malady')
local World=require('World')
local EnvObject=require('EnvObjects.EnvObject')
local Character=require('CharacterConstants')

local EatAtFoodReplicator = Class.create(Task)

--EatAtFoodReplicator.emoticon = 'sleep'
EatAtFoodReplicator.replicatorOffset = {x=55, y=60}
EatAtFoodReplicator.replicatorOffsetFlipped = {x=55, y=25}
EatAtFoodReplicator.replicatorDir = World.directions.SW
EatAtFoodReplicator.replicatorDirFlipped = World.directions.E

EatAtFoodReplicator.PHASE_WALKTO_REPLICATOR = 0
EatAtFoodReplicator.PHASE_BUYFOOD = 1
EatAtFoodReplicator.PHASE_WALKTO_TILE = 2
EatAtFoodReplicator.PHASE_EATFOOD = 3

local kBUY_DURATION = 2
local kEAT_DURATION = 12
local kBUY_ANIM = 'interact'

function EatAtFoodReplicator:init(rChar,tPromisedNeeds,rActivityOption)
    self.super.init(self,rChar,tPromisedNeeds,rActivityOption)
    self.duration = kBUY_DURATION + kEAT_DURATION
    self.rTarget = rActivityOption.tData.rTargetObject
    assert(rActivityOption.tBlackboard.rChar == rChar)
    assert(rActivityOption.tBlackboard.rTargetObject == self.rTarget)
    self:setPath(rActivityOption.tBlackboard.tPath)
    self:_setPhase(EatAtFoodReplicator.PHASE_WALKTO_REPLICATOR)
end

function EatAtFoodReplicator:_setPhase(nPhase)
    if nPhase == EatAtFoodReplicator.PHASE_WALKTO_REPLICATOR then
        self.bInterruptOnPathFailure = true
    elseif nPhase == EatAtFoodReplicator.PHASE_BUYFOOD then
        self.bInterruptOnPathFailure = false
        local bSuccessful, sReason = self:_buyFood()
        if not bSuccessful then
            self:interrupt(sReason)
            return
        end
    elseif nPhase == EatAtFoodReplicator.PHASE_WALKTO_TILE then
        self:unreserve()
        local bSuccessful, sReason = self:_goToTileToEat()
        if not bSuccessful then
            self:interrupt(sReason)
            return
        end
    elseif nPhase == EatAtFoodReplicator.PHASE_EATFOOD then
        self:_eat()
    end
    self.nCurPhase = nPhase
end

function EatAtFoodReplicator:_buyFood()
    self.nBuyFoodDuration = 0
    if self.rTarget then
        -- charge the player
        if not self.nReplicatorPrice then
            local rData = EnvObject.getObjectData('FoodReplicator')
            if rData then
                self.nReplicatorPrice = rData.nFoodPrice or 0
            end
        end
        if g_GameRules.getMatter() >= self.nReplicatorPrice then
            g_GameRules.expendMatter(self.nReplicatorPrice)
        else
            -- need to bail out
            return false, 'insufficient matter for food'
        end

        -- snap character to replicator
        local x,y = self.rTarget:getLoc()
        if self.rTarget.bFlipX then
            self.rChar:setLoc(x + self.replicatorOffsetFlipped.x, y + self.replicatorOffsetFlipped.y)
        else
            self.rChar:setLoc(x + self.replicatorOffset.x, y + self.replicatorOffset.y)
        end
        -- face up and left or up and right
        local tileX, tileY = World._getTileFromWorld(x, y)
        local dir = EatAtFoodReplicator.replicatorDir
        if self.rTarget.bFlipX then
            dir = EatAtFoodReplicator.replicatorDirFlipped
        end
        local faceX, faceY = World._getAdjacentTile(tileX, tileY, dir)
        self.rChar:faceTile(faceX, faceY)

        Malady.interactedWith(self.rChar,self.rTarget)

        -- play the get food anim and charge
        self.rChar:playAnim(kBUY_ANIM, true)
    end
    return true
end

function EatAtFoodReplicator:_updateBuyFood(dt)
    self.duration = self.duration - dt
    self.nBuyFoodDuration = self.nBuyFoodDuration + dt
    if self.nBuyFoodDuration >= kBUY_DURATION then
        return true
    end
    return false
end

function EatAtFoodReplicator:_goToTileToEat()
    if self.rTarget then
        local rRoom = self.rTarget:getRoom()
        if rRoom and rRoom ~= Room.getSpaceRoom() then
            local tx,ty = self.rChar:getNearbyTile()
            if tx then
                local x, y = g_World._getWorldFromTile(tx,ty)
                local cx,cy = self.rChar:getLoc()
                if not self:createPath(cx,cy,x,y, true) then
                    print("EatAtFoodReplicator: couldn't reach tile to eat")
                    return false, "couldn't reach tile to eat"
                end
            else
                return true
            end
        end
    end
    return true
end

function EatAtFoodReplicator:_eat()
    self.nEatDuration = 0
    self.rChar:playAnim("eat_replicator")
end

function EatAtFoodReplicator:_updateEatFood(dt)
    self.duration = self.duration - dt
    self.nEatDuration = self.nEatDuration + dt
    if self.nEatDuration >= kEAT_DURATION then
        return true
    end
    return false
end

function EatAtFoodReplicator:onUpdate(dt)
    if self.nCurPhase == EatAtFoodReplicator.PHASE_WALKTO_REPLICATOR then
        if self:tickWalk(dt) then
            self:_setPhase(EatAtFoodReplicator.PHASE_BUYFOOD)
        end
    elseif self.nCurPhase == EatAtFoodReplicator.PHASE_BUYFOOD then
        if self:_updateBuyFood(dt) then
            self:_setPhase(EatAtFoodReplicator.PHASE_WALKTO_TILE)
        end
    elseif self.nCurPhase == EatAtFoodReplicator.PHASE_WALKTO_TILE then
        if self:tickWalk(dt) then
            self:_setPhase(EatAtFoodReplicator.PHASE_EATFOOD)
        end
    elseif self.nCurPhase == EatAtFoodReplicator.PHASE_EATFOOD then
        if self:_updateEatFood(dt) then
			-- if we were starving, reset timer (stave off death!)
			if self.rChar.tStatus.nStarveTime > 0 then
				self.rChar.tStatus.nStarveTime = 0
			end
            -- spaceface log replicator eating
             --make sure this is the first time they've spawned
            if self.rChar:isHostileToPlayer() then
				Log.add(Log.tTypes.ENEMY_EAT_REPLICATOR, self.rChar)
            else
                Log.add(Log.tTypes.EAT_REPLICATOR, self.rChar)
            end
			-- gourmands hate replicator food
			if self.rChar.tStats.tPersonality.bGourmand then
				self.rChar:angerEvent(Character.REPLICATOR_FOOD)
			end
            return true -- done
        end
    end
    return false
end

return EatAtFoodReplicator
