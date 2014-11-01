local Util = require('DFCommon.Util')
local Class = require('Class')
local SeqCommand = require('SeqCommand')
local AnimEvent = require('AnimEvent')
local AnimatedSprite = require('AnimatedSprite')
local DFMath = require('DFCommon/Math')
local AeCreateSpriteAnim = Class.create(AnimEvent)

local ParticleSystem = require('ParticleSystem')
local LodManager = require('LodManager')

-- ATTRIBUTES --
AeCreateSpriteAnim.OffsetRotation = { 0, 0, 0 }
AeCreateSpriteAnim.SpritesheetId = "SpriteAnims/Effects"
AeCreateSpriteAnim.OffsetRotation = nil
AeCreateSpriteAnim.LayerId = "WorldWall"
AeCreateSpriteAnim.FPS = 20
AeCreateSpriteAnim.SpriteScale = { 1, 1 }

local DFSchema = require('DFCommon.DFSchema')
local tFields = Util.deepCopy(AnimEvent.rSchema.tFieldSchemas)
tFields['SpritesheetId'] = DFSchema.string("SpriteAnims/Effects", "which spritesheet (no extension)?!")
tFields['SpriteAnimPrefix'] = DFSchema.string("", "what sprites do you want in there?")
tFields['OffsetRotation'] = DFSchema.vec3({0, 0, 0}, "Offset rotation (relative to the joint) of the animation event")
tFields['LayerId'] = DFSchema.string("WorldWall", "which layer to add the anim")
tFields['FPS'] = DFSchema.number(12, "frames per second")
tFields['SpriteScale'] = DFSchema.vec2({1, 1}, "How you want the sprite scaled!")

SeqCommand.levelOfDetail(tFields)

AeCreateSpriteAnim.rSchema = DFSchema.object(
	tFields,
	"Creates a particle system."
)
SeqCommand.addEditorSchema('AeCreateSpriteAnim', AeCreateSpriteAnim.rSchema)

-- VIRTUAL FUNCTIONS --
function AeCreateSpriteAnim:onCreated()

    AnimEvent.onCreated(self)
    
	self.OffsetRotation = Util.deepCopy(AeCreateSpriteAnim.OffsetRotation)
end

function AeCreateSpriteAnim:onPreloadCutscene(rAssetSet)   
end

function AeCreateSpriteAnim:onExecute()
    -- Init parameters
    self.tParameters = {}
    if self.JointName then self.tParameters.sJointName = self.JointName end
    if self.Offset then self.tParameters.tOffset = self.Offset end    
    
    if self:_getDebugFlags().DebugExecution then
        Trace("Playing Sprite Anim: ")
    end
    
    local spritesheetId = self.SpritesheetId or "SpriteAnims/Effects"
    local spriteAnimPrefix = self.SpriteAnimPrefix or "muzzleflash_0"
    local layerId = self.LayerId or "WorldWall"
    local fps = self.FPS or 30
    
    local Renderer = require("Renderer")
    local DFGraphics = require("DFCommon.Graphics")
    
    local rSpritesheet = DFGraphics.loadSpriteSheet( spritesheetId )
    for sSprite, _ in pairs( rSpritesheet.names ) do
        DFGraphics.alignSprite(rSpritesheet, sSprite, "center", "center", 1, 1)
    end
    local rLayer = Renderer.getRenderLayer(layerId)
    
    -- look for the joint if one is bound
    local rSprite = AnimatedSprite.new(rLayer, rSpritesheet)
    rSprite:autoSetSpritesFromPrefix(spriteAnimPrefix)
    
    if self.rEntity ~= nil and self.rEntity.rProp ~= nil then
        local rProp = self.rEntity.rProp
        local entityX, entityY, entityZ = rProp:getWorldLoc()

        local jointX, jointY, jointZ = entityX, entityY, entityZ
        
        if self.JointName then
            local rJoint = self.rEntity.rProp.rCurrentRig:getJointProp( self.JointName )
            
            jointX, jointY, jointZ = rJoint:getWorldLoc()
        end
        
        -- TODO: offsets, character rotation
        
        local charRot = self.rEntity.rProp.nCharRotation or 0
        
        local xOffsetDir = math.cos(math.rad(charRot - 90))
        local yOffsetDir = math.sin(math.rad(charRot - 90))

        local offset = self.Offset or {0, 0, 0}
        
        local xOffset = offset[1] * xOffsetDir
        local yOffset = offset[2] * yOffsetDir
        local zOffset = offset[3]

        
        local rotY = DFMath.getAngleBetween( entityX, entityY, entityX + xOffset, entityY + yOffset)
        
        
        rSprite:setRot(0, 0, charRot - 180)   
        
        
        -- move the effect to the joint + offset
        entityX = jointX + xOffset
        entityY = jointY + yOffset
        entityZ = jointZ + zOffset

        
        rSprite:setLoc(entityX,entityY,entityZ)
    end      
    
    local scale = self.SpriteScale or {1.0, 1.0}
    rSprite:setScl(scale[1], scale[2])
    
    rSprite:setFps(fps)
    rSprite:play(true, 0)
end

function AeCreateSpriteAnim:onCleanup()

end

-- PUBLIC FUNCTIONS --

return AeCreateSpriteAnim

