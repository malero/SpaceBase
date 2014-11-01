local Util = require('DFCommon.Util')
local Class = require('Class')
local SeqCommand = require('SeqCommand')
local EffectEvent = require('EffectEvent')
local EePlaySound = Class.create(EffectEvent)

-- ATTRIBUTES --
EePlaySound.KeepAlive = true

local DFSchema = require('DFCommon.DFSchema')
local tFields = Util.deepCopy(EffectEvent.rSchema.tFieldSchemas)
tFields['Cue'] = DFSchema.string(nil, "The sound cue to play.")
tFields['KeepAlive'] = DFSchema.bool(true, "Keep the anim event alive after the animation ends or destroy it")

EePlaySound.rSchema = DFSchema.object(
	tFields,
	"Plays a sound."
)
SeqCommand.addEditorSchema('EePlaySound', EePlaySound.rSchema)

-- VIRTUAL FUNCTIONS --
function EePlaySound:onExecute()
	
    if MOAIFmodEventMgr == nil then
        return
    end
    
    if self.Cue ~= nil and #self.Cue > 0 then
        
        if self:_getDebugFlags().DebugExecution then
            Trace("Playing sound cue: " .. self.Cue)
        end
        
        self.rEvent = MOAIFmodEventMgr.playEvent2D( self.Cue )
        --[[
        if self:_getDebugFlags().DebugLoading then
            if self.rEvent == nil or not self.rEvent:isValid() then
                Trace("Couldn't play audio cue: " .. self.Cue)
            end
        end
        ]]--
    end
end

function EePlaySound:onCleanup()

    if self.rEvent ~= nil and self.rEvent:isValid() then
    
        if self.KeepAlive == false then
            self.rEvent:stop()
        end
        self.rEvent = nil
    end
end

-- PUBLIC FUNCTIONS --

return EePlaySound
