local m = {}

local DFUtil = require("DFCommon.Util")
local UIElement = require('UI.UIElement')
local DFInput = require('DFCommon.Input')
local CitizenInspector = require('UI.CitizenInspector')
local ObjectInspector = require('UI.ObjectInspector')
local ZoneInspector = require('UI.ZoneInspector')
local ObjectList = require('ObjectList')
local SoundManager = require('SoundManager')

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())
    Ob.rSelectedButton = nil

    function Ob:init()
    end

    function Ob:onTick(dt)
    end

    function Ob:onFinger(eventType, x, y, props)
    end

    function Ob:inside(wx, wy)
        return Ob.Parent.inside(self, wx, wy)
    end

    function Ob:onBackButtonPressed(rButton, eventType)
        if eventType == DFInput.TOUCH_UP then
            if g_GuiManager.newSideBar then
                g_GuiManager.newSideBar:closeSubmenu()
                --g_GuiManager.clearSelectionProp()
                g_GuiManager.setSelected(nil)
                SoundManager.playSfx('degauss')
            end
        end
    end   

    function Ob:show(basePri)
        local nPri = Ob.Parent.show(self, basePri)
        g_GameRules.setUIMode(g_GameRules.MODE_BEACON)
        return nPri
    end

    function Ob:hide()
        Ob.Parent.hide(self)
        g_GameRules.setUIMode(g_GameRules.MODE_INSPECT)
    end

    return Ob
end

function m.new(...)
    local Ob = m.create()
    Ob:init(...)

    return Ob
end

return m
    

