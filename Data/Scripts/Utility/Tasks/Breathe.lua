-- Temp testing activity.
-- Character just stands around and does nothing.
-- Should not be used in shipping game.

local Task=require('Utility.Task')
local Class=require('Class')
local DFMath=require('DFCommon.Math')

local Breathe = Class.create(Task)

function Breathe:init(rChar,tPromisedNeeds,rActivityOption)
    self.super.init(self,rChar,tPromisedNeeds,rActivityOption)
    self.duration = DFMath.randomFloat(1,3)
    rChar:playAnim("breathe")
end

function Breathe:onUpdate(dt)
    self.duration = self.duration - dt    
    if self.duration < 0 then
        return true
    end
end

return Breathe
