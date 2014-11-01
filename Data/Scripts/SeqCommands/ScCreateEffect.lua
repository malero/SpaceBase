local Util = require('DFCommon.Util')
local DFMath = require('DFCommon.Math')
local Class = require('Class')
local SeqCommand = require('SeqCommand')
local ScCreateEffect = Class.create(SeqCommand)

local Scene = require('Scene')
local Effect = require('Effect')

-- ATTRIBUTES --
ScCreateEffect.Effect = nil
ScCreateEffect.OffsetLocation = {0, 0, 0}
ScCreateEffect.OffsetRotation = {0, 0, 0}
ScCreateEffect.SortOffset = 0
ScCreateEffect.KeepAlive = false
ScCreateEffect.SceneLayerName = nil

local DFSchema = require('DFCommon.DFSchema')
local tFields = Util.deepCopy(SeqCommand.rSchema.tFieldSchemas)
tFields['Effect'] = DFSchema.resource(nil, 'Unmunged', '.effect', "The path to the effect")
tFields['OffsetLocation'] = DFSchema.vec3({0, 0, 0}, "Offset location of the effect")
tFields['OffsetRotation'] = DFSchema.vec3({0, 0, 0}, "Offset rotation of the effect")
tFields['SortOffset'] = DFSchema.number(0, "Describes if the effect draws in front or behind other geometry of the entity")
tFields['KeepAlive'] = DFSchema.bool(false, "Keep the particle system alive at the end of the sequence?")
tFields['SceneLayerName'] = DFSchema.string(nil, "Name of the layer in which to spawn the effect")

SeqCommand.nonBlocking(tFields)

ScCreateEffect.rSchema = DFSchema.object(
    tFields,
    "Creates a effect in the scene."
)
SeqCommand.addEditorSchema('ScCreateEffect', ScCreateEffect.rSchema)

-- VIRTUAL FUNCTIONS --
function ScCreateEffect:onCreated()

    self.rEffect = nil
    
    -- Make sure we get unique tables
	self.OffsetLocation = Util.deepCopy(ScCreateEffect.OffsetLocation)
    self.OffsetRotation = Util.deepCopy(ScCreateEffect.OffsetRotation)
end

function ScCreateEffect:onPreloadCutscene(rAssetSet)

    if self.Effect ~= nil and #self.Effect > 0 then
        self.rEffect = Effect.new(self.Effect, rAssetSet)
    end
end

function ScCreateEffect:onExecute()
    if self.bSkip then
        return
    end

    local rEntity = self:_getEntity()
    local rSceneLayer = nil
    
    if rEntity == nil then
        rSceneLayer = Scene.CurrentScene:getNamedLayer(self.SceneLayerName)
        if rSceneLayer == nil then
            Trace(TT_Warning, "Can't add effect to unknown scene layer: " .. self.SceneLayerName)
            return
        end
    end
            
    if self.rEffect ~= nil then
    
        if self:_getDebugFlags().DebugExecution then
            Trace(TT_Gameplay, "Creating effect: " .. self.Effect)
        end
        
        -- Add the effect to the scene layer        
        if rEntity ~= nil then
            self.rEffect:setEntity(rEntity)
        else
            self.rEffect:setSceneLayer(rSceneLayer)
        end
        
        -- Apply the sort offset (if defined)
        self.rEffect.sortOffset = self.SortOffset
    
        -- Setup the location and orientation of the effect
        self:_setupAttachment()
        
        -- Set the offsets
        local rEffectProp = self.rEffect:getProp()
        local tOffsetLoc = DFMath.sanitizeVector(self.OffsetLocation, {0,0,0})
        rEffectProp:setLoc(unpack(tOffsetLoc))
        
        local tOffsetRot = DFMath.sanitizeVector(self.OffsetRotation, {0,0,0})
        rEffectProp:setRot(unpack(tOffsetRot))
        
        self.rEffect:start()
    else
        if self:_getDebugFlags().DebugLoading then
            Trace(TT_Gameplay, "Couldn't load effect: " .. self.Effect)
        end
    end
end

function ScCreateEffect:onCleanup()

    if self.rEffect ~= nil then
    
        if self.KeepAlive == false then
            self.rEffect:stop()
            self.rEffect:unload()
        end
        self.rEffect = nil
    end
end

-- PROTECTED FUNCTIONS --
function ScCreateEffect:_getEntity()
    return nil
end

function ScCreateEffect:_setupAttachment()
end

return ScCreateEffect
