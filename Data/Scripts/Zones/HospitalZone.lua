local ObjectList=require('ObjectList')
local Class=require('Class')
local MiscUtil=require('MiscUtil')
local CharacterManager=require('CharacterManager')
local Zone=require('Zones.Zone')
local Room=require('Room')
local ActivityOptionList=require('Utility.ActivityOptionList')
g_ActivityOption=g_ActivityOption or require('Utility.ActivityOption')
local GameRules=require('GameRules')
local Character=require('CharacterConstants')
local World=require('World')

local HospitalZone = Class.create(Zone)

function HospitalZone:init(rRoom)
    Zone.init(self,rRoom)
    self.tOnDutyDoctors = {}
    self.nOnDutyDoctors = 0
    self.bTestedDocs = false
end

function HospitalZone:doctorsOnDuty()
    if not self.bTestedDocs then
        for rDoc,_ in pairs(self.tOnDutyDoctors) do
            if rDoc:isDead() or not rDoc:onDuty() or rDoc:getJob() ~= Character.DOCTOR or rDoc.bDestroyed then
                self:removeDoctor(rDoc)
            end
        end
        self.bTestedDocs = true
    end
    return self.nOnDutyDoctors
end

function HospitalZone:addDoctor(rDoc)
    if not self.tOnDutyDoctors[rDoc] then
        self.tOnDutyDoctors[rDoc] = 1
        self.nOnDutyDoctors = self.nOnDutyDoctors + 1
    end
end

function HospitalZone:removeDoctor(rDoc)
    if self.tOnDutyDoctors[rDoc] then
        self.tOnDutyDoctors[rDoc] = nil
        self.nOnDutyDoctors = self.nOnDutyDoctors - 1
    end
end

function HospitalZone:onTick(dt)
    Zone.onTick(self,dt)
    self.bTestedDocs = false
end

return HospitalZone
