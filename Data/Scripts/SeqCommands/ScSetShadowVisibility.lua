local Util = require('DFCommon.Util')
local Class = require('Class')
local SeqCommand = require('SeqCommand')
local ScSetShadowVisibility = Class.create(SeqCommand)

local EntityManager = require('EntityManager')

-- ATTRIBUTES --
ScSetShadowVisibility.Visible = true

local DFSchema = require('DFCommon.DFSchema')
local tFields = Util.deepCopy(SeqCommand.rSchema.tFieldSchemas)
tFields['ActorName'] = DFSchema.entityName(nil, "Name of the actor", "ControllingActor")
tFields['Visible'] = DFSchema.bool(true, "Should the shadow be visible?")

SeqCommand.nonBlocking(tFields)

ScSetShadowVisibility.rSchema = DFSchema.object(
    tFields,
    "Controls the visibility of the shadow."
)
SeqCommand.addEditorSchema('ScSetShadowVisibility', ScSetShadowVisibility.rSchema)

-- VIRTUAL FUNCTIONS --
function ScSetShadowVisibility:onExecute()

    local rActor = EntityManager.getEntityNamed( self.ActorName )
    if rActor then
        if rActor.CoShadow then
            rActor.CoShadow:enable(self.Visible)
        end
    end    
end

-- PUBLIC FUNCTIONS --

return ScSetShadowVisibility
