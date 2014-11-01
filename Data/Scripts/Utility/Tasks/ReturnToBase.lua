local Task=require('Utility.Task')
local World=require('World')
local Class=require('Class')
local Room=require('Room')

local ReturnToBase = Class.create(Task)

function ReturnToBase:init(rChar,tPromisedNeeds,rActivityOption)
    self.super.init(self,rChar,tPromisedNeeds,rActivityOption)
    self.duration = 5
    assert(rActivityOption.tBlackboard.tPath)
    self:setPath(rActivityOption.tBlackboard.tPath)
end

function ReturnToBase:onUpdate(dt)
    if self:tickWalk(dt) then
        return true
    end
    local tx,ty,tw = self.rChar:getTileLoc()
    local rRoom = Room.getRoomAtTile(tx,ty,tw)
    if rRoom and rRoom:getTeam() == self.rChar:getTeam() then
        return true
    end
end

return ReturnToBase
