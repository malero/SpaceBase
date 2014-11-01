local Util = require('DFCommon.Util')
local Class = require('Class')
local SeqCommand = require('SeqCommand')
local AnimEvent = Class.create(SeqCommand)

-- ATTRIBUTES --
AnimEvent.JointName = nil
AnimEvent.Offset = {0, 0, 0}
AnimEvent.KeepAlive = true

local DFSchema = require('DFCommon.DFSchema')
local tFields = Util.deepCopy(SeqCommand.rSchema.tFieldSchemas)
tFields['JointName'] = DFSchema.string(nil, "Joint at which to spawn the animation event")
tFields['Offset'] = DFSchema.vec3({0, 0, 0}, "Offset location (relative to the joint) of the animation event")
tFields['KeepAlive'] = DFSchema.bool(true, "Keep the anim event alive after the animation ends or destroy it")

SeqCommand.metaFlag(tFields, "AnimEventCommand")
SeqCommand.implicitlyBlocking(tFields)

AnimEvent.rSchema = DFSchema.object(
	tFields,
	"Abstract base class for all anim events."
)
SeqCommand.addEditorSchema('AnimEvent', AnimEvent.rSchema)

-- VIRTUAL FUNCTIONS --
function AnimEvent:onCreated()

    -- Make sure we get unique tables
	self.Offset = Util.deepCopy(AnimEvent.Offset)
	-- Init internal variables
	self.rRig = nil
end

-- PUBLIC FUNCTIONS --
function AnimEvent:setRig(rig)
	self.rRig = rig
    self.rEntity = rig.rEntity
end

-- PROTECTED FUNCTIONS --
function AnimEvent:_createProp()
	-- ToDo: Find joint and create a prop with the offset applied
	assert(0)
end

function AnimEvent:_getEventLoc()

    local rRootProp = self.rEntity:getProp()
    if self.JointName ~= nil and self.rEntity.rProp ~= nil and self.rEntity.rProp.rCurrentRig ~= nil then  
        rRootProp = self.rEntity.rProp.rCurrentRig:getJointProp( self.JointName )
    end
    
    return rRootProp:modelToWorld(unpack(self.Offset))
end

return AnimEvent