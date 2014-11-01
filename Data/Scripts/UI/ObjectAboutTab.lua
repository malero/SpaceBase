local m = {}

local DFUtil = require('DFCommon.Util')
local DFInput = require('DFCommon.Input')
local UIElement = require('UI.UIElement')

local sUILayoutFileName = 'UILayouts/ObjectAboutTabLayout'

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())
    Ob.rObject = nil

    function Ob:init()
        self:processUIInfo(sUILayoutFileName)
        Ob.Parent.init(self)
		self.rFlavorText = self:getTemplateElement('FlavorText')
    end
	
    function Ob:setObject(rObject)
        self.rObject = rObject
		if not self.rObject then
			return
		end
    end
	
    function Ob:onTick(dt)
        if not self.rObject then
			return
		end
		local sFlavor = (self.rObject.getFlavorText and self.rObject:getFlavorText()) or g_LM.line('OBFLAV007TEXT')
		self.rFlavorText:setString(sFlavor)
    end
	
    return Ob
end

function m.new(...)
    local Ob = m.create()
    Ob:init(...)

    return Ob
end

return m
