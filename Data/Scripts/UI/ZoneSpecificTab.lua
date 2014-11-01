local m = {}

local DFUtil = require("DFCommon.Util")
local DFInput = require('DFCommon.Input')
local ScrollableUI = require('UI.ScrollableUI')
local ZoneResearchPane = require('UI.ZoneResearchPane')
local UIElement = require('UI.UIElement')

local sUILayoutFileName = 'UILayouts/ZoneSpecificTabLayout'

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())
    Ob.rZone = nil
    Ob.tButtons = {}
    Ob.bDoRolloverCheck = true

    function Ob:init()
        Ob.Parent.init(self)
        self.rZoneResearchPane = ZoneResearchPane.new()
        self.rActivePane = nil
    end
    
    function Ob:onTick(dt)
        if self.rActivePane and self.rActivePane.onTick then
            self.rActivePane:onTick(dt)
        end
    end
    
    function Ob:inside(wx,wy)
        Ob.Parent.inside(self,wx,wy)
    end
    
    function Ob:onFinger(touch, x, y, props)
        Ob.Parent.onFinger(self,touch, x, y, props)
    end
	
    function Ob:setRoom(rRoom)
        self.rRoom = rRoom

        local rActive = nil
        if self.rRoom and self.rRoom.zoneObj.sZoneInspector then
            if self.rRoom.zoneObj.sZoneInspector == 'ZoneResearchPane' then
                rActive = self.rZoneResearchPane
            end
        end
        if rActive ~= self.rActivePane then
            if self.rActivePane then self:removeElement(self.rActivePane) end
            self.rActivePane = rActive
            self:addElement(self.rActivePane)
        end
        if self.rActivePane then
            self.rActivePane:setRoom(rRoom)
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

