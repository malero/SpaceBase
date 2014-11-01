local Task=require('Utility.Task')
local Class=require('Class')

local WalkTo = Class.create(Task)

function WalkTo:init(rChar,tPromisedNeeds,rActivityOption)
    self.super.init(self,rChar,tPromisedNeeds,rActivityOption)
    self:setPath(rActivityOption.tBlackboard.tPath)
end

function WalkTo:onUpdate(dt)
    if self.tPath then
        self:tickWalk(dt)
    else
        return true
    end
end

return WalkTo
