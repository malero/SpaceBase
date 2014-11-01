local Task=require('Utility.Task')
local Class=require('Class')
local Character=require('CharacterConstants')
local Log=require('Log')
local EnvObject = require('EnvObjects.EnvObject')
local Pickup = require('Pickups.Pickup')
local ResearchData = require('ResearchData')
local Base = require('Base')
local Malady = require('Malady')

local Cuff = Class.create(Task)

function Cuff:init(rChar,tPromisedNeeds,rActivityOption)
    Task.init(self,rChar,tPromisedNeeds,rActivityOption)
    self.rTargetObject = rActivityOption.tData.rTargetObject
    self:setPath(rActivityOption.tBlackboard.tPath)
    self.nAttempts = 0
end

function Cuff:onUpdate(dt)
    if self:interacting() then
        if self:tickInteraction(dt) then
            -- let's auto-cure this for now, to make it easier to get to the brig.
            self.rTargetObject:cure('KnockedOut')

            self.rTargetObject:cuff()
            return true
        end
    elseif self.tPath then
        self:tickWalk(dt)
    else
        local tx,ty = g_World._getTileFromWorld(self.rTargetObject:getLoc())
        if self:attemptInteractWithObject('interact', self.rTargetObject, 1,true) then
            -- wait until completion
        else
            if self.nAttempts < 2 then
                self.nAttempts = self.nAttempts+1
                local tPath = self:createPathTo(self.rTargetObject)
                if not tPath then
                    self:interrupt('Unable to reach dest.')
                end
            else
                self:interrupt('Unable to reach dest.')
            end
        end
    end
end

return Cuff
