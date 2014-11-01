local DFGraphics = require('DFCommon.Graphics')
local DFParticles = require("DFCommon.Particles")
local DFFile = require('DFCommon.File')
local DFUtil = require('DFCommon.Util')
local DFMath = require('DFCommon.Math')
local DataCache = require('DFCommon.DataCache')
local AssetSet = require('DFCommon.AssetSet')
local ParticleSystemManager = require('ParticleSystemManager')
local Renderer = require('Renderer')

local ParticleEffect = {}

local tFlags = {
	DebugDrawName = true,
	DebugDrawCenter = true,
	DebugDrawBounds = false,
}

-- CONSTRUCTOR --
function ParticleEffect.new( rEntity, sResource )
	
	-- PRE-CONSTRUCTOR --
    local self = DFUtil.deepCopy( ParticleEffect )	
    
	self.rEntity = rEntity
	self.sResource = sResource
    
    self.rRootProp = nil
    self.tRootOffsetLocation = { 0, 0, 0 }
    self.tRootOffsetRotation = { 0, 0, 0 }
    self.rTargetProp = nil
    self.tTargetOffset = { 0, 0, 0 }
    
    self.bStarted = false
    self.bStopped = false    
	
	if not self.sResource then
		Trace( "No particle file specified!" )
	else 
		self:preload()
	end
    
    return self
end

-- PUBLIC FUNCTIONS --
function ParticleEffect:preload()
    self:_getParticleSystemData()
end

function ParticleEffect:init(rEntity)

    if self.rEntity == nil and rEntity ~= nil then
        self.rEntity = rEntity
    end

    -- Create the actual particle system
    self:_createParticleSystem()
end

function ParticleEffect:unload()
    
    if self.bUnloaded == true then
        return
    end
    
    -- Make sure we can't see invalid particles
    self:stop(true)
    self:removeFromEntity()
    self:removeFromSceneLayer()

    -- Now it's be safe to unload the graphics resources
    if self.sResource ~= nil then
        DFParticles.unloadParticleData( self.sResource )
    end
    self.rParticleSystemData = nil
    
    self.rEntity = nil
    self.rSceneLayer = nil
    self.rParticleSystem = nil
    
    self.bUnloaded = true
end

function ParticleEffect:isUnloaded()
    return self.rParticleSystem == nil or self:isDone()
end

function ParticleEffect:addToEntity()

    assert(self.rEntity ~= nil and self.rSceneLayer == nil)
    
    self.rEntity:addProp(self.rParticleSystem)
end

function ParticleEffect:removeFromEntity()

    if self.bUnloaded == true or self.bStarted == false then
        return
    end
    
    --assert(self.rEntity ~= nil and self.rSceneLayer == nil)
    
    if self.rEntity then
        self.rEntity:removeProp(self.rParticleSystem)
    end
end	

function ParticleEffect:addToSceneLayer(rSceneLayer)

    assert(rSceneLayer ~= nil and self.rSceneLayer == nil and self.rEntity == nil)
    
    self.rSceneLayer = rSceneLayer
    self.rSceneLayer:addProp(self.rParticleSystem)
end

function ParticleEffect:removeFromSceneLayer()

    if self.bUnloaded == true then
        return
	end
	
    --assert(self.rSceneLayer ~= nil and self.rEntity == nil)
    
    if self.rSceneLayer then
        self.rSceneLayer:removeProp(self.rParticleSystem)
        self.rSceneLayer = nil
    end
end

function ParticleEffect:setRootProp(rProp, scaleFactor)

	scaleFactor = scaleFactor or 300.0

    if rProp == nil and self.rEntity ~= nil then
        rProp = self.rEntity.rProp
		scaleFactor = 1.0
    end

    self.rParticleSystem:clearAttrLink(MOAIProp.INHERIT_TRANSFORM)
    
    self.rRootProp = rProp
    if self.rRootProp ~= nil then
        self.rParticleSystem:setAttrLink(MOAIProp.INHERIT_TRANSFORM, self.rRootProp, MOAIProp.TRANSFORM_TRAIT)
		self.rParticleSystem:setScaleFactor(1.0 / scaleFactor)
    else
		self.rParticleSystem:setScaleFactor()
	end
