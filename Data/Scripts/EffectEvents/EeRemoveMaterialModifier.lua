local Util = require('DFCommon.Util')
local Class = require('Class')
local SeqCommand = require('SeqCommand')
local EffectEvent = require('EffectEvent')
local EeRemoveMaterialModifier = Class.create(EffectEvent)

local EeAddMaterialModifier = require('EffectEvents.EeAddMaterialModifier')

-- ATTRIBUTES --
EeRemoveMaterialModifier.Name = nil
EeRemoveMaterialModifier.Immediate = false

local DFSchema = require('DFCommon.DFSchema')
local tFields = Util.deepCopy(EffectEvent.rSchema.tFieldSchemas)
tFields['Name'] = DFSchema.string(nil, "Name of the material modifier to stop")

EeRemoveMaterialModifier.rSchema = DFSchema.object(
	tFields,
	"Stops a named material modifier."
)
SeqCommand.addEditorSchema('EeRemoveMaterialModifier', EeRemoveMaterialModifier.rSchema)

-- VIRTUAL FUNCTIONS --
function EeRemoveMaterialModifier:onExecute()
	
    if self.Name == nil or #self.Name <= 0 then
        return
    end
    
    local bFound = false
    
    for i=1,self.rEffect.numEvents do
        local rEvent = self.rEffect.tEvents[i]
        if rEvent:is(EeAddMaterialModifier) then
            if rEvent.Name == self.Name then
                rEvent:_clearMaterialMod()
                bFound = true
                break
            end
        end
    end
    
    if not bFound then
        Trace(TT_Warning, "Couldn't find material modifier event to stop: " .. self.Name)
    end
end

return EeRemoveMaterialModifier
