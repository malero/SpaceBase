local m = {}

local DFUtil = require("DFCommon.Util")
local DFInput = require('DFCommon.Input')
local UIElement = require('UI.UIElement')
local Door = require('EnvObjects.Door')
local SoundManager = require('SoundManager')
local ObjectList = require('ObjectList')

local sUILayoutFileName = 'UILayouts/DoorControlsLayout'

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())
    Ob.rObject = nil

    function Ob:init()
        self:processUIInfo(sUILayoutFileName)
        Ob.Parent.init(self)

        self.rNormalButton = self:getTemplateElement('NormalButton')
        self.rLockedButton = self:getTemplateElement('LockedButton')
        self.rForcedButton = self:getTemplateElement('ForcedButton')
        self.rNormalLabel = self:getTemplateElement('NormalLabel')
        self.rLockedLabel = self:getTemplateElement('LockedLabel')
        self.rForcedLabel = self:getTemplateElement('ForcedLabel')

        self.rNormalButtonTexture = self:getTemplateElement('NormalButtonTexture')
        self.rLockedButtonTexture = self:getTemplateElement('LockedButtonTexture')
        self.rForcedButtionTexture = self:getTemplateElement('ForcedButtonTexture')
        self.rNormalButtonTexturePressed = self:getTemplateElement('NormalButtonTexturePressed')
        self.rLockedButtonTexturePressed = self:getTemplateElement('LockedButtonTexturePressed')
        self.rForcedButtionTexturePressed = self:getTemplateElement('ForcedButtonTexturePressed')

        self.rNormalButton:addPressedCallback(self.onButtonPressed, self)
        self.rLockedButton:addPressedCallback(self.onButtonPressed, self)
        self.rForcedButton:addPressedCallback(self.onButtonPressed, self)
    end
	
	function Ob:setLockControlVisibility(bVisible)
		self.rNormalButton:setVisible(bVisible)
		self.rLockedButton:setVisible(bVisible)
		self.rForcedButton:setVisible(bVisible)
		self.rNormalLabel:setVisible(bVisible)
		self.rLockedLabel:setVisible(bVisible)
		self.rForcedLabel:setVisible(bVisible)
        self.rNormalButtonTexture:setVisible(bVisible)
        self.rLockedButtonTexture:setVisible(bVisible)
        self.rForcedButtionTexture:setVisible(bVisible)
	end
	
	function Ob:getCustomControlsLabel()
		return g_LM.line('PROPSX058TEXT')
	end
	
	function Ob:canControl()
		return not self.rObject:isPartOfFunctioningAirlock() and not self.rObject:_isSabotaged() and self.rObject:isFunctioning()
	end
	
    function Ob:onTick(dt)
        if not self.rObject then
			return
		end
		-- airlock door & functioning airlock? broken? dim/disable
		if self:canControl() then
			local operation = self.rObject:getOperation()
			self.rNormalButton:setSelected(operation == Door.operations.NORMAL)
			self.rLockedButton:setSelected(operation == Door.operations.LOCKED)
			self.rForcedButton:setSelected(operation == Door.operations.FORCED_OPEN)
			self.rNormalButton:setEnabled(true)
			self.rLockedButton:setEnabled(true)
			self.rForcedButton:setEnabled(true)
		else
			self.rNormalButton:setEnabled(false)
			self.rLockedButton:setEnabled(false)
			self.rForcedButton:setEnabled(false)
			self.rNormalButton:setSelected(false)
			self.rLockedButton:setSelected(false)
			self.rForcedButton:setSelected(false)
		end
    end

    function Ob:onButtonPressed(rButton, eventType)
        if self.rObject and self:canControl() then
            if eventType == DFInput.TOUCH_UP then
                if rButton == self.rNormalButton then
                    self.rObject:setOperation(Door.operations.NORMAL)
                    SoundManager.playSfx('inspectordoornormal')
                elseif rButton == self.rLockedButton then
                    self.rObject:setOperation(Door.operations.LOCKED)
                    SoundManager.playSfx('inspectordoorlock')
                elseif rButton == self.rForcedButton then
                    self.rObject:setOperation(Door.operations.FORCED_OPEN)
                    SoundManager.playSfx('selectdegauss')
                end
            end
        end
    end
	
    function Ob:setObject(rObject)
        self.rObject = rObject
		self:setLockControlVisibility(self.rObject ~= nil)
    end
	
    return Ob
end

function m.new(...)
    local Ob = m.create()
    Ob:init(...)

    return Ob
end

return m