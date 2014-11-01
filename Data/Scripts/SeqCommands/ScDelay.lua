local Util = require('DFCommon.Util')
local Class = require('Class')
local SeqCommand = require('SeqCommand')
local ScDelay = Class.create(SeqCommand)

-- ATTRIBUTES --
ScDelay.Duration = 0

local DFSchema = require('DFCommon.DFSchema')
local tFields = Util.deepCopy(SeqCommand.rSchema.tFieldSchemas)
tFields['Duration'] = DFSchema.number(0, "Seconds to wait before executing the next command")

SeqCommand.metaPriority(tFields, -1000)
SeqCommand.implicitlyBlocking(tFields)

ScDelay.rSchema = DFSchema.object(
    tFields,
    "Creates a new instance of the specified protoype at the given location."
)
SeqCommand.addEditorSchema('ScDelay', ScDelay.rSchema)

-- VIRTUAL FUNCTIONS --
function ScDelay:onExecute()

    if self:_getDebugFlags().DebugExecution then
        Trace("Waiting " .. tostring(self.Duration) .. " seconds")
    end    
    
    if not self.bSkip then        
    
        local duration = self.Duration
        
        -- Use the synchronization timer for non-blocking cutscenes to make sure that we don't sleep too long
        local endTime = nil
        if self.rSequence.rSyncTimer then
            local curTime = self.rSequence.rSyncTimer:getTime()
            local slippedTime = curTime - self.StartTime
            --if slippedTime ~= 0 then Trace("Slipped time: " .. tostring(slippedTime)) end
            duration = duration - slippedTime
            endTime = self.StartTime + duration
            -- Remove one frame from the duration, so we can wait on the last frame selectively
            if duration > 0.04 then
                duration = duration - 0.04
            end
        end
    
        -- wait unless we're being skipped        
        local rTimer = MOAITimer.new()
        rTimer:setType(MOAIAction.ACTIONTYPE_GAMEPLAY)
        rTimer:setSpan(0, duration)
        rTimer:start()
        while rTimer:isBusy() and not self.bSkip do
            coroutine.yield()
        end
        rTimer:stop()
        
        -- Sleep the last frame only if we are still on time
        if endTime then
            local curTime = self.rSequence.rSyncTimer:getTime()
            local overhangTime = curTime - endTime
            --if overhangTime ~= 0 then Trace("Overhang time: " .. tostring(overhangTime)) end
            -- Wait one more frame only if we didn't already sleep too long
            if overhangTime < -0.032 then
                coroutine.yield()
            end
        end
    end

end

-- PUBLIC FUNCTIONS --

return ScDelay
