local m = {}

local DFUtil = require("DFCommon.Util")
local DFInput = require('DFCommon.Input')
local UIElement = require('UI.UIElement')
local TemplateButton = require('UI.TemplateButton')
local Room = require('Room')
local SoundManager = require('SoundManager')

local sUILayoutFileName = 'UILayouts/InfirmaryBedControlsLayout'

local tEjectBehaviorData = {
	sLayoutFile = 'UILayouts/ActionButtonLayout',
	sLabelElement = 'ActionLabel',
	sInactiveLinecode = 'INSPEC150TEXT',
	sActiveLinecode = 'INSPEC150TEXT',
	isActiveFn=function(self)
		return true
	end,
	buttonStatusFn=function(self)
		if self.rSelected and self.rSelected:getUser() then
			return 'normal'
		end
		return 'disabled'
	end,
	x = 110,
	y = -255,
}

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())
    Ob.rObject = nil

    function Ob:init()
        self:processUIInfo(sUILayoutFileName)
        Ob.Parent.init(self)
		-- when occupied, clickable button to select that person
        self.rOccupantButton = self:getTemplateElement('OccupantButton')
        self.rOccupantButton:addPressedCallback(self.occupantButtonPressed, self)
		self.rEjectButton = TemplateButton.new()
		self.rEjectButton:setBehaviorData(tEjectBehaviorData)
        self.rEjectButton:addPressedCallback(self.ejectButtonPressed, self)
		self:addElement(self.rEjectButton)
		self.rEjectButton:setLoc(tEjectBehaviorData.x, tEjectBehaviorData.y)
		self.rEjectButton.rSelected = nil
    end
	
	function Ob:ejectButtonPressed()
		if self.rObject and self.rObject.eject then
			self.rObject:eject()
		end
	end
	
	function Ob:occupantButtonPressed()
		local rUser = self.rObject and self.rObject:getUser()
		if rUser then
			g_GuiManager.setSelected(rUser)
		end
	end
	
	function Ob:getCustomControlsLabel()
        local rOccupant = self.rObject and self.rObject:getUser()
        local sName = (rOccupant and rOccupant:getNiceName()) or g_LM.line('INSPEC075TEXT')
		return g_LM.line('INSPEC149TEXT') .. ' ' .. sName
	end
	
    function Ob:onTick(dt)
		local rOccupant = self.rObject and self.rObject:getUser()
        self:setElementHidden(self.rOccupantButton, not rOccupant)
		if self.rEjectButton.rSelected ~= self.rObject then
			self.rEjectButton.rSelected = self.rObject
		end
		self.rEjectButton:onTick(dt)
    end
	
    function Ob:setObject(rObject)
        self.rObject = rObject
    end
	
    function Ob:inside(wx, wy)
        local bInside = Ob.Parent.inside(self, wx, wy)
		return self.rEjectButton:inside(wx, wy) or bInside
	end
	
    return Ob
end

function m.new(...)
    local Ob = m.create()
    Ob:init(...)

    return Ob
end

return m
