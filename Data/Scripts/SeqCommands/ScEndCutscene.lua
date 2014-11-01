local Util = require('DFCommon.Util')
local Class = require('Class')
local SeqCommand = require('SeqCommand')
local ScEndCutscene = Class.create(SeqCommand)

-- ATTRIBUTES --

local DFSchema = require('DFCommon.DFSchema')
local tFields = Util.deepCopy(SeqCommand.rSchema.tFieldSchemas)

SeqCommand.nonBlocking(tFields)
SeqCommand.metaPriority(tFields, -1000)

ScEndCutscene.rSchema = DFSchema.object(
    tFields,
    "Causes the current cutscene to immediately stop playing."
)
SeqCommand.addEditorSchema('ScEndCutscene', ScEndCutscene.rSchema)

-- VIRTUAL FUNCTIONS --

-- PUBLIC FUNCTIONS --

return ScEndCutscene
