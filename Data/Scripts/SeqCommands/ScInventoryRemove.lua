local Util = require('DFCommon.Util')
local DFFile = require('DFCommon.File')
local Class = require('Class')
local SeqCommand = require('SeqCommand')
local DataCache = require('DFCommon.DataCache')
local GameRules = require('GameRules')
local ScInventoryRemove = Class.create(SeqCommand)

-- ATTRIBUTES --
local DFSchema = require('DFCommon.DFSchema')
local tFields = Util.deepCopy(SeqCommand.rSchema.tFieldSchemas)
tFields['InventoryResource'] = DFSchema.resource(nil, 'Inventory', '.inv', "Inventory file that contains the data to remove.")

SeqCommand.metaFlag(tFields, "LogicCommand")
SeqCommand.metaPriority(tFields, 20)

ScInventoryRemove.rSchema = DFSchema.object(
    tFields,
    "Sets a game-state value."
)
SeqCommand.addEditorSchema('ScInventoryRemove', ScInventoryRemove.rSchema)

-- VIRTUAL FUNCTIONS --
function ScInventoryRemove:onAnalyzeAssets(rClump)

    -- Item is removed so don't add the referenced assets!
end

function ScInventoryRemove:onExecute()        
    
    local rPlayerEnt = GameRules.getPlayerEntity()
    if rPlayerEnt then
        local coInventory = rPlayerEnt:getComponent( "CoInventory" )
        if coInventory then
            local tData = DataCache.getData( "inv", DFFile.getDataPath( self.InventoryResource ) )
            coInventory:removeItem( tData.sName )            
        end
    end
end

return ScInventoryRemove
