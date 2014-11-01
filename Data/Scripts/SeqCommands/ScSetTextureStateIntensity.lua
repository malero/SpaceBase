local Util = require('DFCommon.Util')
local TextureStateManager = require('TextureStateManager')

local SeqCommand = require('SeqCommand')
local Class = require('Class')
local ScSetTextureStateIntensity = Class.create(SeqCommand)

-- ATTRIBUTES --
ScSetTextureStateIntensity.Intensity = 1
ScSetTextureStateIntensity.BlendDuration = 0

local DFSchema = require('DFCommon.DFSchema')
local tFields = Util.deepCopy(SeqCommand.rSchema.tFieldSchemas)
tFields['GroupName'] = DFSchema.string(nil, "Name of the texture blend group to affect.")
tFields['Intensity'] = DFSchema.number(1, "Target intensity of blend group.")
tFields['BlendDuration'] = DFSchema.number(0, "Duration of intensity change.")

SeqCommand.nonBlocking(tFields)

ScSetTextureStateIntensity.rSchema = DFSchema.object(tFields, "Sets the intensity of a specified texture blend group.")
SeqCommand.addEditorSchema('ScSetTextureStateIntensity', ScSetTextureStateIntensity.rSchema)

function ScSetTextureStateIntensity:onExecute()     
    
    local blendDuration = self.BlendDuration
    if self.bSkip then
        blendDuration = 0
    end
    
    TextureStateManager.setTextureStateIntensity(self.GroupName, self.Intensity, blendDuration)
end

return ScSetTextureStateIntensity
