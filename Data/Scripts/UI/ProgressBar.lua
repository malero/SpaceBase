local UIElement = require('UI.UIElement')
local DFUtil = require("DFCommon.Util")
local DFInput = require('DFCommon.Input')

local m = {}

local sDefaultLayoutFileName = 'UILayouts/ProgressBarLayout'

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())

    function Ob:init(sRenderLayerName,sLayoutFileName)
        Ob.Parent.init(self,sRenderLayerName,sLayoutFileName or sDefaultLayoutFileName)

        self.rBG = self:getTemplateElement('Background')
        self.rFG = self:getTemplateElement('Foreground')
        self.nFraction = 1
    end

    function Ob:refresh()
        self.rBG:setScl(self.uiWidth,self.uiHeight)
        self.rFG:setScl(self.uiWidth*self.nFraction,self.uiHeight)
    end

    function Ob:setProgress(nFraction)
        self.nFraction = nFraction
        self:refresh()
    end

    function Ob:setRect(x1,y1,x2,y2)
        self.tRect = {x1,y1,x2,y2}
        self.uiWidth,self.uiHeight = x2-x1, y1-y2
        self.rBG:setLoc(x1,y1)
        self.rFG:setLoc(x1,y1)
        self:refresh()
    end

    function Ob:show(nBasePri)
        local nPri = Ob.Parent.show(self, nBasePri)
        self.rBG:setPriority(nPri-1)
        self.rFG:setPriority(nPri)
        self:refresh()
        return nPri
    end    

    return Ob
end

function m.new(...)
    local Ob = m.create()
    Ob:init(...)

    return Ob
end

return m

