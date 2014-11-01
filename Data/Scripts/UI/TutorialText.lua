local m = {}

local DFUtil = require("DFCommon.Util")
local UIElement = require('UI.UIElement')
local Gui = require('UI.Gui')

local sUILayoutFileName = 'UILayouts/TutorialTextLayout'

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())

    function Ob:init()
        Ob.Parent.init(self)
        self:processUIInfo(sUILayoutFileName)
		self.rTutorialText = self:getTemplateElement('TutorialText')
		self.rTutorialBGTop = self:getTemplateElement('TutorialTextBGFadeTop')
		self.rTutorialBGMid = self:getTemplateElement('TutorialTextBG')
		self.rTutorialBGBot = self:getTemplateElement('TutorialTextBGFadeBottom')
		self.rBlip = self:getTemplateElement('TutorialBlip')
		self.nTextAlpha = 0
	end
	
	function Ob:setTutorialTextVisibility(bVisible)
        self:setElementHidden(self.rTutorialBGTop, not bVisible)
        self:setElementHidden(self.rTutorialBGMid, not bVisible)
        self:setElementHidden(self.rTutorialBGBot, not bVisible)
        self:setElementHidden(self.rTutorialText, not bVisible)
	end
	
	function Ob:setTutorialText(sLC)
		local s = g_LM.line(sLC)
		if self.rTutorialText:getString() ~= s then
			self:setTutorialTextVisibility(true)
			self.rTutorialText:setString(s)
			-- reset fade
			self.nTextAlpha = 0
		end
	end
	
	function Ob:onTick(dt)
		-- TODO: see if dealie should be active, move to right spot, scale it
		--local scl = math.abs(math.sin(g_GameRules.elapsedTime * 2)) + 2
		--self.rBlip:setScl(scl, scl)
		if g_GuiManager.inMainScreen() and self.nTextAlpha < 1 then
			self.nTextAlpha = self.nTextAlpha + 0.01
			-- drive color for fade up on text change
			self.rTutorialText:setColor(Gui.AMBER[1]*self.nTextAlpha, Gui.AMBER[2]*self.nTextAlpha, Gui.AMBER[3]*self.nTextAlpha, self.nTextAlpha)
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
