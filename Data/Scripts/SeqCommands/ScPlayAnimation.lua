local Util = require('DFCommon.Util')
local Class = require('Class')
local SeqCommand = require('SeqCommand')
local ScPlayAnimation = Class.create(SeqCommand)

local EntityManager = require('EntityManager')

-- ATTRIBUTES --
ScPlayAnimation.ActorName = ""
ScPlayAnimation.UseAsFinalPosition = false

local DFSchema = require('DFCommon.DFSchema')
local tFields = Util.deepCopy(SeqCommand.rSchema.tFieldSchemas)
tFields['ActorName'] = DFSchema.entityName(nil, "Name of the actor", "ControllingActor")
tFields['Animation'] = DFSchema.resource(nil, 'Unmunged', '.anim', "The path to the animation")
tFields['FlipSides'] = DFSchema.bool(false, "Flip the direction of the animation (from facing to the E to facing to the W)")
tFields['ScriptedAnimation'] = DFSchema.string(nil, "(optional) Only used when the Animation field is clear -- the type of animation to play as defined by the Stance")
tFields['ScriptedAnimationState'] = DFSchema.string(nil, "(optional) The state to switch to before this animation plays (the transition animation will play if the command is blocking)")
tFields['ScriptedAnimationCategory'] = DFSchema.string(nil, "(optional) Lets you play a scripted animation at a category other than Cutscene, which is the default")
tFields['UseEntityScaling'] = DFSchema.bool(false, "Ignore the delta-trans scaling of the animation and use the entity scaling instead?")
tFields['UseAsFinalPosition'] = DFSchema.bool(false, "Should the animation's final position be used for the character's final position?")
tFields['Looping'] = DFSchema.bool(false, "Does the animation loop?")

ScPlayAnimation.rSchema = DFSchema.object(
    tFields,
    "Plays the specified animation on the actor."
)
SeqCommand.addEditorSchema('ScPlayAnimation', ScPlayAnimation.rSchema)

-- VIRTUAL FUNCTIONS --
function ScPlayAnimation:onExecute()
    local rActor = EntityManager.getEntityNamed( self.ActorName )
    local coAnimation = rActor and rActor.CoAnimation

    if self.bSkip then
        -- only scripted animations are valid to play
        if self.ScriptedAnimationState and coAnimation then
            coAnimation:setAnimationState( self.ScriptedAnimationState, true )
        end
        if self.ScriptedAnimation and coAnimation then
            local sCategory = self.ScriptedAnimationCategory or "Cutscene"                                        
            coAnimation:playAnimationOfType( self.ScriptedAnimation, sCategory, self.Blocking or not self.Looping )
        end
        return
    end

    if self:_getDebugFlags().DebugExecution then
        local sAnimation = self.Animation or self.ScriptedAnimation or self.ScriptedAnimationState        
        Trace("Playing animation " .. sAnimation .. " on entity " .. self.ActorName)
    end

    if rActor then
        -- stop any navigation
        local coNavigator = rActor.CoNavigator
        if coNavigator then
            coNavigator:cancelNavigation()
        end

        if coAnimation then
            if self.Animation then
                local tAnimation = {}
                tAnimation.sAnimName = self.Animation
                tAnimation.sFilename = self.Animation                
                tAnimation.bFlipX = self.FlipSides         
                tAnimation.bUseEntityScaling = self.UseEntityScaling
                tAnimation.bApplyFinalTrackerLocation = self.UseAsFinalPosition
                
                if self.rSequence.bLoop then
                    -- Because of timing issues it is possible that the animation won't be played in a looping cutscene,
                    -- because the previous instance of the animation is still running, so make sure to clear the category first.
                    coAnimation:clearCategory( "Cutscene" )
                end
                
                coAnimation:playAnimation(tAnimation, "Cutscene", not self.Looping)
                if self.Blocking then
                    coroutine.yield()
                    while coAnimation:isPlayingAnimOfType( self.Animation, "Cutscene" ) and not self.bSkip do
                        coroutine.yield()
                    end
                end
            else
                -- first check if we need to switch stances
                if self.ScriptedAnimationState then
                    local tTransitionAnim = coAnimation:setAnimationState( self.ScriptedAnimationState, true )
                    if tTransitionAnim then
                        coAnimation:playAnimation( tTransitionAnim, "Immediate", true )            
                        -- account for the one-frame delay in playing animations
                        if self.Blocking then
                            coroutine.yield()                        
                            while coAnimation:isPlayingAnimOfType( tTransitionAnim.sAnimName, "Cutscene" ) and not self.bSkip do
                                coroutine.yield()
                            end 
                        end
                    end
                end
                
                -- now play the anim itself, if there is one
                if self.ScriptedAnimation then
                    local sCategory = self.ScriptedAnimationCategory or "Cutscene"                                        
                    coAnimation:playAnimationOfType( self.ScriptedAnimation, sCategory, self.Blocking or not self.Looping )
                    if self.Blocking then
                        coroutine.yield()
                        while coAnimation:isPlayingAnimOfType( self.ScriptedAnimation, "Cutscene" ) and not self.bSkip do
                            coroutine.yield()
                        end
                    end
                end           
            end
        else
            Trace(TT_Error, "Entity " .. self.ActorName .. " has no CoAnimation")
        end
    else
        Trace(TT_Error, "Couldn't find entity: " .. self.ActorName)
    end

end

function ScPlayAnimation:onCleanup()
    local rActor = EntityManager.getEntityNamed( self.ActorName )
    if rActor then
        local coAnimation = rActor.CoAnimation
        if coAnimation then
            coAnimation:clearCategory( "Cutscene" )
        end
    end
end

-- PUBLIC FUNCTIONS --

return ScPlayAnimation
