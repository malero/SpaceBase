local DFUtil = require('DFCommon.Util')
local Class = require('Class')
local GameRules = require('GameRules')
local Renderer = require( "Renderer" )
local SeqCommand = require('SeqCommand')
local Sequence = require( "Sequence" )
local ScFade = Class.create(SeqCommand)

local EntityManager = require('EntityManager')

-- ATTRIBUTES --
ScFade.CameraName = ""
ScFade.Duration = 0
ScFade.Hold = -1
ScFade.OutDuration = 0
ScFade.FadeToScene = true

local DFSchema = require('DFCommon.DFSchema')
local tFields = DFUtil.deepCopy(SeqCommand.rSchema.tFieldSchemas)
tFields['FadeToScene'] = DFSchema.bool(true, "Set to true if you want to fade to scene, false if you want to fade to flat color")
tFields['Duration'] = DFSchema.number(0, "(optional) The time over which to start the fade")
ScFade.rSchema = DFSchema.object(
    tFields,
    "Fades the screen to or from a color"
)
SeqCommand.addEditorSchema('ScFade', ScFade.rSchema)

-- VIRTUAL FUNCTIONS --

function ScFade:onExecute()
    if self:_getDebugFlags().DebugExecution then                
        Trace( "Doing a fade" )
    end    
    
    if not self.bSkip then
        self:_setFade( self.Duration )
        if self.Blocking then
            -- wait unless we're being skipped
            local rTimer = MOAITimer.new()
            rTimer:setType(MOAIAction.ACTIONTYPE_GAMEPLAY)  
            rTimer:setSpan(0, self.Duration)
            rTimer:start()
            while self.Blocking and rTimer:isBusy() and not self.bSkip do
                coroutine.yield()
            end           
            rTimer:stop()        
        end
    end
    
    if self.bSkip then        
        self:_setFade( 0 )
    end
end

-- PRIVATE FUNCTIONS --

function ScFade:_setFade( duration )
    if self.FadeToScene then
        Renderer.fadeIn( duration )
    else
        Renderer.fadeOut( duration )
    end
end

function ScFade:onCleanup( bSkipped )
    if bSkipped then
        self:_setFade( 0 )
    end
end

return ScFade
