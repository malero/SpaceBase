local Task=require('Utility.Task')
local Class=require('Class')
local Log=require('Log')
local Malady=require('Malady')
local World=require('World')
local FieldScanAndHeal=require('Utility.Tasks.FieldScanAndHeal')
local GameRules=require('GameRules')
local Character=require('CharacterConstants')

local BedHeal = Class.create(FieldScanAndHeal)

function BedHeal:init(rChar,tPromisedNeeds,rActivityOption)
    Task.init(self,rChar,tPromisedNeeds,rActivityOption)
    self.rTargetObject = rActivityOption.tData.rTargetObject
    self.bInterruptOnPathFailure = true
    self.rPatient = self.rTargetObject and self.rTargetObject.rUser
    assert(rActivityOption.tBlackboard.rChar == rChar)
    assert(rActivityOption.tBlackboard.rTargetObject == self.rTargetObject)
    self:setPath(rActivityOption.tBlackboard.tPath)
end

function BedHeal:_performDoctorWork()
    if not self.rTargetObject.rUser or self.rTargetObject.rUser ~= self.rPatient then
        self:interrupt('Occupant left bed.')
        return
    end

    if not self.bScanned then
        local bMissedSomething = self:_performScanOn(self.rPatient)
        self.bScanned = not bMissedSomething
    else
        local sName = self:_getNextWork()
        if sName then
            self:_healPerformed(sName,self.rPatient)
        end
        if not self:_getNextWork() then
            return true
        end
    end
end

function BedHeal:_getNextWork()
        local sName = Malady.getNextCurableMalady(self.rPatient, Malady.MAX_SKILL)
        if not sName then
            local nHP,nMaxHP = self.rPatient:getHP()
            if nHP < nMaxHP then sName = 'HitPoints' end
        end
        return sName
end

function BedHeal:onUpdate(dt)
    if self.rTargetObject.bDestroyed then
        self:interrupt('Bed destroyed.')
        return
    end
    if not self.rTargetObject.rUser or self.rPatient ~= self.rTargetObject.rUser then
        self:interrupt('Patient left bed.')
        return
    end
    
	if self:interacting() then 
        if self:tickInteraction(dt) then
            if self:_performDoctorWork() then
                self.rPatient:clearMemory(Character.MEMORY_SENT_TO_HOSPITAL) 
                return true
            end
        end
    elseif self:tickWalk(dt) then
        local tx,ty,tw = self.rTargetObject:getTileLoc()
        -- MTF: we interact with the tile, not the bed, because we don't want to clobber the bed's user, who is the patient.
        if not self:attemptInteractWithTile('maintain',tx,ty,self.HEAL_DURATION) then
            self:interrupt('Failed to reach bed.')
        end
    end
end

function BedHeal:onComplete(bSuccess)
    if self.rPatient == self.rTargetObject.rUser and self.rPatient then
        self.rPatient:clearMemory(Malady.MEMORY_HP_HEALED_RECENTLY)
    end
    Task.onComplete(self, bSuccess)
end

return BedHeal

