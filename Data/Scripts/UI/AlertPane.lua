local m = {}

local DFUtil = require("DFCommon.Util")
local UIElement = require('UI.UIElement')
--local ScrollableUI = require('UI.ScrollableUI')
local AlertEntry = require('UI.AlertEntry')
local HintPane = require('UI.HintPane')
local GameRules = require('GameRules')
local Base = require('Base')
local DFInput = require('DFCommon.Input')

local sUILayoutFileName = 'UILayouts/AlertPaneLayout'

function m.create()
    local Ob = DFUtil.createSubclass(HintPane.create())
    Ob.tEntries = {}
    Ob.rEntryClass = require('UI.AlertEntry')
    Ob.nNumEntries = 0

    function Ob:init()
        Ob.Parent.init(self)
        self.bZebraColor = true
		self.tAltColor = require('UI.Gui').ALERTLOG_BG_ALT
    end
    
    function Ob:_getAlertsToDisplay()
        return Base.getCurrentEvents() or {}
    end

    function Ob:onFinger(touch, x, y, props)
        local bHandled = false
        if self.bMaximize then
            for i, rAlertEntry in ipairs(self.tEntries) do
                if rAlertEntry:isActive() then
                    if rAlertEntry:onFinger(touch, x, y, props) then
                        bHandled = true                    
                    end
                end
            end
        end
        self.rButton:onFinger(touch,x,y,props)
        return bHandled
    end

    function Ob:setMaximized(bMaximize, bForce)
        Ob.Parent.setMaximized(self,bMaximize,bForce)
        g_GuiManager.statusBar:onAlertsExpanded(self.bMaximize)
    end

    return Ob
end

function m.new(...)
    local Ob = m.create()
    Ob:init(...)

    return Ob
end

return m
