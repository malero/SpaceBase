local Task=require('Utility.Task')
local World=require('World')
local Class=require('Class')
local Room=require('Room')
local Log=require('Log')
local Character=require('Character')
local DFMath=require('DFCommon.Math')
local UtilityAI=require('Utility.UtilityAI')
local MaintainPub = Class.create(Task)

function MaintainPub:init(rChar,tPromisedNeeds,rActivityOption)
    self.super.init(self,rChar,tPromisedNeeds,rActivityOption)
    self.duration = math.random(45,60)
    self.rPub = rActivityOption.tData.rPub
    self:setPath(rActivityOption.tBlackboard.tPath)
end

function MaintainPub:_idle()
    self.idleTime = DFMath.randomFloat(.5,1.5)
    self.currentTaskIdle = true
    self.rChar:playAnim('breathe')
end

function MaintainPub:_gatherPubJobs()
    local r = self.rChar:getRoom()
    local tJobs = {}
    if r and r == self.rPub.rRoom then
	    for rProp,_ in pairs(r:getProps()) do
            local tList = rProp:getAvailableActivities()
            for i,rOption in ipairs(tList) do
                
                if rOption:getTag(self.rChar,'WorkShift') == true and rOption:getAdvertisedData() and rOption:getTag(self.rChar,'Job') == Character.BARTENDER then
                    table.insert(tJobs, rOption)
                end
            end
        end
    end

    return { {tUtilityOptions=tJobs} }
end

function MaintainPub:_lookForWork()
    local tGatherers = {MaintainPub={ gatherFn=function() return self:_gatherPubJobs() end } }
    local rNewOption,nNewUtility, logStr = UtilityAI.getBestTask(self.rChar,self.rChar:getCurrentTaskPriority(),true,tGatherers)
    if rNewOption then
        local rTask = rNewOption:createTask(self.rChar, nNewUtility, UtilityAI.DEBUG_PROFILE)
        self:chainTaskRef(rTask)
        return true
    end
end

function MaintainPub:_walk()
    local r = self.rPub.rRoom
    if not r then
        self:interrupt('Pub zone lost its room.')
        return
    end
    local tx,ty,tw
    if r == self.rChar:getRoom() then
        tx,ty,tw = self.rChar:getNearbyTile()
    else
        tx,ty,tw = r:randomLocInRoom(true,true,true)
    end
    if tx then
        local x,y = g_World._getWorldFromTile(tx,ty)
        local cx,cy = self.rChar:getLoc()
        if self:createPath(cx,cy,x,y) then
            self.currentTaskIdle = false
        else
            self:interrupt('Character cannot path to random loc.')
            return
        end    
    end
end

function MaintainPub:onUpdate(dt)
    self.duration = self.duration - dt

    if self.currentTaskIdle then
        self.idleTime = self.idleTime - dt
        if self.duration < 0 then
            if not self:_lookForWork() then
                self:interrupt()
            end
        elseif self.idleTime < 0 then
            self:_lookForWork()
            self:_walk()
        end
    else
        if self:tickWalk(dt) then
            self:_lookForWork()
            self:_idle()
        end
    end
end

return MaintainPub
