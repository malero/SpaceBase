local Util = require('DFCommon.Util')
local Class = require('Class')
local SeqCommand = require('SeqCommand')
local AnimEvent = require('AnimEvent')
local AeFootstep = Class.create(AnimEvent)
local Effect = require('Effect')

local CoFootstepArea = require('Components.CoFootstepArea')
local ParticleSystem = require('ParticleSystem')

local DFSchema = require('DFCommon.DFSchema')
local tFields = Util.deepCopy(AnimEvent.rSchema.tFieldSchemas)

AeFootstep.rSchema = DFSchema.object(
	tFields,
	"Creates a footstep effect."
)
SeqCommand.addEditorSchema('AeFootstep', AeFootstep.rSchema)

-- VIRTUAL FUNCTIONS --
function AeFootstep:onExecute()
	
    -- Destroy the previous effect
    self:_reset()
    
    -- Find out where the effect should be created...
    local x, y, z = self:_getEventLoc()
    -- ...and what kind of footstep effect should be created
    local coFootstepArea = CoFootstepArea.getBestFootstepArea(self.rEntity, x, y, z)
    if coFootstepArea ~= nil then
    
        -- Create the effect (if defined)
        if coFootstepArea.sEffect ~= nil and #coFootstepArea.sEffect > 0 then
        
            if self:_getDebugFlags().DebugExecution then
                Trace("Creating footstep effect: " .. coFootstepArea.sEffect)
            end
            
            self.rEffect = Effect.new(coFootstepArea.sEffect)
            
            self.rEffect:setEntity(self.rEntity)
            self.rEffect:setCompleteBehavior(Effect.ONCOMPLETE_DESTROY)
            self.rEffect.sortOffset = self.particleSystemSortOffset
            
            local rEffectProp = self.rEffect:getProp()    
            rEffectProp:setLoc(unpack(self.Offset))
            
            -- Set the attachment up
            rEffectProp:clearAttrLink(MOAIProp.INHERIT_TRANSFORM)
            if self.JointName ~= nil and self.rEntity.CoRig ~= nil then  
            
                local rJointProp = self.rEntity.CoRig:getJointProp( self.JointName )
                rEffectProp:setAttrLink(MOAIProp.INHERIT_TRANSFORM, rJointProp, MOAIProp.TRANSFORM_TRAIT)
                
                self.rEffect.rootScale = 300.0
            end
            
            self.rEffect:start()
            
        -- Create the particle system
        elseif coFootstepArea.sParticleSystem ~= nil and #coFootstepArea.sParticleSystem > 0 then
        
            if self:_getDebugFlags().DebugExecution then
                Trace("Creating footstep particle system: " .. coFootstepArea.sParticleSystem)
            end
            
            -- Add the particle system to the scene layer
            self.rParticleSystem = ParticleSystem.new(self.rEntity, coFootstepArea.sParticleSystem, nil)
            if self.rParticleSystem then            
                self.rParticleSystem:init()
                
                self.rParticleSystem:setOffsetLocation(coFootstepArea.tParticleSystemOffsetLocation)
                self.rParticleSystem:setOffsetRotation(coFootstepArea.tParticleSystemOffsetRotation)
                self.rParticleSystem:setSortOffset(coFootstepArea.particleSystemSortOffset)
                
                self.rParticleSystem:addToEntity()
                
                -- Set the attachment up
                self.rParticleSystem:setOffsetLocation(self.Offset)
                if self.JointName ~= nil and self.rEntity.CoRig ~= nil then  
                
                    local rJointProp = self.rEntity.CoRig:getJointProp( self.JointName )
                    self.rParticleSystem:setRootProp(rJointProp)
                end
                
                self.rParticleSystem:start()
            end
        end
        
        -- Create the sound
        if coFootstepArea.sSoundCue ~= nil and #coFootstepArea.sSoundCue > 0 then
        
            if MOAIFmodEventMgr ~= nil then
            
                if self:_getDebugFlags().DebugExecution then
                    Trace("Playing footstep sound cue: " .. coFootstepArea.sSoundCue)
                end
                
                self.rSoundEvent = MOAIFmodEventMgr.playEvent3D( coFootstepArea.sSoundCue )
            end
        end
    end
end

function AeFootstep:onCleanup()

    self:_reset()
end

-- PROTECTED FUNCTIONS --
function AeFootstep:_reset()

    if self.rEffect ~= nil then
    
        if self.KeepAlive == false then
        
            self.rEffect:stop(true)
        end
        self.rEffect = nil
    end
    
    if self.rParticleSystem ~= nil then
        
        if self.KeepAlive == false then
            self.rParticleSystem:stop()
            
            -- Remove the particle system to the scene layer
            self.rParticleSystem:removeFromEntity()
            
            self.rParticleSystem:unload()
        end        
        self.rParticleSystem = nil
    end
    
    if self.rSoundEvent ~= nil and self.rSoundEvent:isValid() then
    
        if self.KeepAlive == false then
            self.rSoundEvent:stop()
        end
        self.rSoundEvent = nil
    end
end

return AeFootstep
