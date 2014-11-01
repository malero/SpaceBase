local Task=require('Utility.Task')
local Fire=require('Fire')
local Class=require('Class')
local World=require('World')
local CharacterConstants=require('CharacterConstants')

local ExtinguishFireBareHanded = Class.create(Task)

ExtinguishFireBareHanded.MIN_DOUSE_AMOUNT = 1.0
ExtinguishFireBareHanded.MAX_DOUSE_AMOUNT = 1.25
--ExtinguishFireBareHanded.emoticon = 'alert'
ExtinguishFireBareHanded.animation = 'fight_fire_unarmed'
ExtinguishFireBareHanded.CHANCE_TO_CATCH_FIRE = 0.05 -- Per second fighting fires bare handed
ExtinguishFireBareHanded.sWalkOverride = 'run'

function ExtinguishFireBareHanded:init(rChar,tPromisedNeeds,rActivityOption)
    Task.init(self,rChar,tPromisedNeeds,rActivityOption)
    --self.super.init(self,rChar,tPromisedNeeds,rActivityOption)
    self.nDouseAmount = self:getDuration(ExtinguishFireBareHanded.MIN_DOUSE_AMOUNT, ExtinguishFireBareHanded.MAX_DOUSE_AMOUNT, CharacterConstants.EMERGENCY)
    self.extinguishAnim = ExtinguishFireBareHanded.animation
    assert(rActivityOption.tBlackboard.rChar == rChar)
    self:setPath(rActivityOption.tBlackboard.tPath)
end

function ExtinguishFireBareHanded:_tryToExtinguish()
    local wx,wy = Fire.getNearbyFire(self.rChar:getLoc())
    if wx then
        self.targetX,self.targetY = wx,wy
        self.tx, self.ty = World._getTileFromWorld(wx,wy)
        self.bExtinguishing = true
        self.rChar:playAnim(self.extinguishAnim)
        self.rChar:faceWorld(wx,wy)
        return true
    end
end

function ExtinguishFireBareHanded:onUpdate(dt)
    if not self.bExtinguishing then
        self:_tryToExtinguish()
    end

    if self.bExtinguishing then
        if Fire.douseTile(self.tx, self.ty, self.nDouseAmount * dt) then
            self.rChar:extinguishedFire()
            return true
        elseif self.extinguishAnim == ExtinguishFireBareHanded.animation then
            -- can catch fire if trying to put a fire out by hand
            if not self.nTimeBetweenCatchingFireChances then self.nTimeBetweenCatchingFireChances = 0 end
            if self.nTimeBetweenCatchingFireChances > 1 then
                if math.random() < ExtinguishFireBareHanded.CHANCE_TO_CATCH_FIRE then
                    self.rChar:catchFire()
                end
                self.nTimeBetweenCatchingFireChances = self.nTimeBetweenCatchingFireChances - 1
            else
                self.nTimeBetweenCatchingFireChances = self.nTimeBetweenCatchingFireChances + dt
            end
        end
    elseif self.tPath then
        self:tickWalk(dt)
    else
        self:interrupt("not extinguishing, and no path.")
    end
end

return ExtinguishFireBareHanded

