local Class = require('Class')
local Task = require('Utility.Task')

local Puppet = Class.create(Task)

function Puppet:init(rChar,tPromisedNeeds,rActivityOption)
    Task.init(self, rChar, tPromisedNeeds, rActivityOption)
    self.rMarionette = rActivityOption.tData.rMarionette
end

function Puppet:release()
    self.bPuppetReleased = true
end

function Puppet:onUpdate(dt, dtRaw)
    return self.bPuppetReleased
end

return Puppet

