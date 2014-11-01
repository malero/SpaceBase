local Util = require('DFCommon.Util')
local EnvStateManager = require('EnvStateManager')

local SeqCommand = require('SeqCommand')
local Class = require('Class')
local ScPopEnvState = Class.create(SeqCommand)

-- ATTRIBUTES --
ScPopEnvState.BlendDuration = 0

local DFSchema = require('DFCommon.DFSchema')
local tFields = Util.deepCopy(SeqCommand.rSchema.tFieldSchemas)
tFields['BlendDuration'] = DFSchema.number(0, "Duration of intensity change.")

SeqCommand.nonBlocking(tFields)

ScPopEnvState.rSchema = DFSchema.object(tFields, "Adds a specified environment state to the stack.")
SeqCommand.addEditorSchema('ScPopEnvState', ScPopEnvState.rSchema)

function ScPopEnvState:onExecute()     
    
    local blendDuration = self.BlendDuration
    if self.bSkip then
        blendDuration = 0
    end
    
    EnvStateManager.popState(blendDuration)
end

return ScPopEnvState
