local Util = require('DFCommon.Util')
local Class = require('Class')
local SeqCommand = require('SeqCommand')
local EntityManager = require('EntityManager')
local ScSetVisible = Class.create(SeqCommand)

-- ATTRIBUTES --
ScSetVisible.Visible = false

local DFSchema = require('DFCommon.DFSchema')
local tFields = Util.deepCopy(SeqCommand.rSchema.tFieldSchemas)
tFields['ActorName'] = DFSchema.entityName(nil, "Name of the actor whose position we're changing", "ControllingActor")
tFields['Visible'] = DFSchema.bool(false, "Sets the Actor visible if true, invisible otherwise")

SeqCommand.nonBlocking(tFields)

ScSetVisible.rSchema = DFSchema.object(
    tFields,
    "Creates a new instance of the specified protoype at the given location."
)
SeqCommand.addEditorSchema('ScSetVisible', ScSetVisible.rSchema)

-- VIRTUAL FUNCTIONS --
function ScSetVisible:onExecute()
    
    if not self.bSkip then                   
        local rActor = EntityManager.getEntityNamed( self.ActorName ) 
        if rActor ~= nil then
            rActor:setVisible( self.Visible )
        else
            Trace(TT_Warning, "Actor not found: " .. (self.ActorName or "<n/a"))
        end
    end

end

-- PUBLIC FUNCTIONS --

return ScSetVisible
