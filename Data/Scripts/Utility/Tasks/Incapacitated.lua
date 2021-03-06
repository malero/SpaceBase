local Task=require('Utility.Task')
local Class=require('Class')
local Log=require('Log')
local Malady=require('Malady')
local OptionData=require('Utility.OptionData')
local CharacterConstants=require('CharacterConstants')

local Incapacitated = Class.create(Task)

function Incapacitated:init(rChar,tPromisedNeeds,rActivityOption)
    self.super.init(self,rChar,tPromisedNeeds,rActivityOption)
    self.duration = 9999
    if self.rChar.tStatus.bCuffed then
        self.rChar:playAnim("incapacitated_cuffed")
    elseif self.rChar.tMaladies and self.rChar.tMaladies['BrokenLeg'] then
        self.rChar:playAnim("incapacitated")
    else
        self.rChar:playAnim("sleep")
    end
end

function Incapacitated:onUpdate(dt)
    if self.rChar:getPendingTaskName() or not Malady.isIncapacitated(self.rChar) then
        return true
    end
end

-- semi-hack: we don't want Incapacitated taking priority in the decision-making process in UtilityAI, or else it blocks GetFieldScanned from
-- being picked. But once it's running we don't want Character thinking it needs a higher pri task like "put out a fire".
-- We might be able to nuke this hack once we unify testing survival threats w/ finding tasks we can use to address the threats, since in
-- this character's case there would be nothing they could do about the survival threats.
function Incapacitated:getPriority()
    return OptionData.tPriorities.PUPPET
end

-- Yeah, we're not really doing anything important, but we aren't up for much fun.
function Incapacitated:availableForInterruption(sProposedQueuedTaskName)
    if sProposedQueuedTaskName == 'GetFieldScanned' then
        return true
    else
        return false
    end
end

return Incapacitated
