local Screen = require('UI.Screen')
local Class = require('Class')
local GameRules=require('GameRules')
local DebugManager=require('DebugManager')
local Renderer=require('Renderer')
local Character=require('CharacterConstants')
local SoundManager=require('SoundManager')
local ExampleSaveCycler=require('ExampleSaveCycler')
local DebugInfoManager = require('DebugInfoManager')
local EventController = require('EventController')
local Room = require('Room')
local Profile = require('Profile')

local GameScreen = Class.create(Screen)

GameScreen.bIsOpaque = true
GameScreen.inputMode = INPUTMODE_NORMAL

function GameScreen.beginTextEntry(textBox,focusObj,fnConfirmed,fnCanceled)
    GameScreen.textInputBox = textBox
    GameScreen.textBuffer = textBox:getString()
    GameScreen.textOriginal = GameScreen.textBuffer
    textBox:setString(GameScreen.textBuffer .. '_')
    GameScreen.textFocus = focusObj
    --GameScreen.textChangedCallback = fnChanged
    GameScreen.textConfirmedCallback = fnConfirmed
    GameScreen.textCanceledCallback = fnCanceled
    --GameScreen.textExitedCallback = fnExited
end

function GameScreen.inTextEntry()
    return GameScreen.textInputBox ~= nil
end

-- returns true if it handled the click.
function GameScreen.handleTextEntryClick(wx,wy)
    if GameScreen.textInputBox then
        if GameScreen.textInputBox:inside(wx,wy) then
            -- we could move the 'cursor' here.
        else
            GameScreen.endTextEntry()
        end
        return true
    end
end

function GameScreen.endTextEntry()
    if not GameScreen.textInputBox then return end
    --if GameScreen.textExitedCallback then GameScreen.textExitedCallback(GameScreen.textFocus, GameScreen.textFocus,GameScreen.textInputBox) end
    GameScreen.textInputBox:setString(GameScreen.textOriginal)
    GameScreen.textInputBox = nil
    GameScreen.textBuffer = nil
    GameScreen.textFocus = nil
    --GameScreen.textChangedCallback = nil
    GameScreen.textConfirmedCallback = nil
    GameScreen.textCanceledCallback = nil
    --GameScreen.textExitedCallback = nil
end

function GameScreen:onAddLayers(tRenderLayers)
    Renderer.addRenderLayers(tRenderLayers)
    Renderer.addDebugLayers(tRenderLayers)
end

function GameScreen:init()
    Screen.init(self)
    GameScreen.bFlipProp = false
end

function GameScreen:onHover(x, y)
    GameRules.handleHover(x,y)
end

function GameScreen:inputPointer(touch, bDoubleTap)
    GameRules.inputPointer(touch,bDoubleTap)
end

function GameScreen._cyclePropToPlace(bBackward)
    if not GameScreen.propToPlace then
        GameScreen.propList = {}
        local objList = require('EnvObjects.EnvObjectData')
        for name,data in pairs(objList.tObjects) do
            if data.showInObjectMenu == false then
                table.insert(GameScreen.propList,{name=name,data=data})
            end
        end
        
        GameScreen.propToPlaceIdx = 0
    end
    GameScreen.propToPlaceIdx = GameScreen.propToPlaceIdx + ((bBackward and -1) or 1)
    if GameScreen.propToPlaceIdx > #GameScreen.propList then
        GameScreen.propToPlaceIdx = 1
    elseif GameScreen.propToPlaceIdx < 1 then
        GameScreen.propToPlaceIdx = #GameScreen.propList
    end
    GameScreen.propToPlace = GameScreen.propList[GameScreen.propToPlaceIdx].name

    GameRules.setUIMode(GameRules.MODE_PLACE_PROP, GameScreen.propToPlace)
end

