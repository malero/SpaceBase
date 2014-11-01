local Util = require('DFCommon.Util')
local Class = require('Class')
local SeqCommand = require('SeqCommand')
local ScStartShot = Class.create(SeqCommand)

-- ATTRIBUTES --
ScStartShot.SceneLayerName = ""
ScStartShot.LocatorName = ""

local DFSchema = require('DFCommon.DFSchema')
local tFields = Util.deepCopy(SeqCommand.rSchema.tFieldSchemas)
tFields['SceneLayerName'] = DFSchema.string(nil, "(optional) Name of the default layer for this cutscene")
tFields['LocatorName'] = DFSchema.entityName(nil, "(optional) Name of the default locator for this cutscene")

SeqCommand.nonBlocking(tFields)
SeqCommand.metaPriority(tFields, 1000)

ScStartShot.rSchema = DFSchema.object(
    tFields,
    "Marks the beginning of a shot."
)
SeqCommand.addEditorSchema('ScStartShot', ScStartShot.rSchema)

-- VIRTUAL FUNCTIONS --

-- PUBLIC FUNCTIONS --

return ScStartShot
