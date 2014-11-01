local m = {}

local DFUtil = require("DFCommon.Util")
local UIElement = require('UI.UIElement')
local DFInput = require('DFCommon.Input')

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())
    Ob.rAccordionUI = nil

    function Ob:setAccordionUI(rAccordionUI)
        self.rAccordionUI = rAccordionUI
    end

    function Ob:getAccordionUI()
        return self.rAccordionUI
    end

    function Ob:setSelected(bSelected)
        self.bSelected = bSelected
        local tCallbacks = self:getExtraTemplateInfo('tCallbacks')
        if tCallbacks then
            if bSelected then
                if tCallbacks.onSelected then
                    if self.rTabButton then
                        self.rTabButton:setSelected(true)
                    end
                    self:applyTemplateInfos(tCallbacks.onSelected)
                end
            else
                if tCallbacks.onDeselected then
                    if self.rTabButton then
                        self.rTabButton:setSelected(false)
                    end
                    self:applyTemplateInfos(tCallbacks.onDeselected)
                end
            end
        end
        if self.onSelected then
            self:onSelected(bSelected)
        end
    end

    function Ob:isSelected()
        return self.bSelected
    end

    return Ob
end

function m.new(...)
    local Ob = m.create()
    Ob:init(...)

    return Ob
end

return m