local DFGraphics = require("DFCommon.Graphics")

local UIEffectMask = {}
local UIEffectMaskBox = {}

local kSHOW_BOX_DEBUG = false

-- an individual mask box
function UIEffectMaskBox.new()
    local obj = {}
    
    function obj:init(rDeck,x,y,w,h,nTime,nIntensity)
        self.rProp = MOAIProp.new()
    
        -- the pixels we're going to blend outside of this box
        local padding = 64.0
        local halfPadding = padding * 0.5
        local halfW = w * 0.5
        local halfH = h * 0.5

        local boxW = w + padding
        local boxH = h + padding
        local boxX = x - halfPadding + boxW / 2
        local boxY = y - halfPadding + boxH / 2
    
        self.rProp:setDeck(rDeck)
        self.rProp:setIndex(rDeck.names['softwhitebox'])
        self.rProp:setLoc(boxX,-boxY)
		self.rProp:setScl(boxW/256.0, boxH/256.0)
        
        local Renderer = require("Renderer")
        
        if kSHOW_BOX_DEBUG then
            self.rLayer = Renderer.getRenderLayer("UI")
        else
            self.rLayer = Renderer.getRenderLayer("UIEffectMask")
        end
        
        self.rLayer:insertProp(self.rProp)

        self.nIntensity = nIntensity        
        self.nTimeRemaining = nTime
        self.nTotalTime = self.nTimeRemaining
    end
    
    function obj:onTick(dt)
        self.nTimeRemaining = self.nTimeRemaining - dt
        
        local pct = 0.0
        if self.nTimeRemaining > 0 then 
            pct = self.nTimeRemaining / self.nTotalTime
        end
        
        local value = self.nIntensity * pct
        
        self.rProp:setColor(value, value, value, 1.0)
    end
    
    function obj:onDestroy()
        self.rLayer:removeProp(self.rProp)
        self.rProp = nil
    end
    
    function obj:getTimeRemaining()
        return self.nTimeRemaining
    end
    
    return obj
end

-- the guy who manages all the masks
function UIEffectMask.new()
    local obj = {}
    
    obj.rSpritesheet = DFGraphics.loadSpriteSheet( 'UI/UIMisc' )
    for sSprite, _ in pairs( obj.rSpritesheet.names ) do
        DFGraphics.alignSprite(obj.rSpritesheet, sSprite, "center", "center", 1, 1)
    end
    
    function obj:addMask(x,y,w,h,nTime,nIntensity)
        local rMask = UIEffectMaskBox.new()
        rMask:init(self.rSpritesheet, x,y,w,h, nTime, nIntensity)
        table.insert(self.tMasks, rMask)
    end
    
    function obj:onTick(dt)
        for i=#self.tMasks,1,-1 do
            local rMask = self.tMasks[i]
            rMask:onTick(dt)
            if rMask:getTimeRemaining() <= 0.0 then
                -- remove this mask
                rMask:onDestroy()
                table.remove(self.tMasks, i)
            end
        end
    end
    
    obj.tMasks = {}
    
    return obj
end


return UIEffectMask