local Util = require('DFCommon.Util')
local DFFile = require('DFCommon.File')
local Class = require('Class')
local SeqCommand = require('SeqCommand')
local ScInventoryAdd = Class.create(SeqCommand)
local DataCache = require('DFCommon.DataCache')
local GameRules = require('GameRules')

-- ATTRIBUTES --
local DFSchema = require('DFCommon.DFSchema')
local tFields = Util.deepCopy(SeqCommand.rSchema.tFieldSchemas)
tFields['InventoryResource'] = DFSchema.resource(nil, 'Inventory', '.inv', "Inventory file that contains the data to add.")

SeqCommand.metaFlag(tFields, "LogicCommand")
SeqCommand.metaPriority(tFields, 20)

ScInventoryAdd.rSchema = DFSchema.object(
    tFields,
    "Sets a game-state value."
)
SeqCommand.addEditorSchema('ScInventoryAdd', ScInventoryAdd.rSchema)

-- VIRTUAL FUNCTIONS --
function ScInventoryAdd:onExecute()            
    local rPlayerEnt = GameRules.getPlayerEntity()
    if rPlayerEnt then
        local coInventory = rPlayerEnt:getComponent( "CoInventory" )
        if coInventory then
            coInventory:addItem( self.InventoryResource, nil, true )
        end
    end
end

return ScInventoryAdd
