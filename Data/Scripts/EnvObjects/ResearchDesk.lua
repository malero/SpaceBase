local Class=require('Class')
local GameRules=require('GameRules')
local Character=require('CharacterConstants')
local EnvObject=require('EnvObjects.EnvObject')
local ObjectList=require('ObjectList')
local ActivityOptionList=require('Utility.ActivityOptionList')
g_ActivityOption=g_ActivityOption or require('Utility.ActivityOption')

local ResearchDesk = Class.create(EnvObject, MOAIProp.new)

ResearchDesk.PROBABILITY_FIRE_ON_DESTROY = 0.25

function ResearchDesk:init(sName, wx, wy, bFlipX, bFlipY, bForce, tSaveData, nTeam)
    EnvObject.init(self,sName, wx,wy, bFlipX, bFlipY, bForce, tSaveData, nTeam)

    local tData=
    {
        rTargetObject=self,
        utilityGateSelf=self,
        utilityGateFn=function(rChar, rAO) return self:researchGate(rChar,rAO) end,
		bInfinite=false,
    }
    self.rResearchOption = g_ActivityOption.new('ResearchInLab',tData)
	
	tData=
	{
		rTargetObject=self,
        bNoPathToNearestDiagonal=true,
        utilityGateFn=function(rChar,rAO)
            return self:_collectGate(rChar,rAO)
        end,
	}
	self.rDeliverOption = g_ActivityOption.new('DeliverResearchDatacube',tData)
end

function ResearchDesk:_collectGate(rChar,rAO)
	if not self.bActive then
		return false, 'deactivated'
	end
    return true
end

function ResearchDesk:researchGate(rChar,rAO)
	if not self.bActive then
		return false, 'deactivated'
	end
    if self.rRoom and self.rRoom.zoneObj.getResearchStatus then
        local sResearching = self.rRoom.zoneObj:getResearchStatus()
        if sResearching then
            return true
        else
            return false, 'room has no ongoing research'
        end
    end

    return false, 'not in a research zone'
end

function ResearchDesk:getAvailableActivities()
    local tActivities = EnvObject.getAvailableActivities(self)
    table.insert(tActivities, self.rResearchOption)
    table.insert(tActivities, self.rDeliverOption)
    return tActivities
end

return ResearchDesk
