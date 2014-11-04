local m = {}

local DFUtil = require("DFCommon.Util")
local DFInput = require('DFCommon.Input')
local Character = require('CharacterConstants')
local CharacterManager = require('CharacterManager')
local CitizenNames = require('CitizenNames')
local SoundManager = require('SoundManager')
local UIElement = require('UI.UIElement')
local Base = require('Base')
local ResearchData = require('ResearchData')
local GameRules = require('GameRules')
local ObjectList = require('ObjectList')
local TemplateButton = require('UI.TemplateButton')

local sUILayoutFileName = 'UILayouts/KillbotControllerActionTabLayout'

local tActionButtonData=
{
	-- Send Transmission
	{
		sActiveLinecode="MALEROUI0004TEXT",
        sInactiveLinecode="MALEROUI0004TEXT",
		sLayoutFile = 'UILayouts/ActionButtonLayout',
		sButtonName = 'ActionButton',
		sLabelElement = 'ActionLabel',
		isActiveFn=function(self)
			return false
		end,
        buttonStatusFn = function(self)
            return 'normal'
        end,
    },
}

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())
    Ob.tButtons = {}

    function Ob:init()
        self:processUIInfo(sUILayoutFileName)
        Ob.Parent.init(self)
        local x=110
        local y=-270
		local nButtonMargin = 20
        for i, tButtonData in ipairs(tActionButtonData) do
            local rButton = TemplateButton.new()
			rButton:setBehaviorData(tButtonData)
            local w,h = rButton:getDims()
            self:addElement(rButton)
            rButton:setLoc(x,y)
            y = y + h - nButtonMargin
            table.insert(self.tButtons, rButton)
        end
        self.tButtons[1]:addPressedCallback(self.sendTransmissionButtonPressed, self)
    end
	
	function Ob:sendTransmissionButtonPressed()
		if GameRules.getMatter() < 2500 then return end
		GameRules.expendMatter(2500)

		local nTransmissionChance = 0.1
		if Base.hasCompletedResearch('HumanResourcesLevel4') then
			nTransmissionChance = ResearchData['HumanResourcesLevel4'].nTransmissionSuccess
		elseif Base.hasCompletedResearch('HumanResourcesLevel3') then
			nTransmissionChance = ResearchData['HumanResourcesLevel3'].nTransmissionSuccess
		elseif Base.hasCompletedResearch('HumanResourcesLevel2') then
			nTransmissionChance = ResearchData['HumanResourcesLevel2'].nTransmissionSuccess
		elseif Base.hasCompletedResearch('HumanResourcesLevel1') then
			nTransmissionChance = ResearchData['HumanResourcesLevel1'].nTransmissionSuccess
		end
		
		local bSuccess = math.random() < nTransmissionChance
		if not bSuccess then return end
		local wx,wy,wz = self.rObject:getLoc()
		local tData = {
		    tStats = { nRace = Character.RACE_HUMAN, sName = CitizenNames.getNewUniqueName(Character.RACE_HUMAN, 'M') },
		    tStatus = { },
		}
		CharacterManager.addNewCharacter(wx, wy, tData, Character.TEAM_ID_PLAYER)
	end
	
	function Ob:setRoom(rRoom)
		for _,rButton in pairs(self.tButtons) do
			rButton.rSelected = rRoom
		end
	end
	
	function Ob:onTick(dt)
		-- individual buttons tick their status as defined in behavior data
        for _,rButton in pairs(self.tButtons) do
			rButton:onTick(dt)
		end
    end
	
	function Ob:setObject(rObject)
        self.rObject = rObject
    end
	
    function Ob:inside(wx, wy)
        local bInside = Ob.Parent.inside(self, wx, wy)
        for i, rButton in ipairs(self.tButtons) do
            bInside = rButton:inside(wx, wy) or bInside
        end
        return bInside
    end

    return Ob
end

function m.new(...)
    local Ob = m.create()
    Ob:init(...)

    return Ob
end

return m
