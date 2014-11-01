local Util = require('DFCommon.Util')
local Class = require('Class')
local SeqCommand = require('SeqCommand')
local AnimEvent = require('AnimEvent')
local SoundManager = require('SoundManager')
local AePlaySound = Class.create(AnimEvent)

AePlaySound.Play2D = true

local DFSchema = require('DFCommon.DFSchema')
local tFields = Util.deepCopy(AnimEvent.rSchema.tFieldSchemas)
tFields['Cue'] = DFSchema.string(nil, "The sound cue to play.")
tFields['Play2D'] = DFSchema.bool(true, "Play as 2D or 3D sound.")

AePlaySound.rSchema = DFSchema.object(
	tFields,
	"Plays a sound."
)
SeqCommand.addEditorSchema('AePlaySound', AePlaySound.rSchema)

-- VIRTUAL FUNCTIONS --
function AePlaySound:onExecute()
	
    if MOAIFmodEventMgr == nil then
        return
    end
    
    if self.Cue ~= nil and #self.Cue > 0 then
        
        if self:_getDebugFlags().DebugExecution then
            Trace("Playing sound cue: " .. self.Cue)
        end

        if self.Play2D then
            self.rEvent = MOAIFmodEventMgr.playEvent2D( self.Cue )
        else
            local x,y,z = self.rEntity.rProp:getLoc()

            self.rEvent = MOAIFmodEventMgr.playEvent3D( self.Cue, x, y, 0)
        end

        --[[
        if self:_getDebugFlags().DebugLoading then
            if self.rEvent == nil or not self.rEvent:isValid() then
                Trace("Couldn't play audio cue: " .. self.Cue)
            end
        end
        ]]--
    end
end

function AePlaySound:onCleanup()

    if self.rEvent ~= nil and self.rEvent:isValid() then
        self.rEvent:stop()        
        self.rEvent = nil
    end
end

-- PUBLIC FUNCTIONS --

return AePlaySound
