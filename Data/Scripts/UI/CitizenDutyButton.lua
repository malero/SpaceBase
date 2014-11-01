local m = {}

local DFUtil = require("DFCommon.Util")
local UIElement = require('UI.UIElement')
local DFInput = require('DFCommon.Input')
local CharacterManager = require('CharacterManager')
local SoundManager = require('SoundManager')
local CharacterConstants = require('CharacterConstants')
local Gui = require('UI.Gui')

local sUILayoutFileName = 'UILayouts/CitizenDutyButtonLayout'

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())
    Ob.rDutyInfo = nil
    Ob.rCitizen = nil

    function Ob:init(rDutyInfo)
        self:setRenderLayer('UIScrollLayerLeft')

        Ob.Parent.init(self)
        self:processUIInfo(sUILayoutFileName)        

        self.rDutyIcon = self:getTemplateElement('DutyIcon')
        self.rButtonLabel = self:getTemplateElement('ButtonLabel')
        self.rButtonDescription = self:getTemplateElement('ButtonDescription')
        self.rStarsIcon = self:getTemplateElement('StarsIcon')
        self.rAffIcon = self:getTemplateElement('AffIcon')
        self.rStarsBG = self:getTemplateElement('StarBG')
        self.rNumText = self:getTemplateElement('NumText')
        self.rButton = self:getTemplateElement('Button')
        self.rButton:addPressedCallback(self.onDutyButtonPressed, self)
		self.nMarginY = self:getExtraTemplateInfo('nMarginY')
        
        assertdev(rDutyInfo)
        self.rDutyInfo = rDutyInfo
        if rDutyInfo then
            assertdev(rDutyInfo.enum and rDutyInfo.name and rDutyInfo.desc)
            if rDutyInfo.name then
                self.rButtonLabel:setString(g_LM.line(rDutyInfo.name))
                self:setTemplateUITexture('DutyIcon', CharacterConstants.JOB_ICONS[rDutyInfo.enum], 'UI/JobRoster')
            end
            if rDutyInfo.desc then
                self.rButtonDescription:setString(g_LM.line(rDutyInfo.desc))
            end
        end
		
		-- never show affinity for unemployment
		if self.rDutyInfo.enum == CharacterConstants.UNEMPLOYED then
			self.rAffIcon:setVisible(false)
		end
    end
    
    function Ob:show(n)
        local n2 = Ob.Parent.show(self,n)
        return n2
    end
    
    function Ob:hide()
        Ob.Parent.hide(self)
    end

    function Ob:onTick(dt)
        if not self.rCitizen or not self.rDutyInfo then
			return
		end
		if self.rCitizen:getJob() == self.rDutyInfo.enum then
			self.rButton:setSelected(true)
		else
			self.rButton:setSelected(false)
		end
		local competency
		local tStarBGColor = {}
		local nLevel
		if self.rDutyInfo.enum ~= CharacterConstants.UNEMPLOYED then
			-- JPL FIXME: poopie, the # of stars determination happens in
			-- UI.JobRosterEntry and isn't generally useful - move this out
			-- to CharacterConstants in the future.
			competency = self.rCitizen:getBaseJobCompetency(self.rDutyInfo.enum)
			competency = math.floor(competency * 10)
			competency = string.format('%i', math.floor(competency))
			-- set star texture and bgcolor
			nLevel = self.rCitizen:getJobLevel(self.rDutyInfo.enum)
			tStarBGColor = CharacterConstants.JOB_COMPETENCY_COLORS[nLevel]
			self.rStarsBG:setColor(tStarBGColor[1], tStarBGColor[2], tStarBGColor[3])
			self:setTemplateUITexture('StarsIcon', 'ui_jobs_skillrank'..nLevel, 'UI/JobRoster') 
			self.rStarsIcon:setColor(Gui.AMBER[1], Gui.AMBER[2], Gui.AMBER[3], 1)
			-- affinity for duty icon/color
			local nAff = self.rCitizen:getJobAffinity(self.rDutyInfo.enum)
			local sIcon,tColor = self.rCitizen:getAffinityIconAndColor(nAff)
			self:setTemplateUITexture('AffIcon', sIcon, 'UI/Emoticons')
			self.rAffIcon:setColor(unpack(tColor))
		else
			competency = '-'
			self.rStarsBG:setColor(Gui.AMBER_OPAQUE[1], Gui.AMBER_OPAQUE[2], Gui.AMBER_OPAQUE[3], 1)
			self.rStarsIcon:setColor(0,0,0,0)
		end
		self.rNumText:setString(tostring(CharacterManager.tJobCount[self.rDutyInfo.enum]))
	end

    function Ob:setCitizen(rCitizen)
        self.rCitizen = rCitizen
    end

    function Ob:getDims()
		local w,h = self.rButton:getDims()
        return w, h - self.nMarginY
    end

    function Ob:onDutyButtonPressed(rButton, eventType)
        if eventType == DFInput.TOUCH_UP then
            if self.rCitizen and self.rDutyInfo and not self.rCitizen:isDead() then
                self.rCitizen:setJob(self.rDutyInfo.enum)
                SoundManager.playSfx('inspectorduty')
            end
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
