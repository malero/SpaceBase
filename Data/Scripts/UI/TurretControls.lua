local m = {}

local DFUtil = require("DFCommon.Util")
local DFInput = require('DFCommon.Input')
local UIElement = require('UI.UIElement')
local SoundManager = require('SoundManager')

local sUILayoutFileName = 'UILayouts/EmergencyAlarmControlsLayout'

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())
    Ob.rObject = nil
	
    function Ob:init()
		-- replace labels so we can reuse alarm layout
		self:setReplacements('OnLabel',{linecode='PROPSX087TEXT'})
		self:setReplacements('OffLabel',{linecode='PROPSX088TEXT'})
        self:processUIInfo(sUILayoutFileName)
        Ob.Parent.init(self)
        self.rHostileButton = self:getTemplateElement('OnButton')
        self.rAllButton = self:getTemplateElement('OffButton')
        self.rHostileButton:addPressedCallback(self.onButtonPressed, self)
        self.rAllButton:addPressedCallback(self.onButtonPressed, self)
    end
	
    function Ob:onTick(dt)
        if not self.rObject then
			return
		end
        if self.rObject._fireOnEveryone then
            self.rHostileButton:setSelected(not self.rObject:_fireOnEveryone())
            self.rAllButton:setSelected(self.rObject:_fireOnEveryone())
        end
		self.rHostileButton:setEnabled(self.rObject:canDeactivate())
		self.rAllButton:setEnabled(self.rObject:canDeactivate())
    end
	
	function Ob:getCustomControlsLabel()
		return g_LM.line('PROPSX090TEXT')
	end
	
    function Ob:onButtonPressed(rButton, eventType)
        if not self.rObject then
			return
		end
		if rButton == self.rHostileButton then
			self.rObject.bFireOnEveryone = false
			--SoundManager.playSfx('inspectordoornormal')
		elseif rButton == self.rAllButton then
			self.rObject.bFireOnEveryone = true
			--SoundManager.playSfx('inspectordoorlock')
		end
    end
	
    function Ob:setObject(rObject)
        self.rObject = rObject
    end

    return Ob
end

function m.new(...)
    local Ob = m.create()
    Ob:init(...)

    return Ob
end

return m
