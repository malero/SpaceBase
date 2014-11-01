local Util = require('DFCommon.Util')
local Class = require('Class')
local SeqCommand = require('SeqCommand')
local AnimEvent = require('AnimEvent')
local SoundManager = require('SoundManager')
local Character = require('Character')
local AeCharacterSpeak = Class.create(AnimEvent)
local DFSchema = require('DFCommon.DFSchema')
local tFields = Util.deepCopy(AnimEvent.rSchema.tFieldSchemas)
tFields['Cue'] = DFSchema.string(nil, "Sound cue (exclude race/sex), i.e. 'Positive' or 'Panic'")

AeCharacterSpeak.rSchema = DFSchema.object(
	tFields,
	"Make the character say something in their race/sex voice."
)
SeqCommand.addEditorSchema('AeCharacterSpeak', AeCharacterSpeak.rSchema)

-- VIRTUAL FUNCTIONS --
function AeCharacterSpeak:onExecute()
	
    if MOAIFmodEventMgr == nil then
        return
    end
    
    if self.Cue ~= nil and #self.Cue > 0 then
        
        if self:_getDebugFlags().DebugExecution then
            Trace("Playing sound cue: " .. self.Cue)
        end

        if self.rEntity ~= nil and self.rEntity.rProp ~= nil then
            self.rEvent = self.rEntity.rProp:playVoiceCue(self.Cue)
        end
    end
end

function AeCharacterSpeak:onCleanup()

    if self.rEvent ~= nil and self.rEvent:isValid() then
        self.rEvent:stop()        
        self.rEvent = nil
    end
end

-- PUBLIC FUNCTIONS --

return AeCharacterSpeak
