local Util = require('DFCommon.Util')
local Class = require('Class')
local SeqCommand = require('SeqCommand')
local AnimEvent = require('AnimEvent')
local AeAnimation = Class.create(AnimEvent)

-- ATTRIBUTES --
AeAnimation.Animation = nil

local DFSchema = require('DFCommon.DFSchema')
local tFields = Util.deepCopy(SeqCommand.rSchema.tFieldSchemas)
tFields['Animation'] = DFSchema.resource(nil, 'Unmunged', '.anim', "The path to the animation")

SeqCommand.metaFlag(tFields, "AnimEventOwnerCommand")
SeqCommand.implicitlyBlocking(tFields)

AeAnimation.rSchema = DFSchema.object(
	tFields,
	"Host animation for anim events."
)
SeqCommand.addEditorSchema('AeAnimation', AeAnimation.rSchema)

-- VIRTUAL FUNCTIONS --
function AeAnimation:onExecute()
	
	-- Just for internal use in the cutscene editor
	assert(0)
end

-- PUBLIC FUNCTIONS --

return AeAnimation
