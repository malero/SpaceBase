local Util = require('DFCommon.Util')
local Class = require('Class')
local SeqCommand = require('SeqCommand')
local EffectEvent = require('EffectEvent')
local EeStopParticleSystem = Class.create(EffectEvent)

local EeCreateParticleSystem = require('EffectEvents.EeCreateParticleSystem')

-- ATTRIBUTES --
EeStopParticleSystem.Name = nil
EeStopParticleSystem.Immediate = false

local DFSchema = require('DFCommon.DFSchema')
local tFields = Util.deepCopy(EffectEvent.rSchema.tFieldSchemas)
tFields['Name'] = DFSchema.string(nil, "Name of the particle event to stop")
tFields['Immediate'] = DFSchema.bool(false, "Stop the particle event immediately?")

EeStopParticleSystem.rSchema = DFSchema.object(
	tFields,
	"Stops a named particle system."
)
SeqCommand.addEditorSchema('EeStopParticleSystem', EeStopParticleSystem.rSchema)

-- VIRTUAL FUNCTIONS --
function EeStopParticleSystem:onExecute()
	
    if self.Name == nil or #self.Name <= 0 then
        return
    end
    
    local bFound = false
    
    for i=1,self.rEffect.numEvents do
        local rEvent = self.rEffect.tEvents[i]
        if rEvent:is(EeCreateParticleSystem) then
            if rEvent.Name == self.Name then
                rEvent:stop(self.Immediate)
                bFound = true
                break
            end
        end
    end
    
    if not bFound then
        Trace(TT_Warning, "Couldn't find particle event to stop: " .. self.Name)
    end
end

return EeStopParticleSystem
