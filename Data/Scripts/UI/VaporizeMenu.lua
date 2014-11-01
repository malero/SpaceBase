local Gui = require('UI.Gui')
local DFUtil = require("DFCommon.Util")
local UIElement = require('UI.UIElement')
local Renderer = require('Renderer')

local m = {}

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())
    
    function Ob:init(w)
        Ob.Parent.init(self)

        self.width = w
        self.height = 70
        self.hintBox = self:addRect(self.width, self.height, unpack({221/255,74/255,106/255}))
        --vaporize instructions
        self.hintText = self:addTextToTexture(g_LM.line("BUILDM008TEXT"), self.hintBox, "nevisBody")
    end

    function Ob:inside(wx,wy)
        return self.hintBox:inside(wx,wy)
    end

    function Ob:refresh()
    end

    return Ob
end

function m.new(...)
    local Ob = m.create()
    Ob:init(...)

    return Ob
end

return m
