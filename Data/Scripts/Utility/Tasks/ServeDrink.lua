local Task=require('Utility.Task')
local World=require('World')
local Class=require('Class')
local Room=require('Room')
local Log=require('Log')
local CharacterConstants=require('CharacterConstants')
local Malady = require('Malady')

local ServeDrink = Class.create(Task)

ServeDrink.emoticon = 'beer'

ServeDrink.DURATION_MIN = 3
ServeDrink.DURATION_MAX = 5

function ServeDrink:init(rChar,tPromisedNeeds,rActivityOption)
    Task.init(self, rChar, tPromisedNeeds, rActivityOption)
    self.duration = math.random(ServeDrink.DURATION_MIN, ServeDrink.DURATION_MAX)
    self.rBar = rActivityOption.tData.rBar
    self.nBarTX,self.nBarTY = rActivityOption.tData.barTX,rActivityOption.tData.barTY
    self.nBarSlot = rActivityOption.tData.nBarSlot
    self:setPath(rActivityOption.tBlackboard.tPath)
end

function ServeDrink:onComplete(bSuccess)
    Task.onComplete(self,bSuccess)
	Log.add(Log.tTypes.DUTY_SERVE_DRINK, self.rChar)
end

function ServeDrink:onUpdate(dt)
    if self:interacting() then
        if self.bDone then
            return true
        elseif self:tickInteraction(dt) then
            Malady.interactedWith(self.rChar,self.rBar)
            self.rBar:drinkServed(self.nBarSlot)
            if not self:attemptInteractWithTile('breathe', self.nBarTX, self.nBarTY, 2) then
                self.bDone = true
            else
                return true
            end
        end
    elseif self:tickWalk(dt) then
        self:attemptInteractWithTile('bartender_mix', self.nBarTX, self.nBarTY, self.duration)
	end
end

return ServeDrink
