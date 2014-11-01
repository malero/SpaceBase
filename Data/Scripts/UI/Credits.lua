local m = {}

local DFUtil = require("DFCommon.Util")
local UIElement = require('UI.UIElement')
local DFInput = require('DFCommon.Input')
local Renderer = require('Renderer')
local Gui = require('UI.Gui')
local GameRules = require('GameRules')

local sUILayoutFileName = 'UILayouts/CreditsLayout'

local SCROLL_DELAY = 5
local SCROLL_AMOUNT = -15000
local SCROLL_START_Y = -900
--local SCROLL_TIME = 50
local SCROLL_TIME = -SCROLL_AMOUNT / 120

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())

    function Ob:init()
        Ob.Parent.init(self)
        
        self:setRenderLayer("UIOverlay")

        self:processUIInfo(sUILayoutFileName)
        
        --self.defaultX,self.defaultY = self:getLoc()
        
        self.uiBG = self:getTemplateElement('Background')
        self.uiBG:setScl( Renderer.getViewport().sizeX * 2, Renderer.getViewport().sizeY * 2 )
        self.uiBG:setLoc(-Renderer.getViewport().sizeX *.5, Renderer.getViewport().sizeY *.5 )
        
        self.rLogo = self:getTemplateElement('Logo')
        
        self.scrollTransform = MOAITransform.new()
        self.scrollTransform:setParent(self)
        
        for k,v in pairs(self.tTemplateElements) do
            if v ~= self.uiBG and v ~= self.rLogo then
                -- add parent
                v:setParent(self.scrollTransform)
            end
        end
    end
    
    function Ob:show(basePri)
        Ob.Parent.show(self, basePri)
        self.scrollTransform:setLoc(0, SCROLL_START_Y)
        self:moveProp(self.scrollTransform, 0, SCROLL_START_Y-SCROLL_AMOUNT, SCROLL_TIME)
        GameRules.timePause()
        self.bGotUpClick = false
        self:refresh()
        self:onResize()
    end
    
    function Ob:resume()
        self:hide()
        g_GuiManager.showStartMenu()       
    end

    function Ob:onTick(dt)
        Ob.Parent.onTick(self, dt)
    end

    function Ob:refresh()
    end

    function Ob:playWarbleEffect(bFullscreen)
        if bFullscreen then
            local uiX,uiY,uiW,uiH = Renderer.getUIViewportRect()            
            g_GuiManager.createEffectMaskBox(0, 0, uiW, uiH, 0.3)
        else
            g_GuiManager.createEffectMaskBox(0, 0, 500, 1444, 0.3, 0.3)
        end
    end    


    function Ob:onFinger(touch, x, y, props)
        Ob.Parent.onFinger(self, touch, x, y, props)
        if touch.eventType == DFInput.TOUCH_UP then
            if self.bGotUpClick then self:resume() else self.bGotUpClick = true end
        end
    end

    function Ob:onKeyboard(key, bDown)
        -- capture all keyboard input
        if bDown and key == 27 then -- esc
            g_GuiManager.startMenu:resume(false)
        end
        return true
    end

    function Ob:inside(wx, wy)
        return Ob.Parent.inside(self, wx, wy)
    end

    function Ob:onFileChange(path)
        Ob.Parent.onFileChange(self, path)
        
        self.scrollTransform:setLoc(0, SCROLL_START_Y)
        self:moveProp(self.scrollTransform, 0, SCROLL_START_Y-SCROLL_AMOUNT, SCROLL_TIME)
        
        self.uiBG:setScl( Renderer.getViewport().sizeX * 2, Renderer.getViewport().sizeY * 2 )
        self.uiBG:setLoc( -Renderer.getViewport().sizeX * .5, Renderer.getViewport().sizeY * .5 )
    end
    
    function Ob:onResize()
        Ob.Parent.onResize(self)
        self.uiBG:setScl(Renderer.getViewport().sizeX*2,Renderer.getViewport().sizeY*2)
        self.uiBG:setLoc(-Renderer.getViewport().sizeX*.5,Renderer.getViewport().sizeY*.5)
        self:refresh()
    end
   
    return Ob
end

function m.new(...)
    local Ob = m.create()
    Ob:init(...)

    return Ob
end

return m