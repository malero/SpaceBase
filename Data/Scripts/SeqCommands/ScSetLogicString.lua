local Util = require('DFCommon.Util')
local Class = require('Class')
local SeqCommand = require('SeqCommand')
local GameStateManager = require('GameStateManager')
local ScSetLogicString = Class.create(SeqCommand)

-- ATTRIBUTES --
ScSetLogicString.Key = ""
ScSetLogicString.Value = nil

local DFSchema = require('DFCommon.DFSchema')
local tFields = Util.deepCopy(SeqCommand.rSchema.tFieldSchemas)
tFields['Key'] = DFSchema.string(nil, "Key of the game-state value.")
tFields['Value'] = DFSchema.string(nil, "String value of the game-state value.")

SeqCommand.metaFlag(tFields, "LogicCommand")
SeqCommand.metaPriority(tFields, 20)

ScSetLogicString.rSchema = DFSchema.object(
    tFields,
    "Sets a game-state value."
)
SeqCommand.addEditorSchema('ScSetLogicString', ScSetLogicString.rSchema)

-- VIRTUAL FUNCTIONS --
function ScSetLogicString:onExecute()
    if self.Key and self.Key ~= "" then
        GameStateManager.setValueFor( self.Key, self.Value )
    end
end

return ScSetLogicString
