local Util = require('DFCommon.Util')
local Class = require('Class')
local SeqCommand = require('SeqCommand')
local EffectEvent = require('EffectEvent')
local EeCreateParticleSystem = Class.create(EffectEvent)

local ParticleSystem = require('ParticleSystem')
local LodManager = require('LodManager')

-- ATTRIBUTES --
EeCreateParticleSystem.Name = nil
EeCreateParticleSystem.ParticleSystem = nil
EeCreateParticleSystem.OffsetLocation = { 0, 0, 0 }
EeCreateParticleSystem.OffsetRotation = { 0, 0, 0 }
EeCreateParticleSystem.SortOffset = 0

local DFSchema = require('DFCommon.DFSchema')
local tFields = Util.deepCopy(EffectEvent.rSchema.tFieldSchemas)
tFields['Name'] = DFSchema.string(nil, "Name of the particle event so it can be disabled later")
tFields['ParticleSystem'] = DFSchema.resource(nil, 'Unmunged', '.particles', "The path to the particle system")
tFields['OffsetLocation'] = DFSchema.vec3({0, 0, 0}, "Offset location of the particle event")
tFields['OffsetRotation'] = DFSchema.vec3({0, 0, 0}, "Offset rotation of the particle event")
tFields['SortOffset'] = DFSchema.number(0, "Describes if the particle system draws in front or behind other geometry of the entity")

SeqCommand.levelOfDetail(tFields)

EeCreateParticleSystem.rSchema = DFSchema.object(
	tFields,
	"Creates a particle system."
)
SeqCommand.addEditorSchema('EeCreateParticleSystem', EeCreateParticleSystem.rSchema)

-- VIRTUAL FUNCTIONS --
function EeCreateParticleSystem:onCreated()
    
	self.OffsetLocation = Util.deepCopy(EeCreateParticleSystem.OffsetLocation)
	self.OffsetRotation = Util.deepCopy(EeCreateParticleSystem.OffsetRotation)
end

function EeCreateParticleSystem:onPreloadCutscene(rAssetSet)

    if LodManager.acceptSceneLod(self.LodGroup, self.LodType) == false then
        return
    end
    
    if self.ParticleSystem ~= nil and #self.ParticleSystem > 0 then
        self.rParticleSystem = ParticleSystem.new(nil, self.ParticleSystem, rAssetSet)
    end
end

function EeCreateParticleSystem:onExecute()
    
    if self.rParticleSystem ~= nil then
    
        if self.rParticleSystem.bUnloaded == true then
            -- Reload the particle system, because the effect is looping
            self.rParticleSystem = nil
            self.bStarted = nil
            self:onPreloadCutscene(nil)
        end
    
        if self.bStarted == true then
        
            if self:_getDebugFlags().DebugExecution then
                Trace("Restarting particle system: " .. self.ParticleSystem)
            end
        else
        
            if self:_getDebugFlags().DebugExecution then
                Trace("Creating particle system: " .. self.ParticleSystem)
            end
            
            local rEntity = self.rEffect.rEntity
            local rSceneLayer = self.rEffect.rSceneLayer
            
            -- Get the particle system ready for use
            self.rParticleSystem:init(rEntity)
            self.rParticleSystem:setSortOffset(self.rEffect.sortOffset + self.SortOffset)
            
            -- Add the particle system to the scene layer        
            if rEntity ~= nil then
                self.rParticleSystem:addToEntity(rEntity)
            else
                self.rParticleSystem:addToSceneLayer(rSceneLayer)
            end
            
            -- Setup the location and orientation of the particle system
            self.rParticleSystem:setOffsetLocation(self.OffsetLocation)
            self.rParticleSystem:setOffsetRotation(self.OffsetRotation)
            self.rParticleSystem:setRootProp(self.rEffect:getProp(), self.rEffect.rootScale)
            
            self.bStarted = true
        end

        self.rParticleSystem:start()
        
    else
        if self:_getDebugFlags().DebugLoading then
            Trace("Couldn't load particle system: " .. self.ParticleSystem)
        end
    end
end

function EeCreateParticleSystem:onCleanup()

    if self.rParticleSystem ~= nil then
        
        self.rParticleSystem:stop(true)
        
        -- Remove the particle system to the scene layer
        local rEntity = self.rEffect.rEntity
        if rEntity ~= nil then
            self.rParticleSystem:removeFromEntity()
        else
            self.rParticleSystem:removeFromSceneLayer()
        end
        
        self.rParticleSystem:unload()
        self.rParticleSystem = nil
    end
end

function EeCreateParticleSystem:isDone()

    if self.rParticleSystem ~= nil then
        return self.rParticleSystem:isDone()
    end
    return false
end

-- PUBLIC FUNCTIONS --
function EeCreateParticleSystem:stop(bImmediate)

    if not self:isDone() then
        if self.rParticleSystem ~= nil then
            self.rParticleSystem:stop(bImmediate)
        end
    end
end

return EeCreateParticleSystem
