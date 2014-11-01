local Task=require('Utility.Task')
local Class=require('Class')
local Log=require('Log')
local Room = require('Room')
local World=require('World')
local EnvObject=require('EnvObjects.EnvObject')
local CharacterConstants=require('CharacterConstants')

local EatPlant = Class.create(Task)

EatPlant.HARVEST_DURATION = 2
EatPlant.EAT_DURATION = 5
EatPlant.nDuration = EatPlant.HARVEST_DURATION + EatPlant.EAT_DURATION + 1

function EatPlant:init(rChar,tPromisedNeeds,rActivityOption)
    Task.init(self,rChar,tPromisedNeeds,rActivityOption)
    self.rTarget = rActivityOption.tData.rTargetObject
    self:setPath(rActivityOption.tBlackboard.tPath)
end

function EatPlant:onUpdate(dt)
    if self:interacting() then
        if self:tickInteraction(dt) then
            self.rTarget:eatMe()
            self.bHasFood = true
            local r = self.rChar:getRoom()
            if r and r ~= Room.getSpaceRoom() then
                local tx,ty = self.rChar:getNearbyTile()
                if tx then
                    local wx,wy = g_World._getWorldFromTile(tx,ty)
                    local cx,cy = self.rChar:getLoc()
                    self:createPath(cx,cy,wx,wy, true)
                end
            end
        end
    elseif self.tPath then
        self:tickWalk(dt)
        if not self.tPath and not self.bReachedPlant then
            self.bReachedPlant = true
            if not self:attemptInteractWithObject('interact',self.rTarget,self.HARVEST_DURATION) then
                self:interrupt('failed to reach plant')
            end
        end
    elseif self.nPlayingAnim then
        self.nPlayingAnim = self.nPlayingAnim - dt
        if self.nPlayingAnim <= 0 then
            return true
        end
    elseif self.bHasFood then
        self.nPlayingAnim = self.EAT_DURATION
        self.rChar:playAnim("eat_vegetable")
    else
        assert(false)
    end
end

return EatPlant
