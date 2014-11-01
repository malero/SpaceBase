local Task=require('Utility.Task')
local Class=require('Class')
local World=require('World')
local CommandObject=require('Utility.CommandObject')
local EnvObject=require('EnvObjects.EnvObject')
local GameRules=require('GameRules')
local Inventory=require('Inventory')

local DestroyEnvObject = Class.create(Task)

--DestroyEnvObject.emoticon = 'work'

function DestroyEnvObject:init(rChar,tPromisedNeeds,rActivityOption)
    self.super.init(self,rChar,tPromisedNeeds,rActivityOption)
    self.duration = 6
    self.bForResearch = rActivityOption.tData.bForResearch
    self.rTarget = rActivityOption.tData.rTargetObject
    self.targetTX,self.targetTY,self.targetTW = self.rTarget:getTileLoc()
    self.bRequiresCommand=rActivityOption.tData.bRequiresCommand -- so we don't destroy the object if the command goes away
    assert(rActivityOption.tBlackboard.rChar == rChar)
    assert(rActivityOption.tBlackboard.rTargetObject == self.rTarget)
    self:setPath(rActivityOption.tBlackboard.tPath)
end

function DestroyEnvObject:_tryToDestroy()
    if not self:_commandStillValid() then
        return false
    end

    if self.rChar:isElevated() then return false end

    local cx,cy = self.rChar:getLoc()
    local tx,ty = self.rTarget:getLoc()
    if World.areWorldCoordsAdjacent(cx,cy,tx,ty,true,true) then
        self.bDestroying = true
        self.rChar:playAnim('vaporize')
        self.rChar:faceWorld(tx,ty)
        self.duration = 3
        return true
    end
end

function DestroyEnvObject:_commandStillValid()
    if self.rTarget.bDestroyed then return false end

    if self.bRequiresCommand then
        local cmd = CommandObject.getCommandAtWorld(self.rTarget:getLoc())
        if not cmd or not cmd.bValid then return false end
    end
    return true
end

function DestroyEnvObject:onUpdate(dt)
    if self.rTarget.bDestroyed then
        self:interrupt('already destroyed')
        return
    end
    
    if self.bDestroying then
        self.duration = self.duration - dt
        if self.duration < 0 then
            if self:_commandStillValid() then
                if self.bForResearch then
                    local tCube = self.rTarget.tInventory and self.rTarget.tInventory['Research Datacube']
                    if tCube and tCube.sResearchData then
                        Inventory.createItem('ResearchDatacube', tCube.sResearchData)
                    end
                else
                    -- refund partial cost of object                
                    local nCost = self.rTarget:getVaporizeCost()
                    if nCost then
                        GameRules.addMatter(nCost)
                    end
                end
                self.rTarget:remove()
                return true
            else
                self:interrupt()
                return
            end
        end
    elseif self.tPath then
        self:tickWalk(dt)
    else
        if not self:_tryToDestroy() then
            -- We don't handle a moving target right now, because right now no objects move.
            self:interrupt('moving target?')
        end
    end
end

function DestroyEnvObject:onComplete(bSuccess)
    Task.onComplete(self,bSuccess)
    if not bSuccess and self.targetTX then
        -- MTF HACK: occasionally we get a stranded command for an object that's already destroyed.
        -- Not sure how it's happening; for now we retest on failures to hack-fix.
        local cmd = CommandObject.getCommandAtTile(self.targetTX,self.targetTY)
        if cmd then
            cmd:retestCommandValidity()
        end
    end
end

return DestroyEnvObject
