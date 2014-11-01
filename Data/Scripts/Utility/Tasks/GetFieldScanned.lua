local Class = require('Class')
local Task = require('Utility.Task')
local GameRules = require('GameRules')
local Malady = require('Malady')

local GetFieldScanned = Class.create(Task)

function GetFieldScanned:init(rChar,tPromisedNeeds,rActivityOption)
    Task.init(self, rChar, tPromisedNeeds, rActivityOption)
    self.rTargetObject = rActivityOption.tData.rTargetObject
    self.nNextTimeoutTest=GameRules.elapsedTime+15
    if not Malady.isIncapacitated(self.rChar) then
        self:setPath(rActivityOption.tBlackboard.tPath)
    else
        self.rChar:playAnim("sleep")
    end
	assert(self.rTargetObject and self.rChar)
	assert(self.rChar ~= self.rTargetObject)
end

function GetFieldScanned:doctorWorking(bHealing)
    self.tPath = nil
    if not Malady.isIncapacitated(self.rChar) then
        self.rChar:playAnim('breathe')
        self:attemptInteractWithObject('breathe', self.rTargetObject, 999999)
    end
    self.bScanInProgress = true
end

function GetFieldScanned:scanComplete(rDoctor, bSuccess)
    self.bScanComplete = true
end

function GetFieldScanned:onComplete(bSuccess)
    Task.onComplete(self,bSuccess)
    if bSuccess then
        self.rChar:storeMemory('LastCheckup',GameRules.elapsedTime,120*60)
    end
end

function GetFieldScanned:_followTarget(dt)
    if self:_hackyFollowTimeoutTest(dt) then
        self:interrupt('timed out')
        return
    end
    if self.tPath then
        if self:tickWalk(dt) then
            self.tPath = nil
            self.rChar:playAnim('breathe')
        end
    end
end

function GetFieldScanned:onUpdate(dt)
    if self.bScanComplete then
        return true
    end
    if self.bScanInProgress then
        return
    end

    local bValid, sFailure = self:_testCoopStillValid('FieldScanAndHeal')
    if not bValid then
        self:interrupt(sFailure)
        return
    end

    self:_followTarget(dt)
end


return GetFieldScanned

