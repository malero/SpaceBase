local Class=require('Class')
local EnvObject=require('EnvObjects.EnvObject')
local ObjectList=require('ObjectList')

local EmergencyAlarm = Class.create(EnvObject, MOAIProp.new)

function EmergencyAlarm:onTick(dt)
    EnvObject.onTick(self,dt)
    if self.rRoom and self.spriteSheet and self.spriteName then
        if self.spriteName then
            local bFlipX = self.bFlipX
            local spriteName = self.spriteName
            
            if self.rRoom:isEmergencyAlarmOn() then
                if self.bFlipX then
                    spriteName = spriteName..'_on_flip'
                    bFlipX = false
                else
                    spriteName = spriteName..'_on'
                end
            end
            
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

function EmergencyAlarm:getCustomInspectorName()
    return 'EmergencyAlarmControls'
end

function EmergencyAlarm:remove()
    if self.rRoom then
        self.rRoom:onEmergencyAlarmDestroyed()
    end
    EnvObject.remove(self)
end

function EmergencyAlarm:onConditionSet()
    if self.nCondition <= 0 then
        if self.rRoom then
            self.rRoom:onEmergencyAlarmDestroyed()
        end        
    end
end

return EmergencyAlarm

