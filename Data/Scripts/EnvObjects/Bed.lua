local Class=require('Class')
local EnvObject=require('EnvObjects.EnvObject')
local ObjectList=require('ObjectList')
local Base=require('Base')
local Character=require('CharacterConstants')

local Bed = Class.create(EnvObject, MOAIProp.new)

function Bed:init(sName, wx, wy, bFlipX, bFlipY, bForce, tSaveData, nTeam)
    EnvObject.init(self,sName, wx,wy, bFlipX, bFlipY, bForce, tSaveData, nTeam)

    local tData=
    {
        rTargetObject=self,
        utilityGateFn=function(rChar)
            local rOwner = self:getOwner()
            if rOwner and rOwner ~= rChar then
                return false, 'not your bed'
            end
            local r = self:getRoom()
            if not r then return false, 'no room' end
            if r:getZoneName() == 'BRIG' then
                if not rChar:inPrison() then return false, 'character not in prison' end
            end
            return true
        end,
        utilityOverrideFn=function(rChar,rAO,nOriginalUtility) 
            local rOwner = self:getOwner()
            if rOwner and rOwner == rChar then
                return nOriginalUtility
            elseif rOwner then
                return 0
            else
                local tLastBed = rChar:retrieveMemory(Character.MEMORY_LAST_BED)
                local rBed = tLastBed and ObjectList.getObject(tLastBed)
                if rBed == self then
                    return nOriginalUtility - .5
                end
                return nOriginalUtility - 1
            end
        end,
    }
    self.rSleepInBedOption = g_ActivityOption.new('SleepInBed',tData)
end

function Bed:getOwner()
    local rOwner = nil
    local tCharTag = Base.tBedToChar[self.tag]
    if tCharTag then
        rOwner = ObjectList.getObject(tCharTag)
        if not rOwner or rOwner:isDead() then
            Base.assignBed(nil,self)
            rOwner = nil
        end
    end
    return rOwner
end

function Bed:getResidenceString()
    local r = self:getRoom()
    if not self.bDestroyed and r and r:getZoneName() == 'RESIDENCE' then
        return r.uniqueZoneName
    end
    return g_LM.line('INSPEC168TEXT')
end

function Bed:setOwner(rChar)
    if rChar and rChar:isDead() then rChar = nil end
    Base.assignBed(rChar,self)
end

function Bed:getSaveTable(xShift,yShift)
    local t = EnvObject.getSaveTable(self,xShift,yShift)
    if self.ownerTag then
        t.ownerTag = ObjectList.getTagSaveData(self.ownerTag)
    end
    return t
end

function Bed:getAvailableActivities()
    local tActivities = EnvObject.getAvailableActivities(self)
    table.insert(tActivities, self.rSleepInBedOption)
    return tActivities
end



return Bed
