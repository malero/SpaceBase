local UIElement = require('UI.UIElement')
local DFUtil = require("DFCommon.Util")
local Gui = require('UI.Gui')
local DFInput = require('DFCommon.Input')
local Button = require('UI.Button')

local m = {}

local PRESSED_SCALE_PCT = 0.7

function m.create()
    local Ob = DFUtil.createSubclass(Button.create())

    Ob.rTexture = nil
    Ob.tStates={'active','selected','hover','normal','disabled'}
    Ob.tTextures={}
    Ob.tColors={}
    --Ob.sButtonName = 'Background'

    function Ob:setLayoutFile(sUILayoutFileName)
        self:processUIInfo(sUILayoutFileName)
        self.sLastVisualState = nil
        self.sLastTemplate = nil
    end

    -- Table members: all optional.
		-- sActiveLinecode, sInactiveLinecode: active/inactive linecodes. Overriden by labelFn if it exists.
		-- labelFn: returns a displayable string. NOT a linecode.
		-- sLayoutFile: just a shortcut to getting setLayoutFile called. :P  e.g. 'UILayouts/ActionButtonLayout',
		-- sButtonElement: element for clickable button; just calls setButtonName.
		-- sLabelElement: target for sActiveLinecode,sInactiveLinecode,labelFn.
        -- buttonStatusFn: should return a string from the list in Ob.tStates.
		-- isVisibleFn: return true or false.
	function Ob:setBehaviorData(tData)
		-- define behaviors from table data
		if tData.sLayoutFile then
			self:setLayoutFile(tData.sLayoutFile)
		end
        if tData.sButtonName then
		    self:setButtonName(tData.sButtonName)
        elseif not self.sButtonName then
            -- Default
            self:setButtonName('ActionButton')
        end
		self.tBehaviorData = tData
        if self.rParentUIElement then
            local bTick = self.tBehaviorData.buttonStatusFn or self.tBehaviorData.isActiveFn or self.tBehaviorData.isVisibleFn or self.tBehaviorData.labelFn
            local key = self.sKey or self
            if bTick then
                if not self.rParentUIElement.tTickElements[key] then
                    self.rParentUIElement.tTickElements[key] = self
                end
            else
                if self.rParentUIElement.tTickElements[key] then
                    self.rParentUIElement.tTickElements[key] = nil
                end
            end
        end
	end
	
	function Ob:onTick(dt)
		Ob.Parent.onTick(self, dt)
		-- use behavior table data to determine label, status etc
		-- hidden/visible
		if self.tBehaviorData.isVisibleFn then
            local bShow = self.tBehaviorData.isVisibleFn(self) or false
            if bShow == self.elementsVisible then
                -- no show/hide call. bail on testing other functions, since the button isn't visible.
                if not bShow then return end
			elseif not bShow then
				self:hide()
				-- bail, any other status changes won't be visible
				return
			else
				self:show()
			end
		end
		-- status (disabled, selected)
		if self.tBehaviorData.buttonStatusFn then
			local sStatus = self.tBehaviorData.buttonStatusFn(self)
			self:setVisualsFromString(sStatus)
		end
		-- label
		local rLabel,sLabel
		if self.tBehaviorData.sLabelElement then
			 rLabel = self:getTemplateElement(self.tBehaviorData.sLabelElement or 'ActionButton')
		end
		if not rLabel then
			return
		end
		-- function = dynamic label text
		if self.tBehaviorData.labelFn then
			sLabel = self.tBehaviorData.labelFn(self)
		-- active/inactive linecodes = static label text
		elseif self.tBehaviorData.isActiveFn and self.tBehaviorData.sActiveLinecode and self.tBehaviorData.sInactiveLinecode then
			local bActive = self.tBehaviorData.isActiveFn(self)
			if bActive then
				sLabel = g_LM.line(self.tBehaviorData.sActiveLinecode)
			else
				sLabel = g_LM.line(self.tBehaviorData.sInactiveLinecode)
			end
        else
            if self.bActive then sLabel = g_LM.line(self.tBehaviorData.sActiveLinecode)
            else sLabel = g_LM.line(self.tBehaviorData.sInactiveLinecode) end
		end
        if not sLabel then sLabel = g_LM.line(self.tBehaviorData.sActiveLinecode or self.tBehaviorData.sInactiveLinecode) end
		rLabel:setString(sLabel)
	end
	
    function Ob:setButtonName(sName)
        self.sButtonName = sName
        self.rButton = self:getTemplateElement(self.sButtonName)
        self.tVisualStateData = (self.rButton and self.rButton.tElementInfo) or self.tElementInfo
        assertdev(self.tVisualStateData ~= nil)
        self.sLastVisualState = nil
        self.sLastTemplate = nil
    end

    function Ob:getDims()
        if self.rButton then return self.rButton:getDims() end
        return Ob.Parent.getDims(self)
    end
    
    function Ob:show(nPri)
        local n = Ob.Parent.show(self,nPri)
        self.sLastVisualState = nil
        self.sLastTemplate = nil
        self:_updateVisuals()
        return n
    end

    function Ob:_inBounds(wx,wy)
        if self.rButton then return self.rButton:_inBounds(wx,wy) end
        return false
    end

    function Ob:hide()
        self.bHover = false
        self.bActive = false
        self.bSelected = false        
        self:_updateVisuals()
        Ob.Parent.hide(self)
    end

    function Ob:_updateVisuals(bForce)
        Ob.Parent._updateVisuals(self)
        if self.sVisualState == self.sLastVisualState and not bForce then return end

        local tTemplate = nil
        local sTemplate = nil
        assertdev(self.tVisualStateData ~= nil)

        if self.sVisualState == 'disabled' then
            if self.tVisualStateData.onDisabledOn then
                tTemplate = self.tVisualStateData.onDisabledOn
                sTemplate = 'disabled'
            end
        elseif self.sVisualState == 'active' then
            if self.tVisualStateData.onPressed then
                tTemplate = self.tVisualStateData.onPressed
                sTemplate = 'pressed'
            elseif self.tVisualStateData.onHoverOn then
                tTemplate = self.tVisualStateData.onHoverOn
                sTemplate = 'hover'
            end
        elseif self.sVisualState == 'hover' then
            tTemplate = self.tVisualStateData.onHoverOn
            sTemplate = 'hover'
		elseif self.sVisualState == 'selected' then
			if self.tVisualStateData.onSelectedOn then
				tTemplate = self.tVisualStateData.onSelectedOn
				sTemplate = 'selected'
			else
				tTemplate = self.tVisualStateData.onHoverOn
				sTemplate = 'hover'
			end
        end

        if sTemplate ~= self.sLastTemplate or bForce then
			if self.sLastTemplate == 'selected' and self.tVisualStateData.onSelectedOff then
				self:applyTemplateInfos(self.tVisualStateData.onSelectedOff)
			-- don't unhover if selected
            elseif self.sLastTemplate == 'hover' and self.tVisualStateData.onHoverOff and not self.bSelected then
                self:applyTemplateInfos(self.tVisualStateData.onHoverOff)
            elseif self.sLastTemplate == 'pressed' and self.tVisualStateData.onReleased then
                self:applyTemplateInfos(self.tVisualStateData.onReleased)
            elseif self.sLastTemplate == 'disabled' then
                if self.tVisualStateData.onDisabledOff then
                    self:applyTemplateInfos(self.tVisualStateData.onDisabledOff)
                elseif self.tVisualStateData.onHoverOff then
                    self:applyTemplateInfos(self.tVisualStateData.onHoverOff)
                end
            end

            if tTemplate then
                self:applyTemplateInfos(tTemplate)
            end
        end

        -- refresh hack
        if bForce and not tTemplate and not self.sLastTemplate then
            if self.tVisualStateData.onSelectedOff or (self.tElementInfo and (self.tElementInfo.onHoverOff or self.tElementInfo.onReleased)) or self.tVisualStateData.onDisabledOff then
                self.rParentUIElement:applyTemplateInfos(self.tVisualStateData.onSelectedOff or (self.tElementInfo and (self.tElementInfo.onHoverOff or self.tElementInfo.onReleased)) or self.tVisualStateData.onDisabledOff)
            end
        end

        self.sLastVisualState = self.sVisualState
        self.sLastTemplate = sTemplate
        self.tLastTemplate = tTemplate
    end
	
    function Ob:isCursorInside()
        return self.bWasInside
    end
    
    --[[
    function Ob:setVisible(bVisible)
        self.bVisible = bVisible
        
        if self.rOnePixelProp then
            self.rOnePixelProp:setVisible(bVisible)
        end
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
