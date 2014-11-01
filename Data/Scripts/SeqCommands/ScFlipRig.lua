local DFUtil = require('DFCommon.Util')
local Class = require('Class')
local SeqCommand = require('SeqCommand')
local ScFlipRig = Class.create(SeqCommand)

local EntityManager = require('EntityManager')
local GameRules = require('GameRules')
local Scene = require('Scene')

-- ATTRIBUTES --
ScFlipRig.ActorName = ""
ScFlipRig.Setting = true

local DFSchema = require('DFCommon.DFSchema')
local tFields = DFUtil.deepCopy(SeqCommand.rSchema.tFieldSchemas)
tFields['ActorName'] = DFSchema.entityName(nil, "Name of the actor", "ControllingActor")
tFields['Setting'] = DFSchema.bool(true, "Whether to flip the rig")

SeqCommand.nonBlocking(tFields)

ScFlipRig.rSchema = DFSchema.object(
    tFields,
    "Flips the rig of the specified actor."
)
SeqCommand.addEditorSchema('ScFlipRig', ScFlipRig.rSchema)

-- VIRTUAL FUNCTIONS --

function ScFlipRig:onExecute()
    
    local rActor = EntityManager.getEntityNamed( self.ActorName )
    if rActor and rActor.CoRig then
    
        rActor.CoRig:setRigFlipped( self.Setting )
    else
        Trace(TT_Error, "Couldn't find entity: " .. self.ActorName)
    end

end

return ScFlipRig
