local Util = require('DFCommon.Util')
local Class = require('Class')
local SeqCommand = require('SeqCommand')
local AnimEvent = require('AnimEvent')
local AeFireProjectile = Class.create(AnimEvent)

local LodManager = require('LodManager')

-- ATTRIBUTES --
-- TODO make these attributes work

local DFSchema = require('DFCommon.DFSchema')
local tFields = Util.deepCopy(AnimEvent.rSchema.tFieldSchemas)

SeqCommand.levelOfDetail(tFields)

AeFireProjectile.rSchema = DFSchema.object(
	tFields,
	"Fires a projectile."
)
SeqCommand.addEditorSchema('AeFireProjectile', AeFireProjectile.rSchema)

-- VIRTUAL FUNCTIONS --
function AeFireProjectile:onCreated()

    
    AnimEvent.onCreated(self)
end

function AeFireProjectile:onExecute()
	
    -- Init parameters
    self.tParameters = {}
    if self.JointName then self.tParameters.sJointName = self.JointName end
    if self.Offset then self.tParameters.tOffset = self.Offset end    
    
    if self:_getDebugFlags().DebugExecution then
        Trace("Firing projectile: ")
    end
    
    if self.rEntity ~= nil and self.rEntity.rProp ~= nil and self.rEntity.rProp.rCurrentTask ~= nil then
        self.rEntity.rProp.rCurrentTask:getLeafTask():handleGenericAnimEvent( "FireProjectile", self.tParameters )
    end        
end

function AeFireProjectile:onCleanup()

end

-- PUBLIC FUNCTIONS --

return AeFireProjectile
