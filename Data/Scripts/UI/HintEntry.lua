local m = {}

local DFUtil = require("DFCommon.Util")
local UIElement = require('UI.UIElement')

local sUILayoutFileName = 'UILayouts/HintEntryLayout'

local kYMARGIN = 16
local kDOTS_OFFSET = 4

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())
    Ob.rHint = nil

    function Ob:init(rHintPane)
        self.rHintPane = rHintPane

        self:processUIInfo(sUILayoutFileName)
        Ob.Parent.init(self)

        self.rButton = self:getTemplateElement('Button')
        self.rHintText = self:getTemplateElement('HintText')
        self.tDotElements = {}

        local i = 1
        while true do
            local rDotElement = self:getTemplateElement('DividerDot'..i)
            if rDotElement then
                table.insert(self.tDotElements, rDotElement)
                self.nOrigDotPosX, self.nOrigDotPosY = rDotElement:getLoc()
                i = i + 1
            else
                break
            end
        end

        self.nOrigButtonScaleX, self.nOrigButtonScaleY = self.rButton:getScl()
        self:_calcDimsFromElements()
    end

    function Ob:setAlert(rHint)
        if self.rHint == rHint then return end
        self.rHint = rHint
        if rHint and rHint.lineCode then
			local sString = g_LM.line(rHint.lineCode)
			-- do any replacements
			if rHint.tReplacements then
				for k,v in pairs(rHint.tReplacements) do
					sString = sString:gsub('/'..k..'/', v)
				end
			end
            self.rHintText:setString(sString)
            if self.rHintPane:isMaximized() then
                if not self.elementsVisible then
                    self:show()
                end
            end
            self:resize()
        else
            self:hide(true)
        end
    end

    function Ob:setAsLastAlert(bSet)
        if bSet then
            self:setDotsVisible(false)
        else
            --self:setDotsVisible(true)
        end
    end

    function Ob:setDotsVisible(bVisible)
        if self.bDotsVisible ~= bVisible then
            for i, rDotElement in ipairs(self.tDotElements) do
                rDotElement:setVisible(bVisible)
            end
            self.bDotsVisible = bVisible
        end
    end
    
    function Ob:getDims()
        return self.rButton:getDims()
    end

    function Ob:resize()
        if self.rHint and self.rHint.lineCode then
            local x0, y0, x1, y1 = self.rHintText:getStringBounds(1, string.len(g_LM.line(self.rHint.lineCode)))
            local nYSize = math.abs(y1 - y0)   
            local nYScale = kYMARGIN * 2
            nYScale = nYScale + nYSize
            self.rButton:setScl(self.nOrigButtonScaleX, nYScale)
            -- offset the dots
            local nButtonX, nButtonY = self.rButton:getLoc()
            for i, rDotElement in ipairs(self.tDotElements) do
                local x, y = rDotElement:getLoc()
                rDotElement:setLoc(x, nButtonY - nYScale + kDOTS_OFFSET)
            end
        end
    end

    function Ob:isActive()
        if self.rHint then
            return true
        else
            return false
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