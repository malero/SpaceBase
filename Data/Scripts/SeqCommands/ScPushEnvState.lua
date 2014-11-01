local Util = require('DFCommon.Util')
local EnvStateManager = require('EnvStateManager')

local SeqCommand = require('SeqCommand')
local Class = require('Class')
local ScPushEnvState = Class.create(SeqCommand)

-- ATTRIBUTES --
ScPushEnvState.BlendDuration = 0

local DFSchema = require('DFCommon.DFSchema')
local tFields = Util.deepCopy(SeqCommand.rSchema.tFieldSchemas)
tFields['EnvState'] = DFSchema.resource(nil, 'Data', '.envstate', "The path to the environment state")
tFields['BlendDuration'] = DFSchema.number(0, "Duration of intensity change.")

SeqCommand.nonBlocking(tFields)

ScPushEnvState.rSchema = DFSchema.object(tFields, "Adds a specified environment state to the stack.")
SeqCommand.addEditorSchema('ScPushEnvState', ScPushEnvState.rSchema)

function ScPushEnvState:onExecute()     
    
    local blendDuration = self.BlendDuration
    if self.bSkip then
        blendDuration = 0
    end
    
    EnvStateManager.pushState(self.EnvState, blendDuration)
end

return ScPushEnvState
