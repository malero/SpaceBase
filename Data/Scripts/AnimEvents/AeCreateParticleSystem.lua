local Util = require('DFCommon.Util')
local Class = require('Class')
local SeqCommand = require('SeqCommand')
local AnimEvent = require('AnimEvent')
local AeCreateParticleSystem = Class.create(AnimEvent)

local ParticleSystem = require('ParticleSystem')
local LodManager = require('LodManager')

-- ATTRIBUTES --
AeCreateParticleSystem.ParticleSystem = nil
AeCreateParticleSystem.OffsetRotation = { 0, 0, 0 }
AeCreateParticleSystem.SortOffset = 0

local DFSchema = require('DFCommon.DFSchema')
local tFields = Util.deepCopy(AnimEvent.rSchema.tFieldSchemas)
tFields['ParticleSystem'] = DFSchema.resource(nil, 'Unmunged', '.particles', "The path to the particle system")
tFields['OffsetRotation'] = DFSchema.vec3({0, 0, 0}, "Offset rotation (relative to the joint) of the animation event")
tFields['SortOffset'] = DFSchema.number(0, "Describes if the particle system draws in front or behind other geometry of the entity")

SeqCommand.levelOfDetail(tFields)

AeCreateParticleSystem.rSchema = DFSchema.object(
	tFields,
	"Creates a particle system."
)
SeqCommand.addEditorSchema('AeCreateParticleSystem', AeCreateParticleSystem.rSchema)

-- VIRTUAL FUNCTIONS --
function AeCreateParticleSystem:onCreated()

    AnimEvent.onCreated(self)
    
	self.OffsetRotation = Util.deepCopy(AeCreateParticleSystem.OffsetRotation)
end

function AeCreateParticleSystem:onPreloadCutscene(rAssetSet)

    -- BEN-NOTE: forget LOD for now, we don't support it in spacebase
    --[[
    if LodManager.acceptSceneLod(self.LodGroup, self.LodType) == false then
        return
    end
    ]]--
    
    --self.ParticleSystem = "Effects/Trailer/TrainSmoke.particles"
    
    if self.ParticleSystem ~= nil and #self.ParticleSystem > 0 then
        self.rParticleSystem = ParticleSystem.new(self.rEntity, self.ParticleSystem, rAssetSet)
    end
end

function AeCreateParticleSystem:onExecute()
	
    if self.rParticleSystem ~= nil then
    
        if self:_getDebugFlags().DebugExecution then
            Trace("Creating particle system: " .. self.ParticleSystem)
        end
        
        -- Get the particle system ready for use
        self.rParticleSystem:init(self.rEntity)
        
        -- Apply the sort offset (if defined)
        self.rParticleSystem:setSortOffset(self.SortOffset)
    
        -- Add the particle system to the scene layer
        self.rParticleSystem:addToEntity()
        
        local offsetRotation = self.OffsetRotation or { 0, 0, 0 }
        local offsetLocation = self.Offset or {0, 0, 0}
        
        -- Set the attachment up
        if self.rEntity.rProp and self.rEntity.rProp.rCurrentRig then
            if self.JointName then              
                local rJointProp = self.rEntity.rProp.rCurrentRig:getJointProp( self.JointName )
                self.rParticleSystem:setRootProp(rJointProp)
            end
            
            -- we inherit our character orientation instead of the joint because it was too wonky most of the time
            local rotY = self.rEntity.rProp.nCharRotation or 0
            self.rParticleSystem.rParticleSystem:setRot(0, rotY, 0)
            self.rParticleSystem.nRotY = rotY
            
            -- hack: get particles sorting behind dudes if they're shooting "up"
            if rotY > 135 and rotY < 225 then
                offsetLocation[2] = offsetLocation[2] + 0.5
            end
        end

        self.rParticleSystem:setOffsetLocation(offsetLocation)
        self.rParticleSystem:setOffsetRotation(offsetRotation)
        self.rParticleSystem:start()
    else
        if self:_getDebugFlags().DebugLoading then
            Trace("Couldn't load particle system: " .. self.ParticleSystem)
        end
    end
end

function AeCreateParticleSystem:onCleanup()

    if self.rParticleSystem ~= nil then
        
        if self.KeepAlive == false then
            self.rParticleSystem:stop()
            
            -- Remove the particle system to the scene layer
            self.rParticleSystem:removeFromEntity()
            
            self.rParticleSystem:unload()
        end
        self.rParticleSystem = nil
    end
end

-- PUBLIC FUNCTIONS --

return AeCreateParticleSystem
