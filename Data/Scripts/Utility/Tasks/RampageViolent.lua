local Task=require('Utility.Task')
local World=require('World')
local Class=require('Class')
local Room=require('Room')
local Log=require('Log')
local Character=require('Character')
local CharacterManager=require('CharacterManager')
local UtilityAI=require('Utility.UtilityAI')
local RampageViolent = Class.create(Task)

function RampageViolent:init(rChar,tPromisedNeeds,rActivityOption)
    self.super.init(self,rChar,tPromisedNeeds,rActivityOption)
    self:createPath(rActivityOption.tBlackboard.tPath)
end

function RampageViolent:_gatherActivityOptions()
    --[[
    --TODO: Gather tasks. (Currently copy-pasted from OpenPub)
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
    ]]--
end

function RampageViolent:_startNewTask()
    local tGatherers = {Tasks={ gatherFn=function() return self:_gatherActivityOptions() end } }
    local rNewOption,nNewUtility, logStr = UtilityAI.getBestTask(self.rChar,self.rChar:getCurrentTaskPriority(),true,tGatherers)
    if rNewOption then
        local rTask = rNewOption:createTask(self.rChar, nNewUtility, UtilityAI.DEBUG_PROFILE)
        self:queueTaskRef(rTask)
        return true
    end
end

function RampageViolent:_testComplete()
    local nPop = CharacterManager.getOwnedCitizenPopulation()
    if nPop <= 1 then
        return true
    end
end

function RampageViolent:onUpdate(dt)
    if self:_testComplete() then
        if not self.bComplete then
            return true
        end
        return
    end
    if not self:_startNewTask() then
        local nPop = CharacterManager.getOwnedCitizenPopulation()
        if nPop > 1 then
            self:interrupt('Exiting rampage before everyone is dead.')
        else
            return true
        end
    end
end

function RampageViolent:onComplete(bSuccess)
    Task.onComplete(self,bSuccess)
    -- if interrupted for whatever reason, cap our anger slightly below max.
    self.rChar.tStatus.nAnger = math.min(self.rChar.tStatus.nAnger, .9*Character.ANGER_MAX)
end

return RampageViolent
