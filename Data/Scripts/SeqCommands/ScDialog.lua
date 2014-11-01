local Util = require('DFCommon.Util')
local DialogTreeManager = require('DialogTreeManager')

local SeqCommand = require('SeqCommand')
local Class = require('Class')

-- Create our class
local ScDialog = Class.create(SeqCommand)

-- Augment the sequence command schema with our options
local DFSchema = require('DFCommon.DFSchema')
local tFields = Util.deepCopy(SeqCommand.rSchema.tFieldSchemas)
tFields.tData = DFSchema.table(nil, "The data for the dialog tree.")

ScDialog.rSchema = DFSchema.object(tFields, "Triggers an actor to say a line.")
SeqCommand.addEditorSchema('ScDialog', ScDialog.rSchema)

-- Virtual functions
function ScDialog:onCreated()
    self.bSkipped = false
end

function ScDialog:onExecute()
    DialogTreeManager:playTree(self.tData)
    if self.Blocking then
        while DialogTreeManager:isPlaying() do
            coroutine.yield()
        end
    end
end

return ScDialog