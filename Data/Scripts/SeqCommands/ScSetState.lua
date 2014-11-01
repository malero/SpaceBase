local Util = require('DFCommon.Util')
local GameStateManager = require('GameStateManager')

local SeqCommand = require('SeqCommand')
local Class = require('Class')
local ScSetState = Class.create(SeqCommand)

local DFSchema = require('DFCommon.DFSchema')
local tFields = Util.deepCopy(SeqCommand.rSchema.tFieldSchemas)
tFields.sStateVariable = DFSchema.string(nil, "The name of the state variable to set.")
tFields.bValue = DFSchema.bool(nil, "The value to assign to the state variable.")

ScSetState.rSchema = DFSchema.object(tFields, "Enables or disables player controls.")
SeqCommand.addEditorSchema('ScSetState', ScSetState.rSchema)

function ScSetState:onExecute()
    GameStateManager.setValueFor(self.sStateVariable, self.bValue)
end

return ScSetState
