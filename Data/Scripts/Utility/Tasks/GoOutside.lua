local Task=require('Utility.Task')
local Class=require('Class')
local Pathfinder=require('Pathfinder')
local Log=require('Log')
local Airlock=require('Zones.Airlock')
local Room=require('Room')

local GoOutside = Class.create(Task)

GoOutside.STAGE_WALK_TO_LOCKER = 1
GoOutside.STAGE_PUT_ON_SUIT = 2
GoOutside.STAGE_WAIT = 3
GoOutside.STAGE_GO_OUTSIDE = 4

function GoOutside:init(rChar,tPromisedNeeds,rActivityOption)
    self.super.init(self,rChar,tPromisedNeeds,rActivityOption)
    self.duration = 5
    self.rAirlockZone = rActivityOption.tData.rAirlockZone
    self.rLocker = rActivityOption.tData.rLocker
    self.dropOffX,self.dropOffY = rActivityOption.tData.dropOffX,rActivityOption.tData.dropOffY
    assert(rActivityOption.tBlackboard.rChar == rChar)
    self:setPath(rActivityOption.tBlackboard.tPath)
    self.nStage = GoOutside.STAGE_WALK_TO_LOCKER
    if self.rChar:wearingSpacesuit() then
        local tx,ty,tw = self.rChar:getTileLoc()
        if Room.getRoomAtTile(tx,ty,tw) == self.rAirlockZone.rRoom then
            self.nStage = GoOutside.STAGE_WAIT
        end
    end
end

function GoOutside:onUpdate(dt)
    if self.rAirlockZone.bDestroyed then 
        self:interrupt('airlock disappeared')
        return
    end
    if not self.rAirlockZone.bFunctional then
        self:interrupt('airlock stopped being functional')
        return
    end
    if self.rLocker.bDestroyed then
        self:interrupt('locker disappeared')
        return
    end

    if self.nStage == GoOutside.STAGE_WALK_TO_LOCKER then
        if self:tickWalk(dt) then
            self.nStage = self.nStage+1
        end
    elseif self.nStage == GoOutside.STAGE_PUT_ON_SUIT then
        local tileX, tileY = g_World._getTileFromWorld(self.rChar:getLoc())
        if g_World.isAdjacentToObj(tileX, tileY, false, self.rLocker, true) then
            self.rChar:spacesuitOn()
            self.nStage = self.nStage+1
        else
            self:interrupt('no spacesuit')
        end
    elseif self.nStage == GoOutside.STAGE_WAIT then
        if self.rAirlockZone:canGoOutside() then
            local x1,y1
            if self.dropOffX then
                x1,y1 = self.dropOffX, self.dropOffY
            else
                x1,y1 = self.rAirlockZone:getExteriorTile()
            end
            local x0,y0 = self.rChar:getLoc()
            local tPath = Pathfinder.getPath(x0,y0,x1,y1,self.rChar)
            if not tPath then
                self:interrupt('no path outside')
                return
            end
            self:setPath(tPath)
            self.nStage = self.nStage+1
        else
            self.rAirlockZone:requestOpen()
        end
    elseif self.nStage == GoOutside.STAGE_GO_OUTSIDE then
        if self:tickWalk(dt) then
            return true
        end
    end
end

return GoOutside
