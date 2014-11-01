local m = {}

local DFUtil = require("DFCommon.Util")
local AccordionTab = require('UI.ZoneTab')
local DFInput = require('DFCommon.Input')
local ScrollableUI = require('UI.ScrollableUI')

local sUILayoutFileName = 'UILayouts/ZoneSpecificTabLayout'

function m.create()
    local Ob = DFUtil.createSubclass(AccordionTab.create())
    Ob.rZone = nil
    Ob.tButtons = {}

    function Ob:init()
        self:processUIInfo(sUILayoutFileName)
        Ob.Parent.init(self)

        self.rScrollableUI = ScrollableUI.new()
        self:addElement(self.rScrollableUI) -- to parent

        --self:setScrollListPos()
        --self:applyScrollBarOverride()
		--self.rScrollableUI:setScrollEnabled(true)
    end
	
    function Ob:applyScrollBarOverride()
        local scrollBarOverride = self:getExtraTemplateInfo('scrollBarOverride')
        if scrollBarOverride then
            self.rScrollableUI:applyTemplateInfos(scrollBarOverride)
        end
    end
	
    function Ob:setScrollListPos()
        local nCurY = 0
        local scrollListPosInfo = self:getExtraTemplateInfo('scrollListPosInfo')
        self.rScrollableUI:setPosInfo(scrollListPosInfo)
        for i, rButton in ipairs(self.tButtons) do
            local w,h = rButton:getDims()
            rButton:setLoc(0, nCurY)
            nCurY = nCurY + h
        end
        self.rScrollableUI:setScissorY(scrollListPosInfo.scissorLayerName, scrollListPosInfo.scissorY)
    end

    function Ob:onTick(dt)
        for i, rButton in ipairs(self.tButtons) do
            rButton:onTick(dt)
        end
    end

    function Ob:onSelected(bSelected)
        self.bSelected = bSelected
        if bSelected then
            self.rScrollableUI:show(self.maxPri)
            for i, rButton in ipairs(self.tButtons) do
                rButton:show(0) -- used for temp scrolling masking
            end
        else
            self.rScrollableUI:hide(true)
            for i, rButton in ipairs(self.tButtons) do
                rButton:hide(true)
            end
        end
    end

    function Ob:hide()
        Ob.Parent.hide(self)
        for i, rButton in ipairs(self.tButtons) do
            rButton:hide(true)
        end
    end

    function Ob:onFinger(touch, x, y, props)
        local bHandled = false
        if self.bSelected then
            self.rScrollableUI:onFinger(touch, x, y, props)
        end
        if Ob.Parent.onFinger(self, touch, x, y, props) then
            bHandled = true
        end
        if self.bSelected then
            for i, rButton in ipairs(self.tButtons) do
                bHandled = rButton:onFinger(touch, x, y, props)
            end
        end
        return bHandled
    end

    function Ob:inside(wx, wy)
        Ob.Parent.inside(self, wx, wy)
        self.rScrollableUI:inside(wx, wy)
        for i, rButton in ipairs(self.tButtons) do
            rButton:inside(wx, wy)
        end
    end

    function Ob:onFileChange(path)    
        Ob.Parent.onFileChange(self, path)
        self:setScrollListPos()
		self:applyScrollBarOverride()
    end

    return Ob
end

function m.new(...)
    local Ob = m.create()
    Ob:init(...)

    return Ob
end

return m

