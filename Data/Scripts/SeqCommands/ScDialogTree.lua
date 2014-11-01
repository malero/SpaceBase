local DialogTreeManager = require('DialogTreeManager')
local DataCache = require("DFCommon.DataCache")
local DFFile = require('DFCommon.File')
local DFUtil = require('DFCommon.Util')

local SeqCommand = require('SeqCommand')
local Class = require('Class')

-- Create our class
local ScDialogTree = Class.create(SeqCommand)
ScDialogTree.Blocking = true

-- Augment the sequence command schema with our options
local DFSchema = require('DFCommon.DFSchema')
local tFields = DFUtil.deepCopy(SeqCommand.rSchema.tFieldSchemas)
tFields.tData = DFSchema.table(nil, "The data for the dialog tree.")
tFields['DialogTreeResource'] = DFSchema.resource(nil, 'DialogTrees', '.dtree', "Dialog Tree resource to play")

SeqCommand.implicitlyBlocking(tFields)

ScDialogTree.rSchema = DFSchema.object(tFields, "Triggers a Dialog Tree")

SeqCommand.addEditorSchema('ScDialogTree', ScDialogTree.rSchema)

-- Virtual functions
function ScDialogTree:onCreated()
    self.bSkipped = false
end

function ScDialogTree:onExecute()
    if not self.bSkip then
        local tTreeData = self.tData
        if not tTreeData then
            tTreeData = DataCache.getData("dtree", DFFile.getDataPath( self.DialogTreeResource ) )
        end    
        
        DialogTreeManager:playTree( tTreeData )        
        while DialogTreeManager:isPlaying() do
            coroutine.yield()
        end        
        
        DialogTreeManager:stop()
    end
end

return ScDialogTree