function GameScreen:onKeyboard(key, bDown)
    if g_GuiManager and g_GuiManager.isInStartupScreen() then -- ignore input during the loading screen
        return true
    end

    -- handle text first and specially
    if bDown and GameScreen.textInputBox then
		local nCharLimit = 21
        -- backspace
        if key == 8 then
            -- delete chars if we need to, otherwise don't add it as a string
            if GameScreen.textBuffer:len() > 0 then
                GameScreen.textBuffer = string.sub(GameScreen.textBuffer, 1, GameScreen.textBuffer:len() - 1)
            else
                return
            end
        -- escape
        elseif key == 27 then
			if GameScreen.textCanceledCallback then
				GameScreen.textCanceledCallback(GameScreen.textFocus,GameScreen.textBuffer)
			end
            GameScreen.endTextEntry()
            return
        -- enter
        elseif key == 13 then
            if GameScreen.textConfirmedCallback then
                GameScreen.textConfirmedCallback(GameScreen.textFocus,GameScreen.textBuffer)
            end
            GameScreen.textOriginal = GameScreen.textBuffer
            GameScreen.endTextEntry()
            return
        -- SHIFT, CTRL, ALT (disregard)
        elseif key == 256 or key == 257 or key >= 258 then
            return
        elseif GameScreen.textBuffer:len() < nCharLimit then
            GameScreen.textBuffer = GameScreen.textBuffer .. string.char(key)
        end
        GameScreen.textInputBox:setString(GameScreen.textBuffer..'_')
        --if GameScreen.textChangedCallback then GameScreen.textChangedCallback(GameScreen.textFocus,GameScreen.textBuffer) end
        return
	end
    
    
    local bHandled = false
    
    if g_GuiManager.newBaseActive then
        -- handle New Base input here
        bHandled = true -- currently we don't allow any keyboard input on the New Base screen
    end
	
    local bShift = MOAIInputMgr.device.keyboard:keyIsDown(MOAIKeyboardSensor.SHIFT)
	local bCtrl = MOAIInputMgr.device.keyboard:keyIsDown(MOAIKeyboardSensor.CONTROL)
    
    -- now see if the sidebar or its submenus want this key
    if not bHandled and not GameScreen.bUseDebugKeys and not bCtrl then
        bHandled = g_GuiManager.onKeyboard(key, bDown)
    end
	
    -- standard, legit keyboard commands that we don't want to press ~ before
    local World=require('World')
    if not bHandled and bDown then
        print('dbg key',key)
        if key == 27 then -- esc
            if not g_GuiManager:getSelected() and not g_GuiManager.newBaseActive and not g_GuiManager.newSideBar.rSubmenu then
                if not g_GuiManager.startMenuActive then
                    g_GuiManager.showStartMenu()
                else
                    g_GuiManager.startMenu:resume(false)
                end
            end
        elseif key == string.byte("o") then
            GameRules.cycleVisualizer()
			GameRules.completeTutorialCondition('UsedVizModes')
        elseif key == string.byte("k") then
            GameRules.cutawayMode = not GameRules.cutawayMode
            World.updateCutaway()
			GameRules.completeTutorialCondition('UsedVizModes')
        elseif GameRules.currentMode == GameRules.MODE_PLACE_PROP and key == string.byte("f") then
            -- allows you to flirp pre-propplop
            GameScreen.bFlipProp = not GameScreen.bFlipProp
			GameRules.completeTutorialCondition('FlippedObject')
        elseif (key == string.byte("+")) or (key == string.byte("="))
            or (key == string.byte("-")) or (key == string.byte("_")) then
            
            local bBackward = false
            if (key == string.byte("-")) or (key == string.byte("_")) then
                bBackward = true
            end
            
            if GameRules.inEditMode and GameRules.currentMode == GameRules.MODE_PLACE_PROP then
                GameScreen._cyclePropToPlace(bBackward)
            else
                local zoomAmount = -GameRules.ZOOM_WHEEL_STEP * 4.0
            
                if bBackward then
                    zoomAmount = -zoomAmount
                end
                GameRules.AddZoom(zoomAmount)
				GameRules.completeTutorialCondition('ZoomedView')
            end
        elseif bShift and ( key == string.byte(']') or key == string.byte('[') ) then
            -- cycle items in room
            local sel = g_GuiManager.getSelected()
            local rRoom
            if sel and sel.getProps then
                rRoom = sel
            elseif sel and sel.getRoom then
                rRoom = sel:getRoom()
            end
            if not rRoom then rRoom = g_SpaceRoom end
            local tProps = rRoom:getProps()
            local rPrev
            local rFound
            local bReturnNext=false
         	for rProp,_ in pairs(tProps) do
                if bReturnNext then 
                    rFound = rProp
                    break
                end
                if rProp == GameRules.rLastCycledProp then
                    if key == string.byte('[') then
                        if rPrev then 
                            rFound = rPrev
                            break
                        end
                    elseif key == string.byte(']') then
                        bReturnNext = true
                    end
                end
                rPrev = rProp
            end
            if not rFound and bReturnNext then 
                rFound = next(tProps)
            elseif not rFound then
                rFound = rPrev
            end
            GameRules.rLastCycledProp = rFound
            g_GuiManager.setSelected(rFound)
            if rFound and rFound.getLoc then
                local x, y = rFound:getLoc()
                GameRules._centerCameraOnPoint(x, y)
            end
        elseif key == string.byte(']') then
            GameRules.timeFaster()
			GameRules.completeTutorialCondition('SetTimeSpeed')
			GameRules.completeTutorialCondition('SpeedUpTime')
        elseif key == string.byte('[') then
            GameRules.timeSlower()
			GameRules.completeTutorialCondition('SetTimeSpeed')
			GameRules.completeTutorialCondition('SpeedUpTime')
        elseif key == string.byte(".") or key == string.byte(",") then
            if not bShift then
                -- select next/previous citizen
                local CM = require('CharacterManager')
                local tChars
                -- if dev build, select all characters not just base citizens
                if DFSpace.isDev() then
                    tChars = CM.getCharacters()
                else
                    tChars = CM.getTeamCharacters(Character.TEAM_ID_PLAYER)
                end
                local inc = 1
                if key == string.byte(",") then
                    inc = -1
                end
                GameRules.selectedCharIndex = GameRules.selectedCharIndex + inc
                if GameRules.selectedCharIndex > #tChars then
                    GameRules.selectedCharIndex = 1
                elseif GameRules.selectedCharIndex < 1 then
                    GameRules.selectedCharIndex = #tChars
                end
                g_GuiManager.setSelected(tChars[GameRules.selectedCharIndex])
            else
                -- select next/previous room
                local tRooms = Room.getRoomsOfTeam(Character.TEAM_ID_PLAYER,nil,nil,true)
                local inc = 1
                if key == string.byte(",") then
                    inc = -1
                end
                GameRules.selectedRoomIndex = GameRules.selectedRoomIndex + inc
                if GameRules.selectedRoomIndex > #tRooms then
                    GameRules.selectedRoomIndex = 1
                elseif GameRules.selectedRoomIndex < 1 then
                    GameRules.selectedRoomIndex = #tRooms
                end
                local rRoom = tRooms[GameRules.selectedRoomIndex]
                g_GuiManager.setSelected(rRoom)
                if rRoom then
                    local wx,wy = World._getWorldFromTile(rRoom:getCenterTile())
                    GameRules._centerCameraOnPoint(wx, wy)
                end
            end
         -- Ctrl+s
        elseif key == string.byte('s') and bCtrl then
            -- Saving disabled during events, but queue one up for after the event.
            if not EventController.tCurrentEventPersistentState then 
                if g_GuiManager.newSideBar:isConstructMenuOpen() then
                    g_GameRules.cancelBuild(true) -- let's cancel out any pending UNPAID construction
                    g_GuiManager.newSideBar:closeConstructMenu() 
                end
                GameRules.saveGame()
            else
                GameRules.bQueuedSave = true
            end
        -- Ctrl+l
        elseif key == string.byte('l') and bCtrl then
            GameRules.loadGame()
            GameRules.startLoop()
        elseif key == string.byte('z') and bCtrl then
            -- disaster mode stays on once discovered
            GameRules.bDisasterMode = true
        elseif key == 32 then -- spacebar
            GameRules.togglePause()
			GameRules.completeTutorialCondition('SetTimeSpeed')
        elseif key == 264 then -- F6
            Renderer.toggleUI()
        elseif DFSpace.isDev() or g_bAllowDebugInRelease then
            -- DEV ONLY
            if key == string.byte('?') then
                --DebugInfoManager.cycleDebugMode()
				DebugInfoManager.cycleInfoPage()
            elseif key == 262 then -- F4
                DebugInfoManager.drawSelectedDebug = not DebugInfoManager.drawSelectedDebug
                if DebugInfoManager.drawSelectedDebug then
                    g_GuiManager.debugInfoPane:show()
                else
                    g_GuiManager.debugInfoPane:hide()
                end
			elseif key == string.byte('1') then
				DebugInfoManager.nDebugInfoPage = 0
			elseif key == string.byte('2') then
				DebugInfoManager.nDebugInfoPage = 1
			elseif key == string.byte('3') then
				DebugInfoManager.nDebugInfoPage = 2
			elseif key == string.byte('4') then
				DebugInfoManager.nDebugInfoPage = 3
			elseif key == string.byte('5') then
				DebugInfoManager.nDebugInfoPage = 4
            else
                DebugManager:onKeyboard(key, bDown)
            end
        end
        g_GuiManager.refresh()
    end
    
    -- toggle debug keys
    if not bHandled and bDown then
        if DFSpace.isDev() or g_bAllowDebugInRelease then
            if key == 96 then -- "~"
                if GameScreen.bUseDebugKeys then 
                    GameScreen.bUseDebugKeys = false 
                    GameRules.setUIMode(GameRules.MODE_INSPECT)
                else
                    GameScreen.bUseDebugKeys = true
                end
            end
        end
    end
    
    if not bHandled and GameScreen.bUseDebugKeys then
        if bDown then
            if key == string.byte('r') and bCtrl then
                GameRules.reset()
            elseif key == 16 then -- ctrl+p
                require('EnvObjects.Spawner').spawnAll()
            elseif key == string.byte("h") then
                g_PowerHoliday = not g_PowerHoliday
            -- Editor controls on Shift
            elseif key == string.byte("A") then
                GameRules.setUIMode(GameRules.MODE_PLACE_ASTEROID)
            elseif key == string.byte("B") then
                require('World').testFloorDecal("blood01", nil)
            elseif key == string.byte("C") then
                GameRules.setUIMode(GameRules.MODE_MAKE_CHARACTER, Character.FACTION_BEHAVIOR.Citizen)
            elseif key == string.byte("D") then
                GameRules.setUIMode(GameRules.MODE_DAMAGE_WORLD_TILE)
            elseif key == string.byte("E") then
                GameRules.setEditMode(not GameRules.inEditMode)
            elseif key == string.byte("F") then
                local Fire = require('Fire')
                Fire.testFire()
            elseif key == string.byte("H") then
                GameRules.setUIMode(GameRules.MODE_MAKE_CHARACTER, Character.FACTION_BEHAVIOR.EnemyGroup)
            elseif key == string.byte("K") then
                GameRules.setUIMode(GameRules.MODE_MAKE_CHARACTER, Character.FACTION_BEHAVIOR.KillBot)
            elseif key == string.byte("L") then
                local Malady=require('Malady')
                Malady.DBG_testMalady()
            elseif key == string.byte("M") then
                GameRules.setUIMode(GameRules.MODE_MAKE_CHARACTER, Character.FACTION_BEHAVIOR.Monster)
            elseif key == string.byte("N") then
                require("AnimatedSprite").test()
                --require('CharacterManager').DBG_spawnMonster()
                --require('CharacterManager').DBG_addExperience()
            elseif key == string.byte("P") then
                if not GameScreen.propToPlace then
                    GameScreen._cyclePropToPlace()
                end
                GameRules.setUIMode(GameRules.MODE_PLACE_PROP, GameScreen.propToPlace)
            elseif key == string.byte("S") then
                GameRules.setUIMode(GameRules.MODE_PLACE_SPAWNER)
            elseif key == string.byte("W") then
                GameRules.setUIMode(GameRules.MODE_PLACE_WORLDOBJECT, 'BreachShip')
            elseif key == string.byte("Z") then
                GameRules.setUIMode(GameRules.MODE_DELETE_CHARACTER)
            elseif key == 127 then
                GameRules.deleteSelected()
            elseif bShift and key == string.byte("1") then
                EventController.DBG_forceForecastRegen()
            elseif bShift and key == string.byte("4") then
                GameRules.addMatter(1000)
            elseif bShift and key == string.byte("6") then
                EventController.DBG_forceNextEvent()
            elseif key == 268 then -- F10
                Profile.shinyStart()
            elseif key == 269 then -- F11
                ExampleSaveCycler.nextSave('Demo')
            elseif key == 270 then -- F12
                ExampleSaveCycler.nextSave('Perf')
            end
            --print("key:",key)
            g_GuiManager.refresh()
        else
            GameRules.bZooming = false
            DebugManager:onKeyboard(key, bDown)
        end
    end
end

return GameScreen

