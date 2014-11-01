local Util = require('DFCommon.Util')
local Class = require('Class')
local SeqCommand = require('SeqCommand')
local ScCreateEffect = require('SeqCommands.ScCreateEffect')
local ScActorCreateEffect = Class.create(ScCreateEffect)

local EntityManager = require('EntityManager')

-- ATTRIBUTES --
ScActorCreateEffect.ActorName = ""

local DFSchema = require('DFCommon.DFSchema')
local tFields = Util.deepCopy(ScCreateEffect.rSchema.tFieldSchemas)
tFields['SceneLayerName'] = nil
tFields['ActorName'] = DFSchema.entityName(nil, "Name of the actor", "ControllingActor")
tFields['JointName'] = DFSchema.string(nil, "Joint at which to spawn the particle system")

ScActorCreateEffect.rSchema = DFSchema.object(
    tFields,
    "Creates a effect on the actor."
)
SeqCommand.addEditorSchema('ScActorCreateEffect', ScActorCreateEffect.rSchema)

-- VIRTUAL FUNCTIONS --

-- PROTECTED FUNCTIONS --
function ScActorCreateEffect:_getEntity()

    local rActor = EntityManager.getEntityNamed( self.ActorName )
    
    if rActor == nil then
        Trace(TT_Error, "Couldn't find entity: " .. self.ActorName)
    end
    
    return rActor
end

function ScActorCreateEffect:_setupAttachment()

    local rEntity = self:_getEntity()
    if rEntity ~= nil then
    
        local rEffectProp = self.rEffect:getProp()
        if self.JointName ~= nil and rEntity.CoRig ~= nil then  
        
            local rJointProp = rEntity.CoRig:getJointProp( self.JointName )
            
            if rJointProp == nil then
                Trace(TT_Error, "Couldn't find joint: " .. self.JointName)
            end
            
            rEffectProp:setAttrLink(MOAIProp.INHERIT_TRANSFORM, rJointProp, MOAIProp.TRANSFORM_TRAIT)
            
            self.rEffect.rootScale = 300.0
        else
        
            local rEntityProp = rEntity:getProp()
            rEffectProp:setAttrLink(MOAIProp.INHERIT_TRANSFORM, rEntityProp, MOAIProp.TRANSFORM_TRAIT)   
            
            self.rEffect.rootScale = 1.0
        end
    end
end

return ScActorCreateEffect
