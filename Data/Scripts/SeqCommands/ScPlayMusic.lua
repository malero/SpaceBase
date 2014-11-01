local Util = require('DFCommon.Util')
local GameRules = require('GameRules')
local SoundManager = require('SoundManager')

local SeqCommand = require('SeqCommand')
local Class = require('Class')
local ScPlayMusic = Class.create(SeqCommand)

ScPlayMusic.LeaveMusicPlaying = false

local DFSchema = require('DFCommon.DFSchema')
local tFields = Util.deepCopy(SeqCommand.rSchema.tFieldSchemas)
tFields['MusicCue'] = DFSchema.string(nil, "The music cue to play (for playing sounds, please use PlaySound).")
tFields['LeaveMusicPlaying'] = DFSchema.bool(nil, "Whether to leave the music playing in the game.")

ScPlayMusic.rSchema = DFSchema.object(tFields, "Plays music.")
SeqCommand.addEditorSchema('ScPlayMusic', ScPlayMusic.rSchema)

function ScPlayMusic:onExecute()     
    if self.rEvent and self.rEvent:isValid() then
        self.rEvent:stop()
    end
    
    if not self.bSkip and self.MusicCue then
        SoundManager.playMusicFromCue( self.MusicCue, true )
    end
end

function ScPlayMusic:onCleanup()
    if not self.LeaveMusicPlaying then
        -- clear out the override to resume regular music
        SoundManager.clearMusic( self.MusicCue )         
    end
end

return ScPlayMusic
