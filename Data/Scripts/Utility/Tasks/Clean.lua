local Task=require('Utility.Task')
local Class=require('Class')
local Log=require('Log')
local Character=require('CharacterConstants')

local Clean = Class.create(Task)

--Clean.emoticon = 'clean' --doesn't exist yet

function Clean:init(rChar,tPromisedNeeds,rActivityOption)
    self.super.init(self,rChar,tPromisedNeeds,rActivityOption)
end

function Clean:onUpdate(dt)
    if not self.bDone then
        -- try to finish
    else
        -- be done
        return true    
    end
end

return Clean

