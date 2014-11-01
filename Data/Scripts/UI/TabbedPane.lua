local m = {}

local DFUtil = require("DFCommon.Util")
local UIElement = require('UI.UIElement')
local DFInput = require('DFCommon.Input')
local ScrollableUI = require('UI.ScrollableUI')
local SoundManager = require('SoundManager')

--local sUILayoutFileName = 'UILayouts/CitizenInspectorLayout'
--local sTabButtonLayout = 'UILayouts/IconTabLayout'

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())
    Ob.tTabInfos = {}
    Ob.nCurIndex = 3
    Ob.nNextTabOffset = 0
    Ob.bDoRolloverCheck = true

    function Ob:onTick(dt)
        if self.tTabInfos[self.nCurIndex] and self.tTabInfos[self.nCurIndex].rUI and self.tTabInfos[self.nCurIndex].rUI.onTick then
            self.tTabInfos[self.nCurIndex].rUI:onTick(dt)
        end
    end
    
    function Ob:setRect(x1,y1,x2,y2)
        self.tTemplateRect={x1,y1,x2,y2}
    end
    
    function Ob:hasTab(sTabKey)
        for i,v in ipairs(self.tTabInfos) do
            if v.sTabKey == sTabKey then
                return true
            end
        end
        return false
    end

    function Ob:addTab(rTabUI, sTabKey, bAddScrollable, rTabButton)
        if not rTabButton then
            rTabButton = UIElement.new()
        end
        if not rTabButton.tPosInfo then rTabButton.tPosInfo = {} end
        rTabButton.tPosInfo.offsetX = self.nNextTabOffset
        local w,h = rTabButton:getDims()
        self.nNextTabOffset = self.nNextTabOffset + w
        
        self:addElement(rTabButton)

        local tInfo = {}
        if bAddScrollable then
            tInfo.rUI = ScrollableUI.new()
            tInfo.rUI:addScrollingItem(rTabUI)
            local w,h = self:getScl()
            if self.tTemplateRect then
                tInfo.rUI:setRect(self.tTemplateRect[1],self.tTemplateRect[2],self.tTemplateRect[3],self.tTemplateRect[4])
            end
            --tInfo.rUI:setRect(0,0,w,h)
        else
            tInfo.rUI = rTabUI
        end
        self:addElement(tInfo.rUI, true)
        tInfo.sTabKey = sTabKey
        tInfo.bHidden = false
        tInfo.rTabButton = rTabButton
		-- FYI: the second number below defines Y0 for all tab content
        tInfo.rUI:setLoc(0,-42)
        table.insert(self.tTabInfos, tInfo)
        tInfo.rTabButton:alignToPosInfo()
        tInfo.rUI:alignToPosInfo()
        tInfo.rTabButton:addPressedCallback(function() self:selectTab(tInfo.rUI) end)
        return tInfo
    end

    function Ob:_layoutVisibleTabs()
        -- re-layout buttons horizontally
        self.nNextTabOffset = 0
        for i, v in ipairs(self.tTabInfos) do
            if not v.bHidden then
                v.rTabButton.tPosInfo.offsetX = self.nNextTabOffset
                v.rTabButton:alignToPosInfo()
                
                local w,h = v.rTabButton:getDims()
                self.nNextTabOffset = self.nNextTabOffset + w
            end
        end
    end

    function Ob:hideTab(sTabKey)
        for i,v in ipairs(self.tTabInfos) do
            if v.sTabKey == sTabKey then
                v.bHidden = true
                v.rTabButton:setEnabled(false)
--                v.rTabButton:hide(true)
                self:setElementHidden(v.rTabButton,true)
            end
        end

        self:_layoutVisibleTabs()
    end

    function Ob:revealTab(sTabKey)
        for i,v in ipairs(self.tTabInfos) do
            if v.sTabKey == sTabKey then
                v.bHidden = false
                v.rTabButton:setEnabled(true)
                self:setElementHidden(v.rTabButton,false)
--                v.rTabButton:show(v.rTabButton.rButton:getPriority())
            end
        end

        self:_layoutVisibleTabs()
        if not self.tTabInfos[self.nCurIndex] then
            self:setTabSelected(1)
        end
    end

    function Ob:removeTab(sTabKey)
        for i,v in ipairs(self.tTabInfos) do
            if v.sTabKey == sTabKey then
                local w,h = self.tTabInfos[i].rTabButton:getDims()
                self.nNextTabOffset = self.nNextTabOffset - w
                self:removeElement(self.tTabInfos[i].rUI)
                self:removeElement(self.tTabInfos[i].rTabButton)
                table.remove(self.tTabInfos,i)
                if self.nCurIndex == i then
                    self.nCurIndex = math.max(1,self.nCurIndex-1)
                end
            end
        end
        self:setTabSelected(math.min(self.nCurIndex, #self.tTabInfos))
    end

    function Ob:setTabSelected(nIndex)
        for i, tTabInfo in ipairs(self.tTabInfos) do
            self:setElementHidden(tTabInfo.rUI, i ~= nIndex)
            tTabInfo.rTabButton:setSelected(i == nIndex)
            if i == nIndex then
                tTabInfo.rTabButton:applyTemplateInfos(tTabInfo.rTabButton.tExtraTemplateInfo.tCallbacks.onSelected)
                tTabInfo.rUI:refresh()
                tTabInfo.rUI:onResize()
            else
                tTabInfo.rTabButton:applyTemplateInfos(tTabInfo.rTabButton.tExtraTemplateInfo.onDeselected)
            end
        end
        self.nCurIndex = nIndex
    end

    function Ob:setTabSelectedByKey(sTabKey)
        local idx = nil
        for i,v in ipairs(self.tTabInfos) do
            if v.sTabKey == sTabKey and not v.bHidden then
                idx = i
                break
            end
        end
        if idx then
            self:setTabSelected(idx)
        end
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
        if not self.tTabInfos[self.nCurIndex] then return false end
        
        local bTouched = false
        for i,tTabInfo in ipairs(self.tTabInfos) do
            if tTabInfo.rTabButton:onFinger(touch, x, y, props) then
                return true
            end
        end

        local rUI = self.tTabInfos[self.nCurIndex].rUI
        if rUI then
            return rUI:onFinger(touch, x, y, props)
        end
        return false
    end

    function Ob:inside(wx, wy)
        if not self.tTabInfos[self.nCurIndex] then return false end
    
        local bInside = false
        for i, tTabInfo in ipairs(self.tTabInfos) do
            bInside = tTabInfo.rTabButton:inside(wx, wy) or bInside
        end
        
        bInside = self.tTabInfos[self.nCurIndex].rUI:inside(wx, wy) or bInside
        
        return bInside
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
