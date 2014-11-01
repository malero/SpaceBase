local UIElement = require('UI.UIElement')
local DFUtil = require("DFCommon.Util")
local DFInput = require('DFCommon.Input')

local m = {}

local PRESSED_SCALE_PCT = 0.7

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())

    Ob.bHover = false
    Ob.bActive = false
    Ob.bSelected = false
    Ob.bEnabled = true
    Ob.tHoverCallbackInfos = {}
    Ob.tPressedCallbackInfos = {}

    function Ob:init()
        Ob.Parent.init(self)
    end
    
    function Ob:refresh()
        self:_updateVisuals(true)
    end

    function Ob:setVisualsFromString(sStatus)
        self.bEnabled=true
        self.bSelected=false

        if sStatus == 'disabled' then
            self.bEnabled = false
        elseif sStatus == 'selected' then
            self.bSelected = true
        end
        self:_updateVisuals()
    end

    function Ob:_updateVisuals(bForce)
        self.sVisualState = 'normal'
        if self.bSelected then 
            self.sVisualState = 'selected'
        elseif self.bEnabled == false then 
            self.sVisualState = 'disabled'
        elseif self.bActive then 
            self.sVisualState = 'active'
        elseif self.bHover then
            self.sVisualState = 'hover'
        end
    end

    function Ob:inside(wx,wy)
        local bInside = self:_inBounds(wx,wy)

        if bInside ~= self.bHover then
            self:onHover(bInside)
        end

        return bInside
    end

    function Ob:setEnabled(bEnabled)
        self.bEnabled = bEnabled
        self:_updateVisuals()
    end
    
    function Ob:setGenerateBothEvents(bBoth)
        self.bGenerateBothEvents = bBoth
    end

    function Ob:onHover(bInside)
        self.bHover = bInside
        
        if not bInside then self.bActive = false end

        if self.bEnabled and (self.sBehavior == 'toggle' or (not self.bSelected and not self.bActive)) then
            self:callHoverCallback(bInside)
        end

        self:_updateVisuals()
    end

    function Ob:callHoverCallback(bHovered)
        self:_callback(self.tHoverCallbackInfos,bHovered)
    end

    function Ob:_callback(t,arg)
        for i, rInfo in ipairs(t) do
            if rInfo.rEnt then
                rInfo.callback(rInfo.rEnt, self, arg)
            else
                rInfo.callback(self, arg)
            end
        end
    end

    function Ob:callPressedCallback(eventType)
        -- make callback
        self:_callback(self.tPressedCallbackInfos,eventType)
    end

    function Ob:keyboardPressed()
        if self.bGenerateBothEvents then
            self:callPressedCallback(DFInput.TOUCH_DOWN, true)
        end
        self:callPressedCallback(DFInput.TOUCH_UP, true)
    end
    
    function Ob:show(nBasePri)
        local nPri = Ob.Parent.show(self, nBasePri)
        
        self.bHover = false
        self.bActive = false
        
        self:_updateVisuals()
        return nPri
    end    

    function Ob:onFinger(touch, wx, wy, props)
        if not self.bEnabled then return false end
        if touch.button ~= DFInput.MOUSE_LEFT then
            return false
        end
        if touch.eventType ~= DFInput.TOUCH_UP and touch.eventType ~= DFInput.TOUCH_DOWN then
            return false
        end
        if not self:_inBounds(wx,wy) then
            return false
        end

        if touch.eventType == DFInput.TOUCH_UP then
            --if self.bActive or self.sBehavior == 'toggle' then
                self:callPressedCallback(touch.eventType)
            --end
            self.bActive = false
        elseif touch.eventType == DFInput.TOUCH_DOWN then
            if self.bGenerateBothEvents then
                self:callPressedCallback(touch.eventType)
            end
            self.bActive = true
        end
        self:_updateVisuals()
        return true
    end

    function Ob:setSelected(bSelected)
        self.bSelected = bSelected
        self:_updateVisuals()
    end

    function Ob:addHoverCallback(callback, rEnt)
        self:_addCallback(callback,rEnt,self.tHoverCallbackInfos)
    end

    function Ob:addPressedCallback(callback, rEnt)
        self:_addCallback(callback,rEnt,self.tPressedCallbackInfos)
    end

    function Ob:_addCallback(callback,rEnt,t)
        local rInfo = {}
        rInfo.callback = callback
        rInfo.rEnt = rEnt
        table.insert(t, rInfo)
    end

    return Ob
end

function m.new(...)
    local Ob = m.create()
    Ob:init(...)

    return Ob
end

return m
