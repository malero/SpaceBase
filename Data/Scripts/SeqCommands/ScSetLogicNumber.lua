local Util = require('DFCommon.Util')
local Class = require('Class')
local SeqCommand = require('SeqCommand')
local GameStateManager = require('GameStateManager')
local ScSetLogicNumber = Class.create(SeqCommand)

-- ATTRIBUTES --
ScSetLogicNumber.Key = ""
ScSetLogicNumber.Value = 0

local DFSchema = require('DFCommon.DFSchema')
local tFields = Util.deepCopy(SeqCommand.rSchema.tFieldSchemas)
tFields['Key'] = DFSchema.string(nil, "Key of the game-state value.")
tFields['Value'] = DFSchema.number(0, "Number value of the game-state value.")

SeqCommand.metaFlag(tFields, "LogicCommand")
SeqCommand.metaPriority(tFields, 20)

ScSetLogicNumber.rSchema = DFSchema.object(
    tFields,
    "Sets a game-state value."
)
SeqCommand.addEditorSchema('ScSetLogicNumber', ScSetLogicNumber.rSchema)

-- VIRTUAL FUNCTIONS --
function ScSetLogicNumber:onExecute()
    if self.Key and self.Key ~= "" then
        GameStateManager.setValueFor( self.Key, self.Value )
    end
end

return ScSetLogicNumber
