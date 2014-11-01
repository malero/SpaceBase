local Util = require('DFCommon.Util')
local Class = require('Class')
local SeqCommand = require('SeqCommand')
local GameStateManager = require('GameStateManager')
local ScSetLogicBool = Class.create(SeqCommand)

-- ATTRIBUTES --
ScSetLogicBool.Key = ""
ScSetLogicBool.Value = true

local DFSchema = require('DFCommon.DFSchema')
local tFields = Util.deepCopy(SeqCommand.rSchema.tFieldSchemas)
tFields['Key'] = DFSchema.string(nil, "Key of the game-state value.")
tFields['Value'] = DFSchema.bool(true, "Boolean value of the game-state value")

SeqCommand.metaFlag(tFields, "LogicCommand")
SeqCommand.metaPriority(tFields, 20)

ScSetLogicBool.rSchema = DFSchema.object(
    tFields,
    "Sets a game-state value."
)
SeqCommand.addEditorSchema('ScSetLogicBool', ScSetLogicBool.rSchema)

-- VIRTUAL FUNCTIONS --
function ScSetLogicBool:onExecute()
    
    if self.Key and self.Key ~= "" then
        GameStateManager.setValueFor( self.Key, self.Value )
    end
end

return ScSetLogicBool
