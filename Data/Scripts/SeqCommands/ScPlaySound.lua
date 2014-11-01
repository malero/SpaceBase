local Util = require('DFCommon.Util')
local GameRules = require('GameRules')

local SeqCommand = require('SeqCommand')
local Class = require('Class')
local ScPlaySound = Class.create(SeqCommand)

local DFSchema = require('DFCommon.DFSchema')
local tFields = Util.deepCopy(SeqCommand.rSchema.tFieldSchemas)
tFields['Cue'] = DFSchema.string(nil, "The sound cue to play (for changing music score, please use PlayMusic).")

ScPlaySound.rSchema = DFSchema.object(tFields, "Plays a sound.")
SeqCommand.addEditorSchema('ScPlaySound', ScPlaySound.rSchema)

function ScPlaySound:onExecute()         
    if MOAIFmodEventMgr == nil then
        return
    end
    
    if not self.bSkip and self.Cue and #self.Cue > 0 then
        self.rEvent = MOAIFmodEventMgr.playEvent2D( self.Cue )            
        if self.Blocking then
            coroutine.yield()
            while self.rEvent:isValid() do
                coroutine.yield()
            end
        end
    end
end

function ScPlaySound:onCleanup()
    if self.rEvent ~= nil and self.rEvent:isValid() then
        self.rEvent:stop()        
        self.rEvent = nil
    end
end

return ScPlaySound
