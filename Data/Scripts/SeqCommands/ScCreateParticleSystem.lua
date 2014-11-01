local Util = require('DFCommon.Util')
local Class = require('Class')
local SeqCommand = require('SeqCommand')
local ScCreateParticleSystem = Class.create(SeqCommand)

local Scene = require('Scene')
local ParticleSystem = require('ParticleSystem')
local LodManager = require('LodManager')

-- ATTRIBUTES --
ScCreateParticleSystem.ParticleSystem = nil
ScCreateParticleSystem.OffsetLocation = {0, 0, 0}
ScCreateParticleSystem.OffsetRotation = {0, 0, 0}
ScCreateParticleSystem.SortOffset = 0
ScCreateParticleSystem.KeepAlive = false
ScCreateParticleSystem.SceneLayerName = nil

local DFSchema = require('DFCommon.DFSchema')
local tFields = Util.deepCopy(SeqCommand.rSchema.tFieldSchemas)
tFields['ParticleSystem'] = DFSchema.resource(nil, 'Unmunged', '.particles', "The path to the particle system")
tFields['OffsetLocation'] = DFSchema.vec3({0, 0, 0}, "Offset location of the particle system")
tFields['OffsetRotation'] = DFSchema.vec3({0, 0, 0}, "Offset rotation of the particle system")
tFields['SortOffset'] = DFSchema.number(0, "Describes if the particle system draws in front or behind other geometry of the entity")
tFields['KeepAlive'] = DFSchema.bool(false, "Keep the particle system alive at the end of the sequence?")
tFields['SceneLayerName'] = DFSchema.string(nil, "Name of the layer in which to spawn the particle system")

SeqCommand.nonBlocking(tFields)
SeqCommand.levelOfDetail(tFields)

ScCreateParticleSystem.rSchema = DFSchema.object(
    tFields,
    "Creates a particle effect in the scene."
)
SeqCommand.addEditorSchema('ScCreateParticleSystem', ScCreateParticleSystem.rSchema)

-- VIRTUAL FUNCTIONS --
function ScCreateParticleSystem:onCreated()

    self.rParticleSystem = nil
    
    -- Make sure we get unique tables
	self.OffsetLocation = Util.deepCopy(ScCreateParticleSystem.OffsetLocation)
    self.OffsetRotation = Util.deepCopy(ScCreateParticleSystem.OffsetRotation)
end

function ScCreateParticleSystem:onPreloadCutscene(rAssetSet)

    if LodManager.acceptSceneLod(self.LodGroup, self.LodType) == false then
        return
    end

    if self.ParticleSystem ~= nil and #self.ParticleSystem > 0 then
        self.rParticleSystem = ParticleSystem.new(self:_getEntity(), self.ParticleSystem, rAssetSet)
    end
end

function ScCreateParticleSystem:onExecute()
    if self.bSkip then
        return
    end

    local rEntity = self:_getEntity()
    local rSceneLayer = nil
    
    if rEntity == nil then
        rSceneLayer = Scene.CurrentScene:getNamedLayer(self.SceneLayerName)
        if rSceneLayer == nil then
            Trace(TT_Warning, "Can't add particle system to unknown scene layer: " .. self.SceneLayerName)
            return
        end
    end
            
    if self.rParticleSystem ~= nil then
    
        if self:_getDebugFlags().DebugExecution then
            Trace(TT_Gameplay, "Creating particle system: " .. self.ParticleSystem)
        end
        
        -- Get the particle system ready for use
        self.rParticleSystem:init(rEntity)
        self:_setupParticleSystem()
        
        -- Add the particle system to the scene layer        
        if rEntity ~= nil then
            self.rParticleSystem:addToEntity(rEntity)
        else
            self.rParticleSystem:addToSceneLayer(rSceneLayer)
        end
        
        -- Setup the location and orientation of the particle system
        self.rParticleSystem:setOffsetLocation(self.OffsetLocation)
        self.rParticleSystem:setOffsetRotation(self.OffsetRotation)
        self:_setupAttachment()
        
        self.rParticleSystem:start()
    else
        if self:_getDebugFlags().DebugLoading then
            Trace(TT_Warning, "Couldn't load particle system: " .. self.ParticleSystem)
        end
    end
end

function ScCreateParticleSystem:onCleanup()

    if self.rParticleSystem ~= nil then
    
        if self.KeepAlive == false then
            self.rParticleSystem:stop(true)
            
            -- Remove the particle system to the scene layer
            local rEntity = self:_getEntity()
            if rEntity ~= nil then
                self.rParticleSystem:removeFromEntity()
            else
                self.rParticleSystem:removeFromSceneLayer()
            end
            
            self.rParticleSystem:unload()
        end
        self.rParticleSystem = nil
    end
end

-- PROTECTED FUNCTIONS --
function ScCreateParticleSystem:_getEntity()
    return nil
end

function ScCreateParticleSystem:_setupParticleSystem()
    self.rParticleSystem:getProp():setPriority(self.SortOffset)
end

function ScCreateParticleSystem:_setupAttachment()
end

return ScCreateParticleSystem
