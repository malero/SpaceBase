local DFUtil = require('DFCommon.Util')
local Class = require('Class')
local SeqCommand = require('SeqCommand')
local ScPlayDialogSet = Class.create(SeqCommand)

local EntityManager = require('EntityManager')
local GameRules = require('GameRules')

-- ATTRIBUTES --
ScPlayDialogSet.ActorName = ""
ScPlayDialogSet.CinematicDisplay = false
ScPlayDialogSet.UseBabbleAnimation = true
ScPlayDialogSet.UseGenericTalkAnimation = true

local DFSchema = require('DFCommon.DFSchema')
local tFields = DFUtil.deepCopy(SeqCommand.rSchema.tFieldSchemas)
tFields['ActorToSpeak'] = DFSchema.entityName(nil, "Name of the actor", "ControllingActor")
tFields['SetName'] = DFSchema.string(nil, "The set to play")
tFields['DialogSetFile'] = DFSchema.resource(nil, 'Lua', '.lua', "The path to the dialog set", nil, "dialogSet")

ScPlayDialogSet.rSchema = DFSchema.object(
    tFields,
    "Plays the specified dialog set on the actor."
)
SeqCommand.addEditorSchema('ScPlayDialogSet', ScPlayDialogSet.rSchema)

-- VIRTUAL FUNCTIONS --

function ScPlayDialogSet:onExecute()

    if self:_getDebugFlags().DebugExecution then        
        local line = self.LineCode or self.Line or ""
        Trace(TT_Gameplay, "Playing dialog set " .. self.SetName .. " on entity " .. self.ActorToSpeak)
    end
    
    local rActor = EntityManager.getEntityNamed( self.ActorToSpeak )
    if rActor then
        local coVoice = rActor.CoVoice
        if rActor.CoVoice then
            -- stop whatever other set and line we might be playing
            coVoice:stopCurrentLine()
            coVoice:stopCurrentSet()
            
            if not self.bSkip then
                coVoice:playDialogSet( self.SetName, self.DialogSetFile, nil, true )
                if self.Blocking then
                    coroutine.yield()
                    while coVoice:isPlayingSet( self.SetName ) and not self.bSkip do
                        coroutine.yield()
                    end
                    coVoice:stopCurrentLine()
                    coVoice:stopCurrentSet()
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

function ScPlayDialogSet:onCleanup()
    GameRules.dLineSkip:unregister(self._onSkipped, self)
end

-- PRIVATE FUNCTIONS --

function ScPlayDialogSet:_onSkipped()
    local rActor = EntityManager.getEntityNamed( self.ActorToSpeak )
    rActor.CoVoice:stopCurrentLine()
    rActor.CoVoice:stopCurrentSet()    
    GameRules.dLineSkip:unregister(self._onSkipped, self)
end

return ScPlayDialogSet
