local Class=require('Class')
local GameRules=nil

local Camera = Class.create(nil, MOAICamera.new)

function Camera:init()
    GameRules=require('GameRules')
    self.nCameraShakeX = 0
    self.nCameraShakeY = 0
end

function Camera:shake(nMag,nDuration)
    self.nCameraShakeEnd = GameRules.elapsedTime+nDuration
    self.nCameraShakeMagnitude = nMag
end

function Camera:tick(dt)
    if self.nCameraShakeEnd then
        local x,y,z = self:getLoc()
        if self.nCameraShakeEnd < GameRules.elapsedTime then
            self.nCameraShakeEnd = nil
            self.nCameraShakeX = 0
            self.nCameraShakeY = 0
        elseif not self.nLastCameraShake or GameRules.elapsedTime - self.nLastCameraShake > 0 then
            self.nLastCameraShake = GameRules.elapsedTime
            self.nCameraShakeX = (math.random()-.5)*2*self.nCameraShakeMagnitude
            self.nCameraShakeY = (math.random()-.5)*2*self.nCameraShakeMagnitude
        end
        self:setLoc(x,y,z)
    end
end

function Camera:setLoc(x,y,z)
    self._UserData.setLoc(self,x+self.nCameraShakeX,y+self.nCameraShakeY,z)
end

function Camera:getLoc()
    if self.nCameraShakeEnd then
        local x,y,z = self._UserData.getLoc(self)
        return x-self.nCameraShakeX,y-self.nCameraShakeY,z
    else
        return self._UserData.getLoc(self)
    end
end

return Camera

