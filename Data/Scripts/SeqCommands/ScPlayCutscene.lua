local DFUtil = require('DFCommon.Util')
local DFFile = require('DFCommon.File')
local GameRules = require('GameRules')
local DataCache = require('DFCommon.DataCache')

local SeqCommand = require('SeqCommand')
local Class = require('Class')
local ScPlayCutscene = Class.create(SeqCommand)
ScPlayCutscene.Blocking = true
local DFSchema = require('DFCommon.DFSchema')
local tFields = DFUtil.deepCopy(SeqCommand.rSchema.tFieldSchemas)
tFields['Cutscene'] = DFSchema.resource(nil, 'Unmunged/Interactions', '.ctsn', "The cutscene to play")
tFields['Blocking'] = DFSchema.bool(true, "Whether this cutscene should play as blocking.")

SeqCommand.metaPriority(tFields, 5)
SeqCommand.metaString(tFields, "Subsequence", "Cutscene", "Name of the field pointing to a subsequence to embed")

ScPlayCutscene.rSchema = DFSchema.object(tFields, "Plays a cutscene (in the middle of a cutscene).")
SeqCommand.addEditorSchema('ScPlayCutscene', ScPlayCutscene.rSchema)

function ScPlayCutscene:onExecute()
    -- NOTE that when the external cutscene is skipped, NONE of this cutscene's commands are called, so don't put any important logic here.
    if not self.bSkip then
        local Sequence = require('Sequence')
        local tInteractionData = DataCache.getData( "cutscene", DFFile.getAssetPath( self.Cutscene ) )
        
        self.rCutscene = Sequence.new( tInteractionData, self.Cutscene )    
        self.rCutscene:play()                
        
        while self.Blocking and self.rCutscene and not self.rCutscene:isDone() do
            coroutine.yield()
        end        
    end
    
    if self.rCutscene and ( self.bSkip or self.Blocking ) then
        self.rCutscene:stop( true )
        self.rCutscene = nil
    end
end

function ScPlayCutscene:onCleanup()
    if self.rCutscene then
        self.rCutscene:stop( true )
        self.rCutscene = nil
    end
end

return ScPlayCutscene
