local Util = require('DFCommon.Util')

local SeqCommand = require('SeqCommand')
local Class = require('Class')
local ScSetLightGroupIntensity = Class.create(SeqCommand)

-- ATTRIBUTES --
ScSetLightGroupIntensity.Intensity = 1
ScSetLightGroupIntensity.BlendDuration = 0

local DFSchema = require('DFCommon.DFSchema')
local tFields = Util.deepCopy(SeqCommand.rSchema.tFieldSchemas)
tFields['GroupName'] = DFSchema.string(nil, "Name of the light group to affect.")
tFields['AlternateGroupName'] = DFSchema.string(nil, "Name of the light alternate group to cross-fade with.")
tFields['Intensity'] = DFSchema.number(1, "Target intensity of light group.")
tFields['BlendDuration'] = DFSchema.number(0, "Duration of intensity change.")

SeqCommand.nonBlocking(tFields)

ScSetLightGroupIntensity.rSchema = DFSchema.object(tFields, "Sets the intensity of a specified light group.")
SeqCommand.addEditorSchema('ScSetLightGroupIntensity', ScSetLightGroupIntensity.rSchema)

function ScSetLightGroupIntensity:onExecute()     
    
    local blendDuration = self.BlendDuration
    if self.bSkip then
        blendDuration = 0
    end
    
    local alternateIntensity = 1.0 - self.Intensity
    local bCrossfade = self.AlternateGroupName ~= nil and #self.AlternateGroupName > 0
    
    if blendDuration > 0.00001 then
        DFLightEnvironment.seekGroupIntensity(self.GroupName, self.Intensity, blendDuration)
        
        if bCrossfade then
            DFLightEnvironment.seekGroupIntensity(self.AlternateGroupName, alternateIntensity, blendDuration)
        end
    else
        DFLightEnvironment.setGroupIntensity(self.GroupName, self.Intensity)
        
        if bCrossfade then
            DFLightEnvironment.setGroupIntensity(self.AlternateGroupName, alternateIntensity)
        end
    end
end

return ScSetLightGroupIntensity
