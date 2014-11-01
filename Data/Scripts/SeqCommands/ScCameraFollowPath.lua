local Util = require('DFCommon.Util')
local Class = require('Class')
local SeqCommand = require('SeqCommand')
local ScCameraFollowPath = Class.create(SeqCommand)

local CameraPath = require('CameraPath')
local CameraManager = require('CameraManager')
local GameRules = require('GameRules')

-- ATTRIBUTES --
ScCameraFollowPath.CameraPath = ""
ScCameraFollowPath.HoldLastFrame = true
ScCameraFollowPath.EaseOutTime = 0
ScCameraFollowPath.WaitForPlayerMove = false

local DFSchema = require('DFCommon.DFSchema')
local tFields = Util.deepCopy(SeqCommand.rSchema.tFieldSchemas)
tFields['CameraPath'] = DFSchema.resource(nil, 'Unmunged', '.canim', "The path to the camera path")
tFields['HoldLastFrame'] = DFSchema.bool(true, "Whether to skip the update for the Camera Manager for one frame")
tFields['EaseOutTime'] = DFSchema.number(0, "The ease out time into the game camera")

SeqCommand.metaFlag(tFields, "CameraCommand")

ScCameraFollowPath.rSchema = DFSchema.object(
    tFields,
    "Moves the camera along the defined path."
)
SeqCommand.addEditorSchema('ScCameraFollowPath', ScCameraFollowPath.rSchema)

-- VIRTUAL FUNCTIONS --
function ScCameraFollowPath:onExecute()

    if not self.bSkip then    
        self.rCameraPath = CameraPath.new(self.CameraPath)
        self.rCameraPath:setEaseOutTime( self.EaseOutTime )        
        
        -- Activate this camera
        -- ToDo: Expose ease-in time!
        local easeInTime = 0
        CameraManager.pushCamera(self.rCameraPath, easeInTime)
        self.bDoCleanup = true
    end    
end

function ScCameraFollowPath:onPause()
    if self.rCameraPath then
        self.rCameraPath.rAnim:pause()
    end
end

function ScCameraFollowPath:onResume()
    if self.rCameraPath then
        self.rCameraPath.rAnim:start()
    end
end

function ScCameraFollowPath:onCleanup( bSkipped )
    if self.bDoCleanup then
        -- Remove the camera from the stack
        local easeOutTime = self.EaseOutTime        
        if bSkipped then
            easeOutTime = 0
        end
        local bWaitForPlayerToMove = 0 < easeOutTime                
        
        if self.HoldLastFrame then
            GameRules:skipFrame()
        end
        CameraManager.removeCamera(self.rCameraPath, easeOutTime, bWaitForPlayerToMove)
    end
end

return ScCameraFollowPath
