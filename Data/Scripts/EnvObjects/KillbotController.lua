local Class=require('Class')
local EnvObject=require('EnvObjects.EnvObject')
local ObjectList=require('ObjectList')

local KillbotController = Class.create(EnvObject, MOAIProp.new)

function KillbotController:onTick(dt)
    EnvObject.onTick(self,dt)
    if self.rRoom and self.spriteSheet and self.spriteName then
        if self.spriteName then
            local bFlipX = self.bFlipX
            local spriteName = self.spriteName
            
            local index = self.spriteSheet.names[spriteName] 
            if index then
                self:setIndex(index)

                local x,y = EnvObject.getSpriteLoc(self.sName,self.wx,self.wy,bFlipX,self.bFlipY)
                self._UserData:setLoc(x,y,self.wz)
                self:setScl((bFlipX and -1) or 1,1)
            end
        end
    end
end

function KillbotController:getCustomInspectorName()
    return 'KillbotControllerControls'
end

function KillbotController:remove()
    if self.rRoom then
        self.rRoom:onEmergencyAlarmDestroyed()
    end
    EnvObject.remove(self)
end

function KillbotController:onConditionSet()
    if self.nCondition <= 0 then
        if self.rRoom then
            self.rRoom:onEmergencyAlarmDestroyed()
        end        
    end
end

return KillbotController

