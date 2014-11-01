local Class=require('Class')
local DFGraphics = require('DFCommon.Graphics')
local DFMath = require('DFCommon.Math')

local AnimatedSprite = {}

AnimatedSprite.tAllAnimSprites = {}
AnimatedSprite.nCurUniqueId = 1
function AnimatedSprite.tickAll(dt)
    for id,rSprite in pairs(AnimatedSprite.tAllAnimSprites) do
        rSprite:onTick(dt)
    end
end

-- tParams:
--  tSizeRange: default {1,1}
--  nFPS: default 30
--  sAlignH,sAlignV: default 'center'
--  bHoldLastFrame: doesn't kill itself off at end of anim; you need to call die.
function AnimatedSprite.new(rRenderLayer, rSpritesheet, sPrefix, tParams)
    local obj = MOAIProp.new()
    tParams = tParams or {}
    
    local tSizeRange = tParams.tSizeRange
    local nFPS = tParams.nFPS
    local sAlignH, sAlignV = (tParams.sAlignH or 'center'),(tParams.sAlignV or 'center')

    if not rSpritesheet or type(rSpritesheet) == 'string' then
        rSpritesheet = rSpritesheet or "SpriteAnims/Effects"
        rSpritesheet = DFGraphics.loadSpriteSheet( rSpritesheet )
        for sSprite, _ in pairs( rSpritesheet.names ) do
            DFGraphics.alignSprite(rSpritesheet, sSprite, sAlignH, sAlignV, 1, 1)
        end
    end
    
    function obj:setLoopCount(nLoopCount)
        if nil == nLoopCount then nLoopCount = -1 end
        
        self.nLoopCount = nLoopCount
    end
    
    function obj:setFps(fps)
        self.fps = fps
        self.fOneOverFps = 1.0 / fps
    end
    
    function obj:autoSetSpritesFromPrefix(sAnimPrefix)
        local tFrames = {}
    
        for sId in pairs(self.rSpritesheet.names) do
            -- if this string matches our prefix, add it to the list (we'll sort later)
            if string.sub(sId, 1, string.len(sAnimPrefix)) == sAnimPrefix then
                table.insert(tFrames, sId)
            end
        end
        
        table.sort(tFrames)
        
        self:setAnimFrames(tFrames)
    end
    
    function obj:setAnimFrames(tAnimFrames)
        self.tAnimFrames = tAnimFrames
        
        self:restart()
    end
    
    function obj:restart()
        self.fElapsedSinceLastFrame = 0.0
        self.nFrame = 1
    end
    
    function obj:play(bReset, nLoopCount)
        if bReset then self.nFrame = 1 end
        if nLoopCount then self:setLoopCount(nLoopCount) end
        
        self:setFrame(self.nFrame)
        
        self.bIsPlaying = true
    end
    
    function obj:stop()
        self.bIsPlaying = false
    end
    
    function obj:die()
        -- when we die, remove ourself from our layer
        self.bIsPlaying = false
        self.rRenderLayer:removeProp(self)
        
        AnimatedSprite[self.id] = nil
    end
    
    function obj:onTick(dt)
        if self.bIsPlaying then
            self.fElapsedSinceLastFrame = self.fElapsedSinceLastFrame + dt
            
            while self.fElapsedSinceLastFrame > self.fOneOverFps do
                self.fElapsedSinceLastFrame = self.fElapsedSinceLastFrame - self.fOneOverFps
                
                self:nextFrame()
            end
        end
    end
    
    function obj:setFrame(nFrameIdx)
        local spriteId = self.tAnimFrames[nFrameIdx]
        self:setIndex(self.rSpritesheet.names[spriteId])
        self.nFrame = nFrameIdx
    end
    
    function obj:setLayer(rLayer)
        if rLayer == self.rRenderLayer then return end
        if self.rRenderLayer then
            self.rRenderLayer:removeProp(self)
        end
        if rLayer then
            rLayer:insertProp(self)
        end
        self.rRenderLayer = rLayer
    end
    
    function obj:nextFrame()          
        local nextFrame = self.nFrame + 1
        if nextFrame > #self.tAnimFrames then
            if self.bHoldLastFrame then return end

            if self.nLoopCount > 0 then
                self.nLoopCount = self.nLoopCount - 1
            end

            if self.nLoopCount == 0 then
                self:die()
            end
            
            nextFrame = 1
        end
        self:setFrame(nextFrame)
    end
    
    obj.tAnimFrames = {}
    obj.nLoopCount = -1 -- -1 means loop
    obj.nFrame = 1
    obj.bIsPlaying = false
    obj.bHoldLastFrame = tParams.bHoldLastFrame
    obj.rRenderLayer = rRenderLayer
    obj.fElapsedSinceLastFrame = 0.0
    obj.id = AnimatedSprite.nCurUniqueId .. "_anim" -- we use a string so we can gurantee fast hash lookups on death
    obj.rSpritesheet = rSpritesheet
    
    obj:setDeck(rSpritesheet)
    obj:setFps(nFPS or 30)
    rRenderLayer:insertProp(obj)
    
    AnimatedSprite.nCurUniqueId = AnimatedSprite.nCurUniqueId + 1
    AnimatedSprite.tAllAnimSprites[obj.id] = obj
    
    if sPrefix then obj:autoSetSpritesFromPrefix(sPrefix) end
    
    if tSizeRange then
        local propScale = DFMath.randomFloat(tSizeRange[1],tSizeRange[2])
        if math.random() > 0.5 then 
            obj:setScl(-propScale, propScale)
        else
            obj:setScl(propScale, propScale)
        end
    end
    
    return obj
end

function AnimatedSprite.test()
    local spritesheetId = "SpriteAnims/Effects"
    local spriteAnimPrefix = "muzzleflash_0"
    local layerId = "WorldWall"
    
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
    
    local DFInput = require('DFCommon.Input')
    local x,y = DFInput.m_x, DFInput.m_y
    local worldLayer = g_World.getWorldRenderLayer()
    local wx, wy = worldLayer:wndToWorld(x, y)
    
    rSprite:setFps(20)
    rSprite:setLoc(wx,wy,0)
    rSprite:play(true, 0)
end

return AnimatedSprite
