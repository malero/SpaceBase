local m = {}

local DFUtil = require("DFCommon.Util")
local DFInput = require('DFCommon.Input')
local Character = require('CharacterConstants')
local CharacterManager = require('CharacterManager')
local CitizenNames = require('CitizenNames')
local SoundManager = require('SoundManager')
local UIElement = require('UI.UIElement')
local Base = require('Base')
local GameRules = require('GameRules')
local ObjectList = require('ObjectList')
local TemplateButton = require('UI.TemplateButton')

local sUILayoutFileName = 'UILayouts/KillbotControllerActionTabLayout'

local tActionButtonData=
{
	-- build killbot
	{
		sActiveLinecode="MALEROUI0003TEXT",
        sInactiveLinecode="MALEROUI0003TEXT",
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
        self.tButtons[1]:addPressedCallback(self.buildKillbotButtonPressed, self)
    end
	
	function Ob:buildKillbotButtonPressed()
		if GameRules.getMatter() < 5000 then return end
		GameRules.expendMatter(5000)
		local wx,wy,wz = self.rObject:getLoc()
		local tData = {
		    tStats = { nRace = Character.RACE_KILLBOT, sName = CitizenNames.getNewUniqueName(Character.RACE_KILLBOT) },
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
