local m = {}

local DFUtil = require("DFCommon.Util")
local DFMath = require("DFCommon.Math")
local UIElement = require('UI.UIElement')
local DFInput = require('DFCommon.Input')
local MiscUtil = require("MiscUtil")
local GameRules = require('GameRules')
local Renderer = require('Renderer')

local sUILayoutFileName = 'UILayouts/CheckboxLayout'

-- currently just a stub until masking tech
function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())

    function Ob:init(sConfigKey)
        Ob.Parent.init(self)
        
        self:setRenderLayer("UIOverlay")
        
        self:processUIInfo(sUILayoutFileName)
        
        self.rCheck = self:getTemplateElement('Check')
        self.rButtonToggle = self:getTemplateElement('ButtonToggle')
        self.rButtonToggle:addPressedCallback(self.toggle, self) 
        if sConfigKey then
            self.sConfigKey = sConfigKey
            self:setValue(g_Config:getConfigValue(sConfigKey) or self.bValue)
        end
    end

    function Ob:hide(bKeepAlive)
        Ob.Parent.hide(self,bKeepAlive)
    end

    function Ob:show(nMaxPri)
        self.bSliding = false
        self:setValue(self.bValue)
        return Ob.Parent.show(self, nMaxPri)
    end

    function Ob:toggle(rButton, eventType)
        self:setValue(not self.bValue)
    end
    
    function Ob:setValue(bValue, bNoCallback)
        bValue = bValue or false
        bNoCallback = bNoCallback or false
        if self.bValue ~= nil and self.bValue == bValue then return end
        self.bValue = bValue
        self.rCheck:setVisible(bValue)        
        g_Config:setConfigValue(self.sConfigKey, bValue)
        if (not bNoCallback) and self.onChangeCallback then
            self.onChangeCallback(self.sConfigKey, bValue)
        end
    end
    
    function Ob:onFileChange(path)
        Ob.Parent.onFileChange(self, path)
        
        self:setValue(self.bValue)
    end
    
    function Ob:onResize()
        Ob.Parent.onResize(self)
        
        self:setValue(self.bValue)
    end
    
    return Ob
end

function m.new(...)
    local Ob = m.create()
    Ob:init(...)

    return Ob
end

return m
