local Util = require('DFCommon.Util')
local Class = require('Class')
local SeqCommand = require('SeqCommand')
local EffectEvent = Class.create(SeqCommand)

-- ATTRIBUTES --

local DFSchema = require('DFCommon.DFSchema')
local tFields = Util.deepCopy(SeqCommand.rSchema.tFieldSchemas)

SeqCommand.metaFlag(tFields, "EffectEventCommand")
SeqCommand.nonBlocking(tFields)

EffectEvent.rSchema = DFSchema.object(
	tFields,
	"Abstract base class for all effect events."
)
SeqCommand.addEditorSchema('EffectEvent', EffectEvent.rSchema)

-- VIRTUAL FUNCTIONS
function EffectEvent:stop()
end

function EffectEvent:isDone()
    return true
end

-- PROTECTED FUNCTIONS
function EffectEvent:_setEffect(rEffect)
    self.rEffect = rEffect
end

return EffectEvent