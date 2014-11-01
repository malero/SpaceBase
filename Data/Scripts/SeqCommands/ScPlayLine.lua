local DFUtil = require('DFCommon.Util')
local Class = require('Class')
local SeqCommand = require('SeqCommand')
local ScPlayLine = Class.create(SeqCommand)

local EntityManager = require('EntityManager')
local GameRules = require('GameRules')

-- ATTRIBUTES --
ScPlayLine.ActorName = ""
ScPlayLine.CinematicDisplay = false
ScPlayLine.UseBabbleAnimation = true
ScPlayLine.UseGenericTalkAnimation = true

local DFSchema = require('DFCommon.DFSchema')
local tFields = DFUtil.deepCopy(SeqCommand.rSchema.tFieldSchemas)
tFields['ActorToSpeak'] = DFSchema.entityName(nil, "Name of the actor", "ControllingActor")
tFields['LineCode'] = DFSchema.linecode(nil, "(optional) Line code for the line to be said. Either this or Line has to be filled out.")
tFields['Line'] = DFSchema.string(nil, "(optional) If there is no LineCode, this line will be said instead.")
tFields['CinematicDisplay'] = DFSchema.bool(false, "(optional) Whether to display this line at the bottom of the screen or near the actor (default)")
tFields['UseBabbleAnimation'] = DFSchema.bool(true, "(optional) Whether to use the babble animation generated for this linecode (usually false for cinematic cutscenes, defaults to true)")
tFields['UseGenericTalkAnimation'] = DFSchema.bool(true, "(optional) Whether to use the generic talk animation programmatically chosen for this linecode (usually false for cinematic cutscenes, defaults to true)")

ScPlayLine.rSchema = DFSchema.object(
    tFields,
    "Plays the specified line on the actor."
)
SeqCommand.addEditorSchema('ScPlayLine', ScPlayLine.rSchema)

-- VIRTUAL FUNCTIONS --

function ScPlayLine:onExecute()
    -- construct a tDialogLine out of the parts provided
    local tDialogLine =
    {        
        sLine = self.Line,
        sLineCode = self.LineCode,
        bCinematicDisplay = self.CinematicDisplay,        
        bNoBabble = not self.UseBabbleAnimation,
        bNoGenericTalk = not self.UseGenericTalkAnimation,
        bFromCutscene = true,
    }

    if self:_getDebugFlags().DebugExecution and not self.bSkip then

        local atTime = ""
        if self.rSequence.rSyncTimer then
            local seqTime = self.rSequence.rSyncTimer:getTime()
            local seqFrame = seqTime * 30
            atTime = " (time: " .. tostring(seqTime) .. " frame: " .. tostring(seqFrame) .. ")"
        end
            
 
        local line = self.LineCode or self.Line or ""
        Trace(TT_Gameplay, "Playing line " .. line .. " on entity " .. self.ActorToSpeak .. atTime)
    end
    
    local rActor = EntityManager.getEntityNamed( self.ActorToSpeak )
    if rActor then
        local coVoice = rActor.CoVoice
        if coVoice then
            -- stop whatever other line we might be playing
            coVoice:stopCurrentLine()
            
            if not self.bSkip then
                coVoice:sayLine( tDialogLine )
                if self.Blocking then
                    coroutine.yield()
                    while coVoice:isPlayingLine() and not self.bSkip do
                        coroutine.yield()
                    end
                    coVoice:stopCurrentLine()
                else
                    -- need to be notified if this gets skipped
                     GameRules.dLineSkip:register(self._onSkipped, self)                    
                end
            end
        else
            Trace(TT_Error, "Entity " .. self.ActorToSpeak .. " has no CoVoice")
        end
    else
        Trace(TT_Error, "Couldn't find entity: " .. self.ActorToSpeak)
    end

end

function ScPlayLine:onCleanup()
    GameRules.dLineSkip:unregister(self._onSkipped, self)
end

-- PRIVATE FUNCTIONS --

function ScPlayLine:_onSkipped()
    local rActor = EntityManager.getEntityNamed( self.ActorToSpeak )
    rActor.CoVoice:stopCurrentLine()
    GameRules.dLineSkip:unregister(self._onSkipped, self)
end

return ScPlayLine
