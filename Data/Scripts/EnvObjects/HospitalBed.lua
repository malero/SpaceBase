local Class=require('Class')
local GameRules=require('GameRules')
local Character=require('CharacterConstants')
local OptionData=require('Utility.OptionData')
local EnvObject=require('EnvObjects.EnvObject')
local ObjectList=require('ObjectList')
local Malady=require('Malady')
local CharacterManager=require('CharacterManager')
local ActivityOptionList=require('Utility.ActivityOptionList')
g_ActivityOption=g_ActivityOption or require('Utility.ActivityOption')

local HospitalBed = Class.create(EnvObject, MOAIProp.new)

function HospitalBed:init(sName, wx, wy, bFlipX, bFlipY, bForce, tSaveData, nTeam)
    EnvObject.init(self,sName, wx,wy, bFlipX, bFlipY, bForce, tSaveData, nTeam)

    local tData=
    {
        rTargetObject=self,
        priorityOverrideFn=function(rChar,rAO,nOriginalPri) 
            if rChar:getPerceivedDiseaseSeverity(true) == 1 or rChar:retrieveMemory(Character.MEMORY_SENT_TO_HOSPITAL) then
                return OptionData.tPriorities.SURVIVAL_LOW 
            else
                return OptionData.tPriorities.NORMAL
            end
        end,
        utilityGateFn=function(rChar)
            if rChar.tStatus.tAssignedToBrig or rChar:inPrison() then
                return false, 'brigged'
            end

            if rChar:retrieveMemory(Character.MEMORY_SENT_TO_HOSPITAL) then return true end
            if rChar:getPerceivedDiseaseSeverity(true) == 0 then
                return false, 'not perceived to be sick' 
            end
            -- See if a doc is on duty.
            if not self:isOperational(true) then
                return 0, 'not functional or no doctors on duty'
            end
            return true
        end,
        -- the 0.01 is for characters sent to the hospital via the UI
        utilityOverrideFn=function(rChar,rAO,nOriginalUtility) 
            return rChar:getPerceivedDiseaseSeverity(true) * 20 + nOriginalUtility + .01
        end,
    }
    self.rCheckInToHospitalOption = g_ActivityOption.new('CheckInToHospital',tData)

    local tData=
    {
        rTargetObject=self,
        utilityGateFn=function(rChar)
            if self.rUser ~= nil then
                return true
            end
            return false, 'nobody in bed'
        end,
        customNeedsFn=function(rDoctor,rAO) return Malady.diseaseHealNeedsOverride(rDoctor,rAO,self.rUser) end
    }
    self.rBedHealOption = g_ActivityOption.new('BedHeal',tData)
end

function HospitalBed:isOperational(bRequireOnDutyDoctor)
    if self.bDestroyed or not self:isFunctioning() or self:shouldDestroy() or self:slatedForTeardown(true) or self:slatedForTeardown() then
        return false
    end
    if self.nInoperationalUntil and self.nInoperationalUntil > GameRules.elapsedTime then
        return false
    end

    local r = self:getRoom()
    local zo = r and r:getZoneObj()
    if not zo or not zo.doctorsOnDuty then
        return false
    end
    if bRequireOnDutyDoctor and zo:doctorsOnDuty() == 0 then
        return false
    end
    return true
end

function HospitalBed:isImmuneTo()
    return true
end

function HospitalBed:eject()
    self.nInoperationalUntil = GameRules.elapsedTime+5
end

function HospitalBed:getAvailableActivities()
    local tActivities = EnvObject.getAvailableActivities(self)
	table.insert(tActivities, self.rCheckInToHospitalOption)
	table.insert(tActivities, self.rBedHealOption)
    return tActivities
end

return HospitalBed

