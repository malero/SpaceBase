local DFUtil = require('DFCommon.Util')
local Class = require('Class')
local SeqCommand = require('SeqCommand')
local ScSetSceneLayer = Class.create(SeqCommand)

local EntityManager = require('EntityManager')
local GameRules = require('GameRules')
local Scene = require('Scene')

-- ATTRIBUTES --
ScSetSceneLayer.ActorName = ""
ScSetSceneLayer.SceneLayerName = ""

local DFSchema = require('DFCommon.DFSchema')
local tFields = DFUtil.deepCopy(SeqCommand.rSchema.tFieldSchemas)
tFields['ActorName'] = DFSchema.entityName(nil, "Name of the actor", "ControllingActor")
tFields['SceneLayerName'] = DFSchema.string(nil, "Name of the target scene layer")

SeqCommand.nonBlocking(tFields)

ScSetSceneLayer.rSchema = DFSchema.object(
    tFields,
    "Moves the actor into the specified layer."
)
SeqCommand.addEditorSchema('ScSetSceneLayer', ScSetSceneLayer.rSchema)

-- VIRTUAL FUNCTIONS --

function ScSetSceneLayer:onExecute()
    
    local rActor = EntityManager.getEntityNamed( self.ActorName )
    if rActor then
    
        local rLayer = Scene.CurrentScene:getNamedLayer( self.SceneLayerName )
        if rLayer ~= nil then
            rActor:setSceneLayer( rLayer )
        else
            Trace(TT_Error, "Couldn't find scene layer: " .. self.SceneLayerName)
        end
    else
        Trace(TT_Error, "Couldn't find entity: " .. self.ActorName)
    end

end

return ScSetSceneLayer
