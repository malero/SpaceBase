local Gui = require('UI.Gui')
local DFUtil = require("DFCommon.Util")
local DFInput = require('DFCommon.Input')
local DFMath = require("DFCommon.Math")
local UIElement = require('UI.UIElement')
local Renderer = require('Renderer')
local World = require('World')
local Zone = require('Zones.Zone')
local EnvObject = require('EnvObjects.EnvObject')
local ObjectList = require('ObjectList')

local m = {}

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())
    
	Ob.TICK_RATE = 0.5

    function Ob:init(w, color)
        Ob.Parent.init(self)

        self.buttonHash = {}
        self.width = w
        self.uiBG = self:addRect(w,1,unpack(color))
        
        local y = 0
        self.baseMargin = 10
        self.innerMargin = 20
        self.yMargin = 10
        self.barMargin = 4
        self.pbInnerWidth = self.width - 2 * self.innerMargin - 2 * self.barMargin
        self.pbHeight = 50
        self.pbInnerHeight = 50 - 2 * self.barMargin

        
        -- OBJECT label
        y = self:_addLabel(y, g_LM.line("ZONEUI014TEXT"))
        -- OBJECT name
        self.uiObjNameRect = self:addRect( self.width-2 * self.baseMargin, 70, 0, 0, 0 )
        self.uiObjNameRect:setLoc(self.baseMargin,y)
        self.uiObjName = self:addTextToTexture(g_LM.line("ZONEUI015TEXT"), self.uiObjNameRect, "inspectName")
        y = y-70
        
        -- CONDITION label
        self.uiCondition, y = self:_addProgressBar(g_LM.line("ZONEUI017TEXT"), y, true)
		-- set green vs yellow color based on actual tuning number
		local EnvObject = require('EnvObjects.EnvObject')
		self.nConditionThreshold = 50
		for _,v in pairs(EnvObject.tConditions) do
			if v.sSuffix == '_damaged' then
				self.nConditionThreshold = v.nBelow
				break
			end
		end		
		self.uiBG:setScl( self.width,math.abs(y) )
    end

    function Ob:updateSelected()
        self.selectedObject = g_GuiManager.getSelected(ObjectList.ENVOBJECT)
        
        if not self.selectedObject then return end
        
        self.uiObjName:setString(self.selectedObject.sFriendlyName)
        
		Ob:updateCondition()
    end
	
	function Ob:updateCondition()
		if not self.selectedObject then
			return
		end
		local condition = self.selectedObject.nCondition / 100
		self.uiCondition:setScl(DFMath.pinPct(condition)*self.pbInnerWidth,self.pbInnerHeight)
		local color = {96/255,160/255,110/255}
		if condition < self.nConditionThreshold / 100 then
			color = {234/255,203/255,78/255}
		end
		self.uiCondition:setColor(unpack(color))
	end

    function Ob:_addLabel(y,t,margin)
        local secondMargin = margin or self.baseMargin
        local label = self:addTextBox(t, "inspectLabel", 0,0,self.width,30,secondMargin,y-30) 
        return y - 30, label
    end
    
    function Ob:inside(wx,wy)
        return self.uiBG:inside(wx,wy)
    end
    
    function Ob:onFinger(eventType, x, y, props)
        if eventType == DFInput.TOUCH_UP then
            for _,v in ipairs(props) do
                local fn = self.buttonHash[v]
                if fn then
                    fn(self)
                    return true
                end
            end
        end
    end
    
    function Ob:_addProgressBar(label, y, bGreen)
        local color = (bGreen and {96/255,160/255,110/255}) or {234/255,203/255,78/255}
        y=self:_addLabel(y,label,self.innerMargin)
        local bg = self:addRect(self.width-2*self.innerMargin,self.pbHeight,0,0,0)
        bg:setLoc(self.innerMargin,y)
        local pb = self:addRect(self.pbInnerWidth,self.pbInnerHeight,unpack(color))
        pb:setLoc(self.innerMargin+self.barMargin,y-self.barMargin)
        y=y-self.pbHeight-self.yMargin
         
        return pb,y
    end
    
    function Ob:refresh()
        self:updateSelected()
    end
	
	function Ob:tick(dt)
		-- only tick if we're active
		if g_GuiManager.getSelected(ObjectList.ENVOBJECT) and g_GuiManager.rSelected == self.selectedObject then
			self:updateCondition()
		end
	end

    return Ob
end

function m.new(...)
    local Ob = m.create()
    Ob:init(...)

    return Ob
end

return m