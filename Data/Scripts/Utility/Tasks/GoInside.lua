local Task=require('Utility.Task')
local Class=require('Class')
local Pathfinder=require('Pathfinder')
local Log=require('Log')
local Oxygen=require('Oxygen')
local Character=require('CharacterConstants')
local Room=require('Room')
local Airlock=require('Zones.Airlock')
local OptionData=require('Utility.OptionData')

local GoInside = Class.create(Task)

local Task=require('Utility.Task')
local Class=require('Class')
local Log=require('Log')

local GoInside = Class.create(Task)

GoInside.STAGE_WALK_TO_DOOR = 1
GoInside.STAGE_WAIT_FOR_OPEN = 2
GoInside.STAGE_WALK_TO_LOCKER = 3
GoInside.STAGE_WAIT_FOR_CLOSE = 4
GoInside.STAGE_WAIT_FOR_FINISHED = 5
GoInside.STAGE_DROP_OFF = 6

function GoInside:init(rChar,tPromisedNeeds,rActivityOption)
    self.super.init(self,rChar,tPromisedNeeds,rActivityOption)
    self.duration = 5
    self.nPriority = OptionData.tPriorities.SURVIVAL_NORMAL
    self.rAirlockZone = rActivityOption.tData.rAirlockZone
    self.dropOffX,self.dropOffY = rActivityOption.tData.dropOffX,rActivityOption.tData.dropOffY
    self.rLocker = rActivityOption.tData.rLocker
    assert(rActivityOption.tBlackboard.rChar == rChar)
    self:setPath(rActivityOption.tBlackboard.tPath)
    self.nStage = GoInside.STAGE_WALK_TO_DOOR
end

function GoInside:onUpdate(dt)
    if self.rAirlockZone.bDestroyed then 
        self:interrupt('airlock disappeared.')
        return
    end
    if not self.rAirlockZone.bFunctional then
        self:interrupt('non-functional airlock')
        return
    end
    if self.rLocker.bDestroyed then
        self:interrupt('locker disappeared.')
        return
    end

    if self.nStage == GoInside.STAGE_WALK_TO_DOOR then
        if self:tickWalk(dt) then
            self.nStage = self.nStage+1
        end
    elseif self.nStage == GoInside.STAGE_WAIT_FOR_OPEN then
        if self.rAirlockZone:canGoOutside() or not self.rChar:spacewalking() then
            --local x1,y1 = self.rLocker:getLoc()
            local x1,y1 = self.rLocker:getAccessWorldLoc()
            local x0,y0 = self.rChar:getLoc()
            local tPath = x1 and Pathfinder.getPath(x0,y0,x1,y1,self.rChar)
            if not tPath then
                -- We REALLY don't want to fail here, because the pathing system depends on a functional airlock actually being functional.
                -- So we'll first try any adjacent tile to the locker, and then if that fails, just a random point in the airlock.
                x1,y1 = self.rLocker:getLoc()
                tPath = Pathfinder.getPath(x0,y0,x1,y1,self.rChar,{bPathToNearest=true})
                if not tPath then
                    x1,y1 = self.rAirlockZone.rRoom:randomLocInRoom(false,true)
                    if x1 and y1 then
                        tPath = Pathfinder.getPath(x0,y0,x1,y1,self.rChar)
                        if not tPath then
                            self:interrupt('no path')
                            return
                        end
                    end
                end
            end
            self:setPath(tPath)
            self.nStage = self.nStage+1
			self.nEntryAttempts = 0
        else
            self.rAirlockZone:requestOpen()
        end
    elseif self.nStage == GoInside.STAGE_WALK_TO_LOCKER then
        if not self.rChar:spacewalking() or self:tickWalk(dt) then
            self.nStage = self.nStage+1
        end
    elseif self.nStage == GoInside.STAGE_WAIT_FOR_CLOSE then
        local r = Room.getRoomAt(self.rChar:getLoc())
		if self.rChar:isElevated() or r ~= self.rAirlockZone.rRoom then
			self:interrupt('character failed to enter airlock')
			return
		end
        if self.rAirlockZone:isSafe(self.rChar) then
            if not self.rChar:isElevated() then
                if Oxygen.getOxygen(self.rChar:getLoc()) > Character.OXYGEN_LOW then
                    if not self.rChar:getCurrentTask():requireSpacesuit() then
                        self.rChar:spacesuitOff()
                    end
                    self.nStage = self.nStage+1
                end
            end
        end
    elseif self.nStage == GoInside.STAGE_WAIT_FOR_FINISHED then
        if not self.rAirlockZone.bRunning then
            if self.dropOffX then
                local x1,y1 = self.dropOffX, self.dropOffY
                local x0,y0 = self.rChar:getLoc()
                local tPath = Pathfinder.getPath(x0,y0,x1,y1,self.rChar)
                if tPath then
                    self:setPath(tPath)
                else
                    local tx,ty = g_World._getTileFromWorld(self.dropOffX,self.dropOffY)
                    self:interrupt('failed to path to drop-off point')
                end
            end
            self.nStage = self.nStage+1
        end
    elseif self.nStage == GoInside.STAGE_DROP_OFF then
        if self:tickWalk(dt) then
            return true
        end
    end
end

return GoInside
