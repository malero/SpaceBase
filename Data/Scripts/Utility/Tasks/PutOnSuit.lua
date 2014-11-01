local Task=require('Utility.Task')
local Class=require('Class')
local Log=require('Log')
local World=require('World')
local Character=require('CharacterConstants')

local PutOnSuit = Class.create(Task)

function PutOnSuit:init(rChar,tPromisedNeeds,rActivityOption)
    self.super.init(self,rChar,tPromisedNeeds,rActivityOption)
            assertdev(not rChar:wearingSpacesuit())
            assertdev(not rChar:spacewalking())
    self.duration = math.random(Character.SLEEP_DURATION*.9, Character.SLEEP_DURATION*1.1)
    self.rTarget = rActivityOption.tData.rTargetObject
    assertdev(rActivityOption.tBlackboard.rChar == rChar)
    assertdev(rActivityOption.tBlackboard.rTargetObject == self.rTarget)
    assertdev(rActivityOption.tBlackboard.tPath)
    
    local tx,ty = self.rChar:getTileLoc()
    assertdev(tx == rActivityOption.tBlackboard.tPath.tPathNodes[1].tx)
    assertdev(ty == rActivityOption.tBlackboard.tPath.tPathNodes[1].ty)
    
    if rActivityOption.tBlackboard.tPath then
        self:setPath(rActivityOption.tBlackboard.tPath) 
    end
end

function PutOnSuit:onUpdate(dt)
    if self.rChar:wearingSpacesuit() then
        -- MTF HACK: characters will sometimes decide to spacewalk to an airlock to put on a suit.
        return true
    end

    if self.nInteracting then
        if self:tickInteraction(dt) then
            local tx,ty = self.rChar:getTileLoc()
            if g_World.isAdjacentToObj(tx,ty, true, self.rTarget, true) then
                self.rChar:spacesuitOn()
                return true
            else
                self:interrupt('failed interaction with locker')
            end
        end
    elseif self:tickWalk(dt) then
        if not self:attemptInteractWithObject('interact', self.rTarget, 1, true) then
            self:interrupt('failed to start interaction with locker')
        end
    end
end

return PutOnSuit
