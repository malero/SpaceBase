----------------------------------------------------------------
-- Copyright (c) 2012 Double Fine Productions
-- All Rights Reserved. 
----------------------------------------------------------------

local Debugger = require('DFMoai.Debugger')
local Editor = require('DFMoai.Tools.Editor')
local Pickle = require('DFMoai.Pickle')
local Particles = require('DFCommon.Particles')
local Graphics = require('DFCommon.Graphics')
local File = require('DFCommon.File')

local ParticleSystem = require("ParticleSystem")

-- Create ParticleEdit in the global namespace
ParticleEdit = {}
setmetatable(ParticleEdit, { __index = Editor })

function ParticleEdit:init(rViewport)
    Editor.init(self)
    
    self.rViewport = rViewport
    local tData = dofile(self:modelFile())
    self:filterData(tData)
    self:ready('ParticleEdit', tData, Particles.rSchema )      
    
    self.pointerX, self.pointerY = MOAIInputMgr.device.pointer:getLoc() 
    
        -- Set up the camera
    self.rCamera = MOAICamera.new()
    self.rCamera:setOrtho(false)
    self.rCamera:setLoc( 0, 0, 1000 )
    self.rCamera:setScl( 1, -1 ) 
    DFEffects.setCamera(self.rCamera)
    
    -- Set up our editing rendering
    self.rLayer = MOAILayer.new()
    self.rLayer:setCamera(self.rCamera)
    self.rLayer:setViewport(self.rViewport)
    MOAISim.pushRenderPass(self.rLayer)
    
    Debugger.dFileChanged:register(self.onFileChanged, self)
    
    self:restartEffect()
end

function ParticleEdit:onFileChanged(sPath)
    local sAssetPath = File.getAssetPath(self:_getParticlePath())
    if sAssetPath == sPath or sAssetPath:gsub('Munged/', '_Cache/') == sPath then
        self:restartEffect()
    end
end

function ParticleEdit:filterData(tData)
    -- Discontinue constant key particle systems
    for sKey, rFieldSchema in pairs(Particles.rSchema.tFieldSchemas) do
        if rFieldSchema.tTypes[1] == 'curve' then
            local tCurveData = tData[sKey]
            if tCurveData and #tCurveData == 1 and type(tCurveData[1]) == 'number' then
                local value = tCurveData[1]
                tData[sKey] = { { 0, value, 0, 0 }, { 1, value, 0, 0 } }
            end
        end
    end
end

function ParticleEdit:restartEffect()
    local sResourcePath = self:_getParticlePath()

    if self.rPfx then
        local pfxProp = self.rPfx:getProp()
        pfxProp:stop()
        self.rLayer:removeProp(pfxProp) 
        -- Not necessary unless we remunge, too.
        -- Particles.reloadParticleData(sResourcePath)
    end

    self.rPfx = ParticleSystem.new(nil, sResourcePath)
    self.rPfx:init()
    
	local pfxProp = self.rPfx:getProp()
	pfxProp:start()
	self.rLayer:insertProp(pfxProp) 
end

function ParticleEdit:thread()
    while true do
        self:_tickInput()
        coroutine.yield()
    end
end

function ParticleEdit:_getParticlePath()
    return self:modelFile():gsub('Unmunged/', '')
end

function ParticleEdit:_tickInput()
    -- Update our mouse delta
    local x, y = MOAIInputMgr.device.pointer:getLoc()
    local dx, dy = x - self.pointerX, y - self.pointerY
    self.pointerX, self.pointerY = x, y

    -- Get the world-space ray for this mouse position
    local px, py, pz, vx, vy, vz = self.rLayer:wndToWorld(x, y)
 end

-- Setup the main window
local rGameViewport, rUiViewport = Graphics.createWindow("ParticleEdit", 640, 480)
rGameViewport:setScale ( 640, 480 )

local rThread = MOAICoroutine.new()
rThread:run(function()
    ParticleEdit:init(rGameViewport)
    ParticleEdit:thread()
end)