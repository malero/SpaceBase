local UIElement = require('UI.UIElement')
local DFUtil = require("DFCommon.Util")
local DFInput = require('DFCommon.Input')
local Button = require('UI.Button')
local SoundManager = require('SoundManager')

local m = {}

function m.create()
    local Ob = DFUtil.createSubclass(Button.create())

    Ob.rOnePixelProp = nil
    Ob.tDefaultColor = nil
    Ob.tHoverColor = nil
    Ob.tElementInfo = nil

    function Ob:init(sRenderLayerName,sLayoutFileName)
        Ob.Parent.init(self,sRenderLayerName,sLayoutFileName)

        self.rOnePixelProp = self:addOnePixel()
    end

    function Ob:setScl(x,y,z)
        self.rOnePixelProp:setScl(x,y,z)
    end

    function Ob:getScl()
        return self.rOnePixelProp:getScl()
    end

    function Ob:getDims()
        local w,h = self.rOnePixelProp:getScl()
        return w,-h
    end

    function Ob:setColor(r, g, b, a)
        if self.rOnePixelProp then
            self.tDefaultColor = { r, g, b, a }
            self.rOnePixelProp:setColor(r, g, b, a)
        end
    end 
    
    function Ob:hide()
        self.bHover = false
        self.bActive = false
--        self.bSelected = false        
        Ob.Parent.hide(self)
        self:_updateVisuals()
    end
    
    function Ob:show(n)
        local r = Ob.Parent.show(self,n)
        self:_updateVisuals()
        return r
    end

    function Ob:_updateVisuals(bForce)
        Ob.Parent._updateVisuals(self)
        if self.sVisualState == self.sLastVisualState and not bForce then return end

        local tTemplate = nil
        local sTemplate = nil
		
        if self.sVisualState == 'disabled' then
            if self.tElementInfo.onDisabledOn then
                tTemplate = self.tElementInfo.onDisabledOn
                sTemplate = 'disabled'
            end
        elseif self.sVisualState == 'active' then
            if self.tElementInfo.onPressed then
                tTemplate = self.tElementInfo.onPressed
                sTemplate = 'pressed'
            elseif self.tElementInfo.onHoverOn then
                tTemplate = self.tElementInfo.onHoverOn
                sTemplate = 'hover'
            end
        elseif self.sVisualState == 'hover' or (self.sVisualState == 'selected' and not self.tElementInfo.onSelectedOn) then
            tTemplate = self.tElementInfo.onHoverOn
            sTemplate = 'hover'
        elseif self.sVisualState == 'selected' then
            tTemplate = self.tElementInfo.onSelectedOn
            sTemplate = 'selected'
		end

        if sTemplate ~= self.sLastTemplate or bForce then
            if self.sLastTemplate == 'hover' and self.tElementInfo.onHoverOff then
                self.rParentUIElement:applyTemplateInfos(self.tElementInfo.onHoverOff)
            elseif self.sLastTemplate == 'pressed' and self.tElementInfo.onReleased then
                self.rParentUIElement:applyTemplateInfos(self.tElementInfo.onReleased)
                if sTemplate ~= 'hover' and self.tElementInfo.onHoverOff then
                    self.rParentUIElement:applyTemplateInfos(self.tElementInfo.onHoverOff)
                end
			elseif self.sLastTemplate == 'disabled' and self.tElementInfo.onDisabledOff then
				self.rParentUIElement:applyTemplateInfos(self.tElementInfo.onDisabledOff)
			end
            if tTemplate then
                self.rParentUIElement:applyTemplateInfos(tTemplate)
            end
        end
        
        -- refresh hack
        if bForce and not tTemplate and not self.sLastTemplate then
            if self.tElementInfo.onHoverOff or self.tElementInfo.onReleased then
                self.rParentUIElement:applyTemplateInfos(self.tElementInfo.onHoverOff or self.tElementInfo.onReleased)
            end
        end

        self.sLastVisualState = self.sVisualState
        self.sLastTemplate = sTemplate
        self.tLastTemplate = tTemplate
    end

    function Ob:isCursorInside()
        return self.bWasInside
    end

    function Ob:setVisible(bVisible)
        --if bVisible == self.bVisible then return end
        self.bVisible = bVisible
        --if bVisible then self:show()
        --else self:hide() end
        
        if self.rOnePixelProp then
            self.rOnePixelProp:setVisible(bVisible)
        end
        
    end
    

    --[[
    function Ob:setLocked(bLocked, bHoveredOverride, bPressedIgnoreLocks)
        self.bLocked = bLocked
        self.bPressedIgnoreLocks = bPressedIgnoreLocks
        if not self.bLocked then
            if self.bWasInside then
                self:onHover(true)
            else
                self:onHover(false)
            end
        end
        if bHoveredOverride ~= nil then
            self:onHover(bHoveredOverride, true)
        end
    end

    function Ob:isLocked()
        return self.bLocked
    end
    ]]--

    return Ob
end

function m.new(...)
    local Ob = m.create()
    Ob:init(...)

    return Ob
end

return m
