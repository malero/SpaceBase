local DFUtil = require('DFCommon.Util')
local Class = require('Class')
local SeqCommand = require('SeqCommand')
local ScExplanation = Class.create(SeqCommand)

local EntityManager = require('EntityManager')

-- ATTRIBUTES --
ScExplanation.Duration = 3
ScExplanation.FullScreen = false

local DFSchema = require('DFCommon.DFSchema')
local tFields = DFUtil.deepCopy(SeqCommand.rSchema.tFieldSchemas)
tFields['Explanation'] = DFSchema.string(nil, "Describe what should happen (this line will be displayed as a stand-in for the action that should take place here")
tFields['Duration'] = DFSchema.number(3, "(optional) How long to keep the line up (3 secs by default).")
tFields['FullScreen'] = DFSchema.bool(false, "(optional) Whether the explanation will take up the full screen (false by default).")

ScExplanation.rSchema = DFSchema.object(
    tFields,
    "Plays the specified line on the actor."
)
SeqCommand.addEditorSchema('ScExplanation', ScExplanation.rSchema)

-- VIRTUAL FUNCTIONS --

function ScExplanation:onExecute()
    if not self.Explanation then
        return
    end
    
    -- if we're not skipping, let's display the explanation
    if not self.bSkip then
        self:_setStandinDisplay( true, self.Explanation )        
        if self.Blocking then
            local rTimer = MOAITimer.new()
            rTimer:setType(MOAIAction.ACTIONTYPE_GAMEPLAY)  
            rTimer:setSpan(0, self.Duration)
            rTimer:start()
            while self.Blocking and rTimer:isBusy() and not self.bSkip do
                coroutine.yield()
            end     
             -- turn off display
            self:_setStandinDisplay( false )        
        else
            -- start coroutine with _playSequence    
            self.rDisplayingThread = MOAICoroutine.new()
            self.rDisplayingThread:setType(MOAIAction.ACTIONTYPE_GAMEPLAY)            
            self.rDisplayingThread:run( ScExplanation._displayMonitor, self )
        end
    else
        if self.rDisplayingThread then
            self.rDisplayingThread:stop()
            self.rDisplayingThread = nil                        
        end
        -- turn off display
        self:_setStandinDisplay( false )               
    end
    
    
end

-- PRIVATE FUNCTIONS --

function ScExplanation._displayMonitor( rExplanation )
    local rTimer = MOAITimer.new()
    rTimer:setType(MOAIAction.ACTIONTYPE_GAMEPLAY)  
    rTimer:setSpan(0, rExplanation.Duration)
    rTimer:start()
    while rTimer:isBusy() and not rExplanation.bSkip do
        coroutine.yield()
    end 
    -- turn off display
    rExplanation:_setStandinDisplay( false )        
end

function ScExplanation:_setStandinDisplay(bSetting, sText)    
    local Renderer = require("Renderer")
    local rRenderLayer = Renderer.getRenderLayer("UI")
    if bSetting then    
        if not self._rStandinTextBox then
            -- get viewport stats ---------------------------------------------------------
            local rx0, ry0, rx1, ry1 = Renderer.getViewportRect()
            local dx, dy = rx1 - rx0, ry1 - ry0
            local aspectRatio = dy / dx    
            ------------------------------------------------------------------------------- 
            local safeHeight = dx * aspectRatio    
            local height = .1 * safeHeight
            local standinHeight = safeHeight - height
            local width = dx
            local x, y = 0, safeHeight - height
            
            if self.FullScreen then
                height = safeHeight
                standinHeight = kVirtualScreenHeight
                y = 0
            end            
                        
            -- create the background for the text            
            local rWhiteTex = Renderer.getGlobalTexture( "white" )		
            local gfxQuad = MOAIGfxQuad2D.new ()
            gfxQuad:setTexture ( rWhiteTex )
            gfxQuad:setRect ( 0, 0, 1, 1 )
            gfxQuad:setUVRect ( 0, 0, 1, 1 )
            
            self._rStandinBackground = MOAIProp2D.new()
            self._rStandinBackground:setDeck( gfxQuad )    
            self._rStandinBackground:setColor( 0, 0, 0, 1 )        
            self._rStandinBackground:setLoc(x, y )                     
            self._rStandinBackground:setScl( width, standinHeight )        
            
            rRenderLayer:insertProp( self._rStandinBackground )           
            
            -- create the text box
            self._rStandinTextBox = MOAITextBox.new()
            self._rStandinTextBox:setFont( Renderer.getGlobalFont("standin") )        
            self._rStandinTextBox:setTextSize( 30 )
            self._rStandinTextBox:setAlignment(MOAITextBox.CENTER_JUSTIFY, MOAITextBox.CENTER_JUSTIFY)        
            self._rStandinTextBox:setColor(1, 1, 1)                                
                    
            rRenderLayer:insertProp( self._rStandinTextBox )                          
            
            self._rStandinTextBox:setRect( x,y, x+width, y+height )                                
        end    
        
        self._rStandinTextBox:setString(sText)    
        self._rStandinTextBox:revealAll()    

        rRenderLayer:insertProp( self._rStandinBackground )        
        rRenderLayer:insertProp( self._rStandinTextBox )
    else
        if self._rStandinTextBox then
            rRenderLayer:removeProp( self._rStandinTextBox )
            rRenderLayer:removeProp( self._rStandinBackground )
        end
    end
        
end

-- PUBLIC FUNCTIONS --

return ScExplanation
