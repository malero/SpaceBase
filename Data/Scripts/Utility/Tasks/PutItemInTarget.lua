local Task=require('Utility.Task')
local Class=require('Class')
local Log=require('Log')
local Character=require('CharacterConstants')
local GameRules = require('GameRules')

local PutItemInTarget = Class.create(Task)

function PutItemInTarget:init(rChar,tPromisedNeeds,rActivityOption)
    self.super.init(self,rChar,tPromisedNeeds,rActivityOption)
    self.nDuration = 2
    self.sObjectKey = rActivityOption.tData.sObjectKey
    self.rTargetObject = rActivityOption.tData.rTargetObject
    self:setPath(rActivityOption.tBlackboard.tPath)
end

function PutItemInTarget:onUpdate(dt)
    local sItemKey = self.rChar:getDisplayItem()
    if not sItemKey then
        self:interrupt('no items to display')
        return
    end

    if self:interacting() then
        if self:tickInteraction(dt) then
            self.rChar:transferItemTo(self.rTargetObject,sItemKey)
            return true
        end
    elseif self.tPath then
        self:tickWalk(dt)
    else
        if self:attemptInteractWithObject('interact',self.rTargetObject,self.nDuration) then
            -- wait until completion
        else
            self:interrupt('Unable to reach dropoff point.')
        end
    end
end

return PutItemInTarget
