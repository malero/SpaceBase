local Task=require('Utility.Task')
local DFMath=require('DFCommon.Math')
local World=require('World')
local GameRules=require('GameRules')
local Class=require('Class')
local Log=require('Log')
local Malady=require('Malady')
local MiscUtil=require('MiscUtil')
local DFUtil = require('DFCommon.Util')
local Character=require('CharacterConstants')

local FieldScanAndHeal = Class.create(Task)
FieldScanAndHeal.HEAL_DURATION = 25

function FieldScanAndHeal:init(rChar, tPromisedNeeds, rActivityOption)
    Task.init(self,rChar,tPromisedNeeds,rActivityOption)
    self.rTargetObject = rActivityOption.tData.rTargetObject
    self.rPatient = self.rTargetObject
    self.nNextTimeoutTest=GameRules.elapsedTime+15
    self:setPath(rActivityOption.tBlackboard.tPath)
    self.rPatient:setPendingCoopTask('GetFieldScanned',rChar)
	assert(self.rPatient and self.rChar)
	assert(self.rChar ~= self.rPatient)
end


function FieldScanAndHeal:_testScanOrHeal()
    if self.rPatient:getCurrentTaskName() ~= 'GetFieldScanned' then return false end
    -- if anyone's still walking, let them finish first.
    if self.tPath or (self.rPatient and self.rPatient.rCurrentTask and self.rPatient.rCurrentTask.rPath) then 
        return false 
    end
    
    if not self.bScanned then
        if self:attemptInteractWithObject('maintain', self.rPatient, self.HEAL_DURATION) then
            return true
        end
    else
        local bHPInjury = self:_hpToHeal() ~= nil
        local sName,tData = Malady.getNextCurableMalady(self.rPatient,self.rChar:getJobLevel(Character.DOCTOR))
        if not bHPInjury and not sName then
            return false
        end
        if self:attemptInteractWithObject('maintain', self.rPatient, self.HEAL_DURATION) then
            self.sCurrentMalady = sName or 'HitPoints'
            return true
        end
    end
end

function FieldScanAndHeal:onComplete(bSuccess)
    Task.onComplete(self, bSuccess)
    self.rChar:playAnim('breathe')
    if self.rPatient.rCurrentTask and self.rPatient.rCurrentTask.scanComplete then
        self.rPatient.rCurrentTask:scanComplete(self.rChar, bSuccess)
    end
end

function FieldScanAndHeal:_followTarget(dt)
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

function FieldScanAndHeal:_getLogData(sMaladyName)
	local tLogData
    if sMaladyName == 'HitPoints' then
        local sLineCode = (self.rPatient:getHealth() == Character.STATUS_HURT and 'DISEAS031TEXT') or 'DISEAS030TEXT'
        tLogData = {
	        sPatient = self.rPatient.tStats.sName,
	        sDoctor = self.rChar.tStats.sName,
	        sDisease = g_LM.line(sLineCode),
        }
    elseif sMaladyName then
        tLogData = {
		    sPatient = self.rPatient.tStats.sName,
		    sDoctor = self.rChar.tStats.sName,
		    sDisease = Malady.getFriendlyName(sMaladyName),
	    }
    else
        tLogData = {
		    sPatient = self.rPatient.tStats.sName,
		    sDoctor = self.rChar.tStats.sName,
	    }
    end
	return tLogData
end

function FieldScanAndHeal:_performScanOn(rPatient)
	local bFoundSomething = false
    local bMissedSomething = false
    if rPatient.tStatus.tMaladies then
        for sName,tInfo in pairs(rPatient.tStatus.tMaladies) do
            if not tInfo.bDiagnosed then
                local bSuper = self.rChar:getInventoryItemOfTemplate('SuperDoctorTool')
                if bSuper or self:getJobSuccess(Character.DOCTOR) then
                    tInfo.bDiagnosed = true
                    Malady.diseaseEncountered(tInfo,rPatient)
                else
                    self.rChar:angerEvent(Character.ANGER_JOB_FAIL_MAJOR)
                end
            end
        end
    end
	-- in case of successful/clean scan
	if not bFoundSomething and not self:_hpToHeal() then
		local tLogData = self:_getLogData()
		Log.add(Log.tTypes.DUTY_DOCTOR_SCAN_HEALTHY, self.rChar, tLogData)
		Log.add(Log.tTypes.HEALTH_CITIZEN_SCAN, rPatient, tLogData)
	end
    return bMissedSomething
end

function FieldScanAndHeal:_healPerformed(sMalady,rPatient)
    local nHP,nMaxHP = rPatient:getHP()
    if sMalady == 'HitPoints' then
        local nHP = DFMath.lerp(10,60,self.rChar:getJobCompetency(Character.DOCTOR))
        if self.rChar:getInventoryItemOfTemplate('SuperDoctorTool') then
            nHP = nHP*2
        end
        rPatient:healHP(nHP)
        rPatient:storeMemory(Malady.MEMORY_HP_HEALED_RECENTLY,Malady.FIELD_HP_COOLDOWN)
    else
        rPatient:cure(sMalady)
    end
	local sLogType = Log.tTypes.DUTY_DOCTOR_HEAL_ILLNESS
	-- healing an injury?
	if Malady.isInjury(sMalady) then
		sLogType = Log.tTypes.DUTY_DOCTOR_HEAL_BROKEN_LEG
    elseif sMalady == 'HitPoints' then
        if nHP < Character.HURT_THRESHOLD then
            sLogType = Log.tTypes.DUTY_DOCTOR_HEAL_HP_MAJOR
        else
            sLogType = Log.tTypes.DUTY_DOCTOR_HEAL_HP_MINOR
        end
	end
	local tLogData = self:_getLogData(sMalady)
	Log.add(sLogType, self.rChar, tLogData)
	-- citizen getting healed uses a more generic "i'm better" log for now
	Log.add(Log.tTypes.HEALTH_CITIZEN_HEAL_ILLNESS, rPatient, tLogData)
end

function FieldScanAndHeal:_hpToHeal()
    local nHP,nMaxHP = self.rPatient:getHP()
    if nHP < nMaxHP then
        if self.rPatient:retrieveMemory(Malady.MEMORY_HP_HEALED_RECENTLY) == nil then
            return math.min(nMaxHP - nHP, DFMath.lerp(10,60,self.rChar:getJobCompetency(Character.DOCTOR)))
        end
    end
end

function FieldScanAndHeal:onUpdate(dt)
    local bValid,sFailure = self:_testCoopStillValid('GetFieldScanned')
    if not bValid then
        self:interrupt(sFailure)
        return
    end
    if self.bComplete then return end

    local bHPInjury = self:_hpToHeal() ~= nil
    if not bHPInjury and self.bScanned and not Malady.getNextCurableMalady(self.rPatient,self.rChar:getJobLevel(Character.DOCTOR)) then
        return true
    end

    if self:interacting() then
        if self:tickInteraction(dt) then
            if not self.bScanned then
                self:_performScanOn(self.rPatient)
	            self.bScanned = true
            else
                self:_healPerformed(self.sCurrentMalady,self.rPatient)
                self.sCurrentMalady = nil
            end
            bHPInjury = self:_hpToHeal() ~= nil
            if not bHPInjury and not Malady.getNextCurableMalady(self.rPatient,self.rChar:getJobLevel(Character.DOCTOR)) then
                return true
            end
        end
    elseif self:_testScanOrHeal() then
        self.rPatient.rCurrentTask:doctorWorking(self.bScanned)
    else 
        self:_followTarget(dt)
    end
end

return FieldScanAndHeal
