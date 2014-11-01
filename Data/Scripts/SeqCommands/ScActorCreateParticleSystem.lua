local Util = require('DFCommon.Util')
local Class = require('Class')
local SeqCommand = require('SeqCommand')
local ScCreateParticleSystem = require('SeqCommands.ScCreateParticleSystem')
local ScActorCreateParticleSystem = Class.create(ScCreateParticleSystem)

local EntityManager = require('EntityManager')

-- ATTRIBUTES --
ScActorCreateParticleSystem.ActorName = ""

local DFSchema = require('DFCommon.DFSchema')
local tFields = Util.deepCopy(ScCreateParticleSystem.rSchema.tFieldSchemas)
tFields['SceneLayerName'] = nil
tFields['ActorName'] = DFSchema.entityName(nil, "Name of the actor", "ControllingActor")
tFields['JointName'] = DFSchema.string(nil, "Joint at which to spawn the particle system")

ScActorCreateParticleSystem.rSchema = DFSchema.object(
    tFields,
    "Creates a particle system on the actor."
)
SeqCommand.addEditorSchema('ScActorCreateParticleSystem', ScActorCreateParticleSystem.rSchema)

-- VIRTUAL FUNCTIONS --

-- PROTECTED FUNCTIONS --
function ScActorCreateParticleSystem:_getEntity()

    local rActor = EntityManager.getEntityNamed( self.ActorName )
    
    -- try again to grab the entity
    if rActor == nil then 
        rActor = self.rSequence:getSequenceEntityNamed( self.ActorName )        
    end
    
    if rActor == nil then
        Trace(TT_Error, "Couldn't find entity: " .. self.ActorName)
    end
    
    return rActor
end

function ScActorCreateParticleSystem:_setupParticleSystem()
    self.rParticleSystem:setSortOffset(self.SortOffset)
end

function ScActorCreateParticleSystem:_setupAttachment()

    local rEntity = self:_getEntity()
    if rEntity ~= nil then
    
        if self.JointName ~= nil and self.rEntity.rProp ~= nil and self.rEntity.rProp.rCurrentRig ~= nil then  
        
            local rJointProp = self.rEntity.rProp.rCurrentRig:getJointProp( self.JointName )
            
            if rJointProp == nil then
                Trace(TT_Error, "Couldn't find joint: " .. self.JointName)
            end
            
            self.rParticleSystem:setRootProp(rJointProp)
        end
    end
end

return ScActorCreateParticleSystem