end

function ParticleEffect:onTick(dt)

--[[ useful for debugging rotation issues
    if not self.nRotY then self.nRotY = 0 end
    self.nRotY = self.nRotY + 5
    self.nRotY = 180
    self.rParticleSystem:setRot(30, self.nRotY, 0)
    ]]--
end

function ParticleEffect:setOffsetLocation(tOffset)

    self.tRootOffsetLocation = DFUtil.deepCopy(tOffset)
    self:_updateRootOffset()
end

function ParticleEffect:setOffsetRotation(tOffset)

    self.tRootOffsetRotation = DFUtil.deepCopy(tOffset)
    self:_updateRootOffset()
end

function ParticleEffect:setTargetProp(rProp)

    self.rTargetProp = rProp
    self.rParticleSystem:setTarget(self.rTargetProp)
end

function ParticleEffect:setTargetOffset(tOffset)

    self.tTargetOffset = DFUtil.deepCopy(tOffset)
    self.rParticleSystem:setTargetOffset(unpack(self.tTargetOffset))
end

function ParticleEffect:setSortOffset(offset)

    if offset >= -0.0001 and offset <= 0.0001 then
        self.rParticleSystem.priorityOffset = nil
    else
        self.rParticleSystem.priorityOffset = offset
    end
end

function ParticleEffect:setGroupName(sGroupName)
    self.rParticleSystem:setGroupName(sGroupName)
end

function ParticleEffect:start()
    if self.bUnloaded then
        Print(TT_Warning, 'Attempt to start unloaded particle effect.')
        return
    end
    
    local bStart = false
    if not self.bStarted or self.bStopped then
        bStart = true
    else
        bStart = self:isDone()
    end
    
    if bStart then
        -- Patricks fix should make this work properly
        -- forceUpdate appears to work via push, not pull, so we tell the root node to update.
	    --if self.rRootProp then self.rRootProp:forceUpdate() end

    	self.rParticleSystem:start()

        self.bStarted = true
        self.bStopped = false
    end
end

function ParticleEffect:stop( bImmediate )
    
    if self.bUnloaded == true then
        return
    end
    
    if not self.bStopped and self.bStarted then
        self.rParticleSystem:stop( bImmediate )
    end
    self.bStopped = true
end

function ParticleEffect:isDone()

    if self.bUnloaded == true then
        return true
    end
    
    if self.bStarted then
        return self.rParticleSystem:isDead()
    end
    return false
end

function ParticleEffect:setVisible( bSetting )
    if not self.bStarted or self.bStopped then
        Trace( "Can't set effect visibility when it hasn't started or is stopped!" )
        return
    end
    
    self.rParticleSystem:setVisible( bSetting )
end

function ParticleEffect:getProp()
    return self.rParticleSystem
end

-- PROTECTED FUNCTIONS --
function ParticleEffect:_createParticleSystem()

    if self.rParticleSystem == nil then
    
        -- Load the particle system data
        local rParticleSystemData = self:_getParticleSystemData()
        
        if rParticleSystemData == nil then
            local sResource = self.sResource or "<nil>"
            Trace(TT_Error, "Unable to load particle system data: " .. sResource)
            return nil
        end
        
        -- create + init C++ internal implementation object
        self.rParticleSystem = DFParticleSystem.new()
        self.rParticleSystem:initParticleSystem(rParticleSystemData)
        
        -- Make sure the particle system follows the entity by default
        if self.rEntity ~= nil then
            self:setRootProp(self.rEntity.rProp, 1.0)
        end	        
        
        ParticleSystemManager.register(self)        
        
    end
    return self.rParticleSystem
end

function ParticleEffect:_getParticleSystemData()

    -- ToDo: Move AssetSet into DFCommon and support it for textures, materials and particles
	-- Load the definition of the particle system
    if self.rParticleSystemData == nil and self.sResource ~= nil then
        self.rParticleSystemData = DFParticles.loadParticleData( self.sResource )
    end
    return self.rParticleSystemData	
