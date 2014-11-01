local Util = require('DFCommon.Util')
local Class = require('Class')
local SeqCommand = require('SeqCommand')
local EntityManager = require('EntityManager')
local ScSetMeshPartVisibility = Class.create(SeqCommand)

-- ATTRIBUTES --
ScSetMeshPartVisibility.MeshName = ""
ScSetMeshPartVisibility.MeshPart = ""
ScSetMeshPartVisibility.IsConditionalOverride = false
ScSetMeshPartVisibility.FixedState = true
ScSetMeshPartVisibility.ConditionalMeshPart = ""

local DFSchema = require('DFCommon.DFSchema')
local tFields = Util.deepCopy(SeqCommand.rSchema.tFieldSchemas)
tFields['ActorName'] = DFSchema.entityName(nil, "Name of the actor", "ControllingActor")
tFields['MeshName'] = DFSchema.string(nil, "The name of the mesh where this part is located (usually, just the name of the rig).")
tFields['MeshPart'] = DFSchema.string(nil, "The name of the mesh part as it appears in the rig file (e.g. _Group_Flipbook_Group_Front_FBGroup_Fr_Accessories_Fr_Acces_Lf_Ankle_IK_Fr_Lf_CouldShoe)")
tFields['IsConditionalOverride'] = DFSchema.bool(false, "Is the mesh part override driven by the visiblity of another part or is it fixed?")
tFields['FixedState'] = DFSchema.bool(true, "Boolean value for whether to turn this part on or off (only used when OverrideType = Fixed)")
tFields['ConditionalMeshPart'] = DFSchema.string(nil, "Name of the mesh part that has to be visible in order to switch the given part on (only used when OverrideType = Conditional)")

SeqCommand.nonBlocking(tFields)
SeqCommand.metaPriority(tFields, 5)

ScSetMeshPartVisibility.rSchema = DFSchema.object(
    tFields,
    "Turns on and off the visibility of the specified mesh part"
)
SeqCommand.addEditorSchema('ScSetMeshPartVisibility', ScSetMeshPartVisibility.rSchema)

-- VIRTUAL FUNCTIONS --
function ScSetMeshPartVisibility:onExecute()
    local rActor = EntityManager.getEntityNamed( self.ActorName )
    if rActor then
        if self.MeshPart and self.MeshPart ~= "" and self.MeshName and self.MeshName ~= "" then
        
            local tMeshVisibilityOverrides = {}
            tMeshVisibilityOverrides[self.MeshName] = {}
            if self.IsConditionalOverride == true then
                tMeshVisibilityOverrides[self.MeshName][self.MeshPart] = self.ConditionalMeshPart
            else
                tMeshVisibilityOverrides[self.MeshName][self.MeshPart] = self.FixedState
            end
            
            rActor.CoRig:addMeshVisibilityOverrides( tMeshVisibilityOverrides )        
        end
    else
        Trace(TT_Warning, "Unable to find entity: " .. self.ActorName)
    end
end

return ScSetMeshPartVisibility
