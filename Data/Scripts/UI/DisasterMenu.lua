local m = {}

local DFUtil = require("DFCommon.Util")
local UIElement = require('UI.UIElement')
local DFInput = require('DFCommon.Input')
local SoundManager = require('SoundManager')

local MiscUtil = require('MiscUtil')
local Room = require('Room')
local Fire = require('Fire')
local EventController = require('EventController')
local CharacterManager = require('CharacterManager')
local Character = require('CharacterConstants')
local Malady = require('Malady')

local sUILayoutFileName = 'UILayouts/DisasterMenuLayout'

local nDisasterDelay = 3

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())
    Ob.rSelectedButton = nil

    function Ob:init()
        Ob.Parent.init(self)
    
        self:processUIInfo(sUILayoutFileName)

        self.rDoneButton = self:getTemplateElement('DoneButton')
        self.rFireButton = self:getTemplateElement('FireButton')
        self.rMeteorButton = self:getTemplateElement('MeteorButton')
        self.rKillbotButton = self:getTemplateElement('KillbotButton')
        self.rRaiderButton = self:getTemplateElement('RaiderButton')
        self.rBreachButton = self:getTemplateElement('BreachButton')
        self.rParasiteButton = self:getTemplateElement('ParasiteButton')
        self.rDerelictButton = self:getTemplateElement('DerelictButton')
        self.rDockButton = self:getTemplateElement('DockButton')

        self.rDoneButton:addPressedCallback(self.onDoneButtonPressed, self)
        self.rFireButton:addPressedCallback(self.onFireButtonPressed, self)
        self.rMeteorButton:addPressedCallback(self.onMeteorButtonPressed, self)
        self.rKillbotButton:addPressedCallback(self.onKillbotButtonPressed, self)
        self.rRaiderButton:addPressedCallback(self.onRaiderButtonPressed, self)
        self.rBreachButton:addPressedCallback(self.onBreachButtonPressed, self)
        self.rParasiteButton:addPressedCallback(self.onParasiteButtonPressed, self)
        self.rDerelictButton:addPressedCallback(self.onDerelictButtonPressed, self)
        self.rDockButton:addPressedCallback(self.onDockButtonPressed, self)
        
        self.tHotkeyButtons = {}
        self:addHotkey(self:getTemplateElement('DoneHotkey').sText, self.rDoneButton)
    end

    function Ob:addHotkey(sKey, rButton)
        sKey = string.lower(sKey)
    
        local keyCode = -1
    
        if sKey == "esc" then
            keyCode = 27
        elseif sKey == "ret" or sKey == "ent" then
            keyCode = 13
        elseif sKey == "spc" then
            keyCode = 32
        else
            keyCode = string.byte(sKey)
            
            -- also store the uppercase version because hey why not
            local uppercaseKeyCode = string.byte(string.upper(sKey))
            self.tHotkeyButtons[uppercaseKeyCode] = rButton
        end
    
        self.tHotkeyButtons[keyCode] = rButton
    end
    
    -- returns true if key was handled
    function Ob:onKeyboard(key, bDown)
        local bHandled = false

        if not self.rSubmenu then
            if bDown and self.tHotkeyButtons[key] then
                local rButton = self.tHotkeyButtons[key]
                rButton:keyboardPressed()
                bHandled = true
            end
        end
        
        if not bHandled and self.rSubmenu and self.rSubmenu.onKeyboard then
            bHandled = self.rSubmenu:onKeyboard(key, bDown)
        end
        
        return bHandled
    end

    function Ob:onDoneButtonPressed(rButton, eventType)
        if eventType == DFInput.TOUCH_UP then
            if g_GuiManager.newSideBar then
                g_GuiManager.newSideBar:closeSubmenu()
                SoundManager.playSfx('degauss')
            end
        end
    end
    
    function Ob:randomSpotInBase()
        local tRooms = Room.getRoomsOfTeam(Character.TEAM_ID_PLAYER, false, nil, true)
        local rRoom = MiscUtil.randomValue(tRooms)
        if not rRoom then
            return
        end
        return rRoom:randomLocInRoom(false,true,false)
    end
    
    function Ob:onFireButtonPressed(rButton, eventType)
        if eventType == DFInput.TOUCH_UP then
            local wx,wy = self:randomSpotInBase()
            Fire.startFire(wx,wy)
        end
    end
    
    function Ob:onMeteorButtonPressed(rButton, eventType)
        if eventType == DFInput.TOUCH_UP then
            EventController.DBG_forceQueue('meteorEvents')
        end
    end
    
    function Ob:onKillbotButtonPressed(rButton, eventType)
        if eventType == DFInput.TOUCH_UP then
            local wx,wy = self:randomSpotInBase()
            local tData = {
                tStats = { nRace = Character.RACE_KILLBOT, sName = 'KillBot' },
                tStatus = { },
            }
            CharacterManager.addNewCharacter(wx, wy, tData, Character.TEAM_ID_DEBUG_MONSTER)
        end
    end

    function Ob:onRaiderButtonPressed(rButton, eventType)
        if eventType == DFInput.TOUCH_UP then
            EventController.DBG_forceQueue('hostileImmigrationEvents', false, nDisasterDelay)
        end
    end
    
    function Ob:onBreachButtonPressed(rButton, eventType)
        if eventType == DFInput.TOUCH_UP then
            EventController.DBG_forceQueue('breachingEvents')
        end
    end
    
    function Ob:onParasiteButtonPressed(rButton, eventType)
        if eventType == DFInput.TOUCH_UP then
            local tChars = CharacterManager.getOwnedCharacters()
            local rChar = MiscUtil.randomValue(tChars)
            local tMalady = Malady.createNewMaladyInstance('Parasite')
            -- make the parasite ready to burst
            tMalady.tSymptomStarts[1] = g_GameRules.elapsedTime + 0.01
            tMalady.tSymptomStarts[2] = g_GameRules.elapsedTime + nDisasterDelay
            tMalady.tSymptomStages[1].tTimeToSymptoms = {0.1, 0.2}
            tMalady.tSymptomStages[2].tTimeToSymptoms = {nDisasterDelay, nDisasterDelay}
            rChar:diseaseInteraction(nil,tMalady)
        end
    end
    
    function Ob:onDerelictButtonPressed(rButton, eventType)
        if eventType == DFInput.TOUCH_UP then
            EventController.DBG_forceQueue('hostileDerelictEvents', false, nDisasterDelay)
        end
    end
    
    function Ob:onDockButtonPressed(rButton, eventType)
        if eventType == DFInput.TOUCH_UP then
            EventController.DBG_forceQueue('hostileDockingEvents', false, nDisasterDelay)
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
