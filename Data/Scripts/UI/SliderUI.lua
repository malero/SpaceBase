local m = {}

local DFUtil = require("DFCommon.Util")
local DFMath = require("DFCommon.Math")
local UIElement = require('UI.UIElement')
local DFInput = require('DFCommon.Input')
local MiscUtil = require("MiscUtil")
local GameRules = require('GameRules')
local Renderer = require('Renderer')

local sUILayoutFileName = 'UILayouts/SliderUILayout'

-- currently just a stub until masking tech
function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())

    function Ob:init(sConfigKey)
        Ob.Parent.init(self)
        
        self:setRenderLayer("UIOverlay")
        
        self:processUIInfo(sUILayoutFileName)
        
        self.rBackground = self:getTemplateElement('Background')
        self.rThumb = self:getTemplateElement('Thumb')
        self.rForeground = self:getTemplateElement('Foreground')
        self.nMaxWidth,self.nHeight = self.rForeground:getDims()
        self.nHeight=-self.nHeight
        self.defaultX,self.defaultY = self.rForeground:getLoc()
        local scaleX, scaleY = self.rForeground:getScl()
        self.nMaxWidth = math.max(self.nMaxWidth, 0.1)
        self.nValue = 1
        if sConfigKey then
            self.sConfigKey = sConfigKey
            self:setValue(g_Config:getConfigValue(sConfigKey) or 1)
        end
    end

    function Ob:hide(bKeepAlive)
        Ob.Parent.hide(self,bKeepAlive)
    end

    function Ob:show(nMaxPri)
        self.bSliding = false
        self:setValue(self.nValue)
        return Ob.Parent.show(self, nMaxPri)
    end

    function Ob:onFinger(touch, x, y, props)
        Ob.Parent.onFinger(self, touch, x, y, props)
        local bgX,bgY = self.rBackground:getWorldLoc ()
        local bgX2 = bgX * 2
        local bInside = self.rBackground:inside(x,y)
        if bInside and touch.eventType == DFInput.TOUCH_DOWN then
            self.bSliding = true
            self:_updatePos()
        elseif touch.eventType == DFInput.TOUCH_UP then
            self.bSliding = false
        end
    end
    
    function Ob:_updatePos()
        local x,y = GameRules.cursorX, GameRules.cursorY
        local wx,wy = Renderer.getRenderLayer('UI'):wndToWorld(x, y)
        local bgX,bgY = self.rBackground:getWorldLoc()
        local nValue = (wx-bgX)/self.nMaxWidth
        self:setValue(nValue)
    end
    
    function Ob:setValue(nValue)
        nValue = DFMath.clamp((nValue or self.nValue), 0, 1)
        local newWidth = DFMath.lerp(0, self.nMaxWidth, nValue)
        self.rForeground:setScl(newWidth, self.nHeight)
        self.rThumb:setLoc(self.defaultX + newWidth, self.defaultY)
        self.nValue = nValue
        g_Config:setConfigValue(self.sConfigKey, nValue)
        if self.onChangeCallback then self.onChangeCallback(self.sConfigKey, nValue) end
    end
    
    function Ob:onFileChange(path)
        Ob.Parent.onFileChange(self, path)
        
        self:setValue(self.nValue)
    end
    
    function Ob:onResize()
        Ob.Parent.onResize(self)
        
        self:setValue(self.nValue)
    end
    
    function Ob:onTick(dt)
        Ob.Parent.onTick(self, dt)
        if self.bSliding then self:_updatePos() end
    end
    
    return Ob
end

function m.new(...)
    local Ob = m.create()
    Ob:init(...)

    return Ob
end

return m