end

function ParticleEffect:_updateRootOffset()
    self.tRootOffsetLocation = DFMath.sanitizeVector(self.tRootOffsetLocation, {0,0,0})
    self.tRootOffsetRotation = DFMath.sanitizeVector(self.tRootOffsetRotation, {0,0,0})
    
    local px, py, pz = unpack(self.tRootOffsetLocation)
    local rx, ry, rz = unpack(self.tRootOffsetRotation)    
    self.rParticleSystem:setOffset(px, py, pz, rx, ry, rz)
end

-- DEBUG DRAW --
function ParticleEffect.debugDrawBox(rSceneLayer, x0, y0, z0, x1, y1, z1)

    local a0, b0 = rSceneLayer:worldToWnd(x0, y0, z0)
    local a1, b1 = rSceneLayer:worldToWnd(x1, y0, z0)
    local a2, b2 = rSceneLayer:worldToWnd(x1, y1, z0)
    local a3, b3 = rSceneLayer:worldToWnd(x0, y1, z0)
    
    local c0, d0 = rSceneLayer:worldToWnd(x0, y0, z1)
    local c1, d1 = rSceneLayer:worldToWnd(x1, y0, z1)
    local c2, d2 = rSceneLayer:worldToWnd(x1, y1, z1)
    local c3, d3 = rSceneLayer:worldToWnd(x0, y1, z1)
    
    MOAIDraw.drawLine( a0, b0, a1, b1 )
    MOAIDraw.drawLine( a1, b1, a2, b2 )
    MOAIDraw.drawLine( a2, b2, a3, b3 )
    MOAIDraw.drawLine( a3, b3, a0, b0 )
    
    MOAIDraw.drawLine( c0, d0, c1, d1 )
    MOAIDraw.drawLine( c1, d1, c2, d2 )
    MOAIDraw.drawLine( c2, d2, c3, d3 )
    MOAIDraw.drawLine( c3, d3, c0, d0 )
    
    MOAIDraw.drawLine( a0, b0, c0, d0 )
    MOAIDraw.drawLine( a1, b1, c1, d1 )
    MOAIDraw.drawLine( a2, b2, c2, d2 )
    MOAIDraw.drawLine( a3, b3, c3, d3 )
end

function ParticleEffect:_debugDraw()
	
    if self.rParticleSystem ~= nil then
    
        local sDebugText = self.sResource    
        
        local rSceneLayer = self.rSceneLayer
        if rSceneLayer == nil then
            rSceneLayer = self.rEntity:getSceneLayer()        
            sDebugText = self.rEntity.sName .. ": " .. sDebugText
        end
        
        local x, y, z = self.rParticleSystem:modelToWorld()
        local cx, cy = rSceneLayer:worldToWnd(x, y, z)		
                    
        cx = math.floor( cx )
        cy = math.floor( cy )
        
        MOAIGfxDevice.setPenColor( 1, 1, 1, 1 )
        
        if tFlags.DebugDrawCenter then
            MOAIDraw.drawRect(cx - 2, cy - 2, cx + 2, cy + 2)
        end
        
        if tFlags.DebugDrawName then
        
            local numChars = #sDebugText
            cx = cx - numChars * 5
            
            local rFont = Renderer.getGlobalFont("debug")
            MOAIDraw.drawText(rFont, 30, sDebugText, cx, cy, 1, 2, 2)
        end
        
        if tFlags.DebugDrawBounds then
        
            MOAIGfxDevice.setPenColor ( 1, 0, 0, 1 )        
            local x0, y0, z0, x1, y1, z1 = self.rParticleSystem:getWorldBounds()
            if x0 ~= nil then
            
                local offset = 5
                x0 = x0 - offset
                y0 = y0 - offset
                z0 = z0 - offset
                
                x1 = x1 + offset
                y1 = y1 + offset
                z1 = z1 + offset
                
                ParticleEffect.debugDrawBox( rSceneLayer, x0, y0, z0, x1, y1, z1 )
            end
        end
    end
end

return ParticleEffect
