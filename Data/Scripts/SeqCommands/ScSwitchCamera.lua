local DFUtil = require('DFCommon.Util')
local Class = require('Class')
local SeqCommand = require('SeqCommand')
local ScSwitchCamera = Class.create(SeqCommand)

local EntityManager = require('EntityManager')

-- ATTRIBUTES --
ScSwitchCamera.CameraName = ""
ScSwitchCamera.Duration = 0
ScSwitchCamera.UseForGameplay = false

local DFSchema = require('DFCommon.DFSchema')
local tFields = DFUtil.deepCopy(SeqCommand.rSchema.tFieldSchemas)
tFields['CameraName'] = DFSchema.entityName(nil, "Name of the camera to switch to", "")
tFields['Duration'] = DFSchema.number(0,"(optional) The time over which to interpolate to the new camera")
tFields['UseForGameplay'] = DFSchema.bool(false,"(optional) Should this camera be deactivated when the cutscene is over or carry over to gameplay")
ScSwitchCamera.rSchema = DFSchema.object(
    tFields,
    "Plays the specified line on the actor."
)
SeqCommand.addEditorSchema('ScSwitchCamera', ScSwitchCamera.rSchema)
SeqCommand.metaFlag(tFields, "CameraCommand")

-- VIRTUAL FUNCTIONS --

function ScSwitchCamera:onExecute()    
    if self:_getDebugFlags().DebugExecution then        
        local line = self.LineCode or self.Line or ""
        Trace( "Switching to camera " .. self.CameraName .. " in " ..  self.Duration .. " secs" )
    end    
    
    local rCamera = EntityManager.getEntityNamed( self.CameraName )    
    
    if rCamera then
        local coCamera = rCamera:getComponent( "CoCamera" )
        if coCamera then
            if coCamera:isActive() then
                Trace( TT_Warning, "Camera ".. self.CameraName.. " is already active. It could mean that this is the main camera for the scene -- it should not be switched to else bad things happen.")
            end

            if not self.bSkip then
                coCamera:setCutscenePriority(true)
                coCamera:activate( self.Duration )

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

            if self.bSkip then                       
                coCamera:activate( 0 )
            end
        else
            Trace(TT_Error, "Camera " .. self.CameraName .. " has no CoCamera")
        end       
        
    else
        Trace(TT_Error, "Couldn't find camera: " .. self.CameraName)
    end
end

function ScSwitchCamera:onCleanup()
    local rCamera = EntityManager.getEntityNamed( self.CameraName )    
    if rCamera and rCamera.CoCamera then        
        rCamera.CoCamera:setCutscenePriority(false)
        if not self.UseForGameplay then            
            rCamera.CoCamera:deactivate(0)
        end    
    end
end

-- PUBLIC FUNCTIONS --

return ScSwitchCamera
