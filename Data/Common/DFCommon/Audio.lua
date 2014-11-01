local DFFile = require("DFCommon.File")
local m = {
    bInitialized = false
}

-- init
function m.init(nSampleRate, nNumFrames)
    --sampleRate	( number ) Optional. Default value is 44100.
    --numFrames	( number ) Optional. Default value is 8192
    if MOAIUntzSystem then        
        MOAIUntzSystem.initialize(nSampleRate, nNumFrames)
        m.bInitialized = true
    else
        print('ERROR: MOAIUntzSystem does not exist')
    end
end

-- returns the moaiuntzsound
function m.playSound(sAudioFilePath, bLoadIntoMemory, bLooping, nLoopStartTime, nLoopEndTime)
    if not m.bInitialized then
        return
    end
    if sAudioFilePath then
        local rSound = MOAIUntzSound.new()
        if rSound then
            rSound:load(DFFile.getAudioPath(sAudioFilePath), true)
            rSound:setLooping(bLooping)
            if bLooping and nLoopStartTime and nLoopEndTime then
                rSound:setLoopPoints(nLoopStartTime, nLoopEndTime)
            end
            rSound:play()
            return rSound
        end
    end
end

function m.loadSound(sAudioFilePath)
    if sAudioFilePath then
        local rSound = MOAIUntzSound.new()
        if rSound then
            rSound:load(DFFile.getAudioPath(sAudioFilePath), false)  
            return rSound
        end
    end   
    return nil
end

function m.stopSound(rAudioRef)
    if rAudioRef then
        rAudioRef:stop()
    end
end

return m