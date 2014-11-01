local Class=require('Class')
local Effect=require('Effect')
local Fire=require('Fire')

local Flame = Class.create(Effect, MOAIProp.new)

Flame.EFFECT_LIST = {'Effects/Fire/flame01'}

function Flame:init(wx,wy, attachEntity, nInitialIntensity)
    Effect.init(self, Flame.EFFECT_LIST, wx, wy, attachEntity, nil, {0,64,0})
    self.nIntensity = nInitialIntensity
    self.rAttachedTo=attachEntity
end

function Flame:extinguish()
    local wx,wy = self:getLoc()
    Fire._flameRemoved(wx,wy,self,self.rAttachedTo)
    self:remove()
end

function Flame:douse(nDouseAmount)
    self.nIntensity = self.nIntensity - nDouseAmount
    return self.nIntensity <= 0
end

return Flame

