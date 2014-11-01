local m = {}

local DFUtil = require("DFCommon.Util")
local UIElement = require('UI.UIElement')
local DFInput = require('DFCommon.Input')
local SoundManager = require('SoundManager')

local sUILayoutFileName = 'UILayouts/CitizenInspectorLayout'

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())
    Ob.tTabInfos = {}
    Ob.nCurIndex = 1

    function Ob:init()
        Ob.Parent.init(self)
    end

    function Ob:onTick(dt)
        for i, tTabInfo in ipairs(self.tTabInfos) do            
            if tTabInfo.rUI then
                local nCurX, nCurY = tTabInfo.rUI:getLoc()
                if nCurX ~= tTabInfo.nDesiredX or nCurY ~= tTabInfo.nDesiredY then
                    -- do lerp here
                    -- snapping for now
                    tTabInfo.rUI:setLoc(tTabInfo.nDesiredX, tTabInfo.nDesiredY)
                end
                if tTabInfo.rUI.onTick then
                    tTabInfo.rUI:onTick(dt)
                end
            end
        end
    end

    -- we currently make the assumption that this UI isn't visible when tabs are added
    function Ob:addTab(rTabUI, sTabKey)
            local tInfo = {}
            tInfo.rUI = rTabUI
            tInfo.sTabKey = sTabKey
            tInfo.nInitX = 0
            tInfo.nInitY = 0
            tInfo.nFinalX = 0
            tInfo.nFinalY = 0
            tInfo.nDesiredX = tInfo.nInitX
            tInfo.nDesiredY = tInfo.nInitY
            self:addElement(rTabUI)
            rTabUI:setLoc(tInfo.nInitX, tInfo.nInitY)
            rTabUI:setAccordionUI(self)
            table.insert(self.tTabInfos, tInfo)
    end

    --[[
    function Ob:removeTab(sTabKey)
        for i,v in ipairs(self.tTabInfos) do
            if v.sTabKey == sTabKey then
                table.remove(self.tTabInfos,i)
            end
        end
    end
    ]]--

    function Ob:setTabInfo(sTabKey, tTabInfo)
        if sTabKey and tTabInfo then
            local tInfoToModify = nil
            for k, tExistingInfo in ipairs(self.tTabInfos) do
                if tExistingInfo.sTabKey == sTabKey then
                    tInfoToModify = tExistingInfo
                    break
                end
            end
            if tInfoToModify then
                if tTabInfo.nInitX then
                    tInfoToModify.nInitX = tTabInfo.nInitX
                end
                if tTabInfo.nInitY then
                    tInfoToModify.nInitY = tTabInfo.nInitY
                end
                if tTabInfo.nFinalX then
                    tInfoToModify.nFinalX = tTabInfo.nFinalX
                end
                if tTabInfo.nFinalY then
                    tInfoToModify.nFinalY = tTabInfo.nFinalY
                end
            end            
        end 
    end

    function Ob:setTabSelected(nIndex)
        -- flag the tab's final pos
        for i, tTabInfo in ipairs(self.tTabInfos) do            
            if i <= nIndex then
                tTabInfo.nDesiredX = self:_convertLayoutVal(tTabInfo.nInitX)
                tTabInfo.nDesiredY = self:_convertLayoutVal(tTabInfo.nInitY)
            else
                tTabInfo.nDesiredX = self:_convertLayoutVal(tTabInfo.nFinalX)
                tTabInfo.nDesiredY = self:_convertLayoutVal(tTabInfo.nFinalY)
            end
            if i == nIndex then
                tTabInfo.rUI:setSelected(true)
            else
                tTabInfo.rUI:setSelected(false)
            end
        end
        self.nCurIndex = nIndex
    end

    function Ob:selectTab(rTabUI)
        if rTabUI then
            for i, tTabInfo in ipairs(self.tTabInfos) do
                if tTabInfo.rUI == rTabUI then
                    self:setTabSelected(i)
                    SoundManager.playSfx('inspectortab')
                    break
                end
            end
        end
    end

    function Ob:getSelectedTabIndex()
        return self.nCurIndex
    end

    function Ob:show(nPri)
        local r = Ob.Parent.show(self, nPri)
        self:setTabSelected(self.nCurIndex)
        return r
    end

    function Ob:onFinger(touch, x, y, props)
        local bTouched = false
        for i, tTabInfo in ipairs(self.tTabInfos) do            
            -- MTF CRITICAL BUG: processes all UI on all tabs, even deselected ones.
            if tTabInfo.rUI:onFinger(touch, x, y, props) then
                bTouched = true
            end
        end
        return bTouched
    end

    function Ob:inside(wx, wy)
        for i, tTabInfo in ipairs(self.tTabInfos) do            
            tTabInfo.rUI:inside(wx, wy)
        end
    end

    function Ob:onResize()
        Ob.Parent.onResize(self)
        for i, tTabInfo in ipairs(self.tTabInfos) do            
            tTabInfo.rUI:onResize()
        end
        self:setTabSelected(self.nCurIndex)
    end

    return Ob
end

function m.new(...)
    local Ob = m.create()
    Ob:init(...)

    return Ob
end

return m
