local DebugManager = require('DebugManager')
local Renderer = require('Renderer')

local ParticleSystemManager = {
    profilerName='ParticleSystemManager',
}

ParticleSystemManager.tActiveParticleSystems = {}
ParticleSystemManager.lastTimePrint = 0

-- PUBLIC FUNCTIONS --
function ParticleSystemManager.register( rParticleSystem )
    table.insert(ParticleSystemManager.tActiveParticleSystems, rParticleSystem)
end

function ParticleSystemManager.init()    
end

function ParticleSystemManager.stopAll()

    local numActiveParticleSystems = #ParticleSystemManager.tActiveParticleSystems
    for i=1,numActiveParticleSystems do
        local rParticleSystem = ParticleSystemManager.tActiveParticleSystems[i]
        rParticleSystem:stop(true)
        rParticleSystem:unload()
    end
    
    ParticleSystemManager.update()
    ParticleSystemManager.update()
    
    DFEffects.stopAllParticleSystems()
end

function ParticleSystemManager.checkForLeaks()
    
    local numParticleSystemsAlive = DFEffects.debugPrintParticleSystems()
    if numParticleSystemsAlive > 0 then
        Trace(TT_Error, tostring(numParticleSystemsAlive) .. " particle systems leakd!")
    end
end

function ParticleSystemManager.onTick(dt)    

    -- Delete dead particle systems
    local numActiveParticleSystems = #ParticleSystemManager.tActiveParticleSystems
    for i=1,numActiveParticleSystems do
    
        local idx = numActiveParticleSystems - i + 1
        local rParticleSystem = ParticleSystemManager.tActiveParticleSystems[idx]
        
        if rParticleSystem.bStarted == true then
        
            local bUnregister = true
            if rParticleSystem.rParticleSystem ~= nil then
            
                bUnregister = false
                
                local bIsDead = rParticleSystem.rParticleSystem:isDead()            
                if bIsDead == true then
                
                    rParticleSystem:stop()
                
                    if rParticleSystem.rEntity ~= nil then
                        rParticleSystem:removeFromEntity()
                    elseif rParticleSystem.rSceneLayer ~= nil then
                        rParticleSystem:removeFromSceneLayer()
                    else
                        assert(0)
                    end
                    
                    rParticleSystem:unload()
                    rParticleSystem = nil
                    
                    bUnregister = true
                else
                    rParticleSystem:onTick(dt)
                end
            end
            
            if bUnregister == true then
                table.remove(ParticleSystemManager.tActiveParticleSystems, idx)
            end
            
        elseif rParticleSystem.bUnloaded == true then
        
            rParticleSystem:stop()
            
            table.remove(ParticleSystemManager.tActiveParticleSystems, idx)
        end
    end
    
    if ParticleSystemManager.debugDrawEnabled then
        -- Print some debug spam
        local curTime = MOAISim.getDeviceTime()
        local deltaTime = curTime - ParticleSystemManager.lastTimePrint
        if deltaTime > 2 then
        
            ParticleSystemManager.lastTimePrint = curTime
        
            numActiveParticleSystems = #ParticleSystemManager.tActiveParticleSystems
--            Trace("Active particles systems: " .. tostring(numActiveParticleSystems))
        end
    end
end

-- DEBUG --
function ParticleSystemManager._debugDraw()

    local numActiveParticleSystems = #ParticleSystemManager.tActiveParticleSystems
    for i=1,numActiveParticleSystems do
        local rParticleSystem = ParticleSystemManager.tActiveParticleSystems[i]
        rParticleSystem:_debugDraw()
    end	
end

function ParticleSystemManager.enableDebugDraw(bEnable)
	if ParticleSystemManager.debugDrawEnabled and not bEnable then
		ParticleSystemManager.debugDrawEnabled = false
        Renderer.dDebugRenderWorldSpace:unregister(ParticleSystemManager._debugDraw)
	elseif not ParticleSystemManager.debugDrawEnabled and bEnable then
		ParticleSystemManager.debugDrawEnabled = true
        Renderer.dDebugRenderWorldSpace:register(ParticleSystemManager._debugDraw)
	end
end

function ParticleSystemManager.toggleDebugDraw()
	if ParticleSystemManager.debugDrawEnabled == nil then
		ParticleSystemManager.debugDrawEnabled = false
	end
	ParticleSystemManager.enableDebugDraw(not ParticleSystemManager.debugDrawEnabled)
end

function ParticleSystemManager._debugList()
            
    local xCursor = 50
    local yCursor = 100
    local yOffset = 15
    
    local rFont = Renderer.getGlobalFont("debug")
    MOAIGfxDevice.setPenColor( 1, 1, 1, 1 )
    
    local numActiveParticleSystems = #ParticleSystemManager.tActiveParticleSystems
    if numActiveParticleSystems <= 0 then
        MOAIDraw.drawText(rFont, 30, "No active particle systems", xCursor, yCursor, 1, 2, 2)
        return
    else
        MOAIDraw.drawText(rFont, 30, tostring(numActiveParticleSystems) .. " active particle systems:", xCursor, yCursor, 1, 2, 2)
    end
    xCursor = xCursor + 20
    yCursor = yCursor + yOffset

    local tNamedParticleSystems = {}
    for i=1,numActiveParticleSystems do
        local rParticleSystem = ParticleSystemManager.tActiveParticleSystems[i]
        if rParticleSystem then
        
            if not tNamedParticleSystems[rParticleSystem.sResource] then
                tNamedParticleSystems[rParticleSystem.sResource] = 0
            end
            
            tNamedParticleSystems[rParticleSystem.sResource] = tNamedParticleSystems[rParticleSystem.sResource] + 1
        end
    end
    
    for sParticleResourceName, count in pairs(tNamedParticleSystems) do
            
        local cx = math.floor( xCursor )
        local cy = math.floor( yCursor )
    
        local text = sParticleResourceName .. " (" .. tostring(count) .. ")"
        MOAIDraw.drawText(rFont, 30, text, cx, cy, 1, 1, 1)
        yCursor = yCursor + yOffset
    end
end

function ParticleSystemManager.enableDebugList(bEnable)
	if ParticleSystemManager.debugListEnabled and not bEnable then
		ParticleSystemManager.debugListEnabled = false
        Renderer.dDebugRenderWorldSpace:unregister(ParticleSystemManager._debugList)
	elseif not ParticleSystemManager.debugListEnabled and bEnable then
		ParticleSystemManager.debugListEnabled = true
        Renderer.dDebugRenderWorldSpace:register(ParticleSystemManager._debugList)
	end
end

function ParticleSystemManager.toggleDebugList()
	if ParticleSystemManager.debugListEnabled == nil then
		ParticleSystemManager.debugListEnabled = false
	end
	ParticleSystemManager.enableDebugList(not ParticleSystemManager.debugListEnabled)
end

function ParticleSystemManager.toggleDisable()
    if ParticleSystemManager.bDisabled == nil then
        ParticleSystemManager.bDisabled = false
    end
    ParticleSystemManager.bDisabled = not ParticleSystemManager.bDisabled
    DFEffects.debugDisableParticles( ParticleSystemManager.bDisabled )
end

DebugManager:addDebugOption( "Disable Particles", { "Graphics" }, "p",  ParticleSystemManager.toggleDisable )
DebugManager:addDebugOption( "Particle Debug Draw", { "Graphics" }, "x",  ParticleSystemManager.toggleDebugDraw )
DebugManager:addDebugOption( "List particle systems", { "Graphics" }, "z",  ParticleSystemManager.toggleDebugList )

return ParticleSystemManager
