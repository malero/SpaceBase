local m = {}

local DFUtil = require("DFCommon.Util")
local UIElement = require('UI.UIElement')
local DFInput = require('DFCommon.Input')
local ScrollableUI = require('UI.ScrollableUI')
local SoundManager = require('SoundManager')
local Base = require('Base')
local Goal = require('Goal')
local GoalData = require('GoalData')
local GoalEntry = require('UI.GoalEntry')

local sUILayoutFileName = 'UILayouts/GoalsListLayout'

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())

    function Ob:init()
        Ob.Parent.init(self)
        self:processUIInfo(sUILayoutFileName)
        self.rBackButton = self:getTemplateElement('BackButton')
        self.rBackButton:addPressedCallback(self.onBackButtonPressed, self)
        self.tHotkeyButtons = {}
        self:addHotkey(self:getTemplateElement('BackHotkey').sText, self.rBackButton)
		self.tGoalEntries = {}
        self.rGoalScrollableUI = self:getTemplateElement('GoalScrollPane')
		self.rGoalScrollableUI:setRenderLayer('UIScrollLayerRight')
        self.rGoalScrollableUI:setScissorLayer('UIScrollLayerRight')
        self.rSortCompleteButton = self:getTemplateElement('SortCompletedButton')
        self.rSortUncompleteButton = self:getTemplateElement('SortUncompletedButton')
        self.rSortCompleteButton:addPressedCallback(self.onSortCompletePressed, self)
        self.rSortUncompleteButton:addPressedCallback(self.onSortUncompletePressed, self)
		self.bCompletedFirst = false
    end
	
	function Ob:updateSortButtons()
		self.rSortCompleteButton:setSelected(self.bCompletedFirst)
		self.rSortUncompleteButton:setSelected(not self.bCompletedFirst)
	end
	
    function Ob:onSortCompletePressed(rButton, eventType)
        if eventType == DFInput.TOUCH_UP then
			self.bCompletedFirst = true
			self:updateSortButtons()
		end
	end
	
    function Ob:onSortUncompletePressed(rButton, eventType)
        if eventType == DFInput.TOUCH_UP then
			self.bCompletedFirst = false
			self:updateSortButtons()
		end
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
                -- you pressed the button
                bHandled = true
                rButton:keyboardPressed()
            end
        end
        if not bHandled and self.rSubmenu and self.rSubmenu.onKeyboard then
            bHandled = self.rSubmenu:onKeyboard(key, bDown)
        end
        return bHandled
    end
    
    function Ob:onBackButtonPressed(rButton, eventType)
        if eventType == DFInput.TOUCH_UP then
            if g_GuiManager.newSideBar then
                g_GuiManager.newSideBar:closeSubmenu()
                SoundManager.playSfx('degauss')
            end
        end
    end
    
    function Ob:show(basePri)
        if g_GameRules.getTimeScale() ~= 0 then
            self.bWasPaused = false
            g_GameRules.togglePause()
        else
            self.bWasPaused = true
        end
        local w,h = g_GuiManager.getUIViewportSizeX(), g_GuiManager.getUIViewportSizeY()
        g_GuiManager.createEffectMaskBox(0, 0, 1800, w, 0.3, 0.3)
        local nPri = Ob.Parent.show(self, basePri)
        self.rGoalScrollableUI:reset()
		self:updateSortButtons()
		-- hide status bar behind us
		g_GuiManager.statusBar:hide()
		g_GuiManager.tutorialText:hide()
		g_GuiManager.hintPane:hide()
		g_GuiManager.alertPane:hide()
        return nPri
    end
	
    function Ob:hide(bKeepAlive)
        if g_GameRules.getTimeScale() == 0 and not self.bWasPaused then
            g_GameRules.togglePause()
        end
        Ob.Parent.hide(self, bKeepAlive)
        self.rGoalScrollableUI:hide()
        for i, rEntry in ipairs(self.tGoalEntries) do
            rEntry:hide(bKeepAlive)
        end
		-- show status bar etc
		g_GuiManager.statusBar:show()
		g_GuiManager.tutorialText:show()
		g_GuiManager.hintPane:show()
		g_GuiManager.alertPane:show()
		g_GuiManager.hintPane:setMaximized(true)
		g_GuiManager.alertPane:setMaximized(true)
    end
	
    function Ob:onTick(dt)
		local tGoals = self:getAllGoals()
		local nTotalItems = #tGoals
		local nCurrentItems = #self.rGoalScrollableUI.tItems
		-- populate list of entries
		-- unlike research, # of list items won't change at runtime
		-- (but this code supports that regardless)
		if nTotalItems > nCurrentItems then
            for i=nCurrentItems+1,nTotalItems do
				self:addEntry(i)
			end
		elseif nTotalItems < nCurrentItems then
            for i=nCurrentItems,nTotalItems,-1 do
                self:removeEntry(i)
			end
		end
		-- set Y here instead of in addProjectEntry for hot reload friendliness
		for i,rEntry in ipairs(self.rGoalScrollableUI.tItems) do
			local w,h = rEntry:getDims()
			local nMargin = 32
			local nYLoc = (h - nMargin) * (i - 1)
			rEntry:setLoc(0, nYLoc)
			rEntry:setGoal(tGoals[i])
        end
        self.rGoalScrollableUI:refresh()
    end
	
	function Ob:getAllGoals()
		local tGoals = GoalData.tGoals
		local tItems = {}
		for i,tGoal in ipairs(tGoals) do
			table.insert(tItems, self:getGoalData(tGoal, i))
		end
		-- sort by progress (in-progress at top)
		local f = function(x,y)
			-- sort completed at top or bottom depending on button state
			if self.bCompletedFirst then
				if x.bComplete and not y.bComplete then
					return true
				elseif y.bComplete and not x.bComplete then
					return false
				end
				-- else: fall through to completion comparison
			else
				if not x.bComplete and y.bComplete then
					return true
				elseif x.bComplete and not y.bComplete then
					return false
				end
			end
			local nX, nY = x.nProgress / x.nTarget, y.nProgress / y.nTarget
			if nX == nY then
				return x.nTieBreaker > y.nTieBreaker
			else
				-- let's try sorting more progress higher - more urgent?
				return nX > nY
			end
		end
		table.sort(tItems, f)
		return tItems
	end

	function Ob:getGoalData(tGoal, nIndex)
		-- return a table with all the info needed for UI
		local tItemData = {}
		tItemData.sID = tGoal.sName
		tItemData.nProgress = Goal.tGoalProgress[tGoal.sName] or 0
		tItemData.bComplete = Base.tS.tGoals[tGoal.sName] or false
		tItemData.sName, tItemData.sDesc = tGoal.sNameLC,tGoal.sDescLC
		tItemData.nTarget = tGoal.nTarget or 0
		tItemData.nTieBreaker = nIndex
		return tItemData
	end
	
	function Ob:addEntry(nIndex)
		local rNewEntry = GoalEntry.new()
		-- Y loc will be set onTick
        self:_calcDimsFromElements()
		self.rGoalScrollableUI:addScrollingItem(rNewEntry)
		rNewEntry.rAssignmentScreen = self
	end
	
	function Ob:removeEntry(nIndex)
		self.rGoalScrollableUI:removeScrollingItem(self.rGoalScrollableUI.tItems[nIndex])
	end
	
	function Ob:onFinger(touch, x, y, props)
        if not self.elementsVisible then return false end
        local bHandled = false
        if self.rBackButton:onFinger(touch, x, y, props) or self.rSortCompleteButton:onFinger(touch, x, y, props) or self.rSortUncompleteButton:onFinger(touch, x, y, props) then
			return true
		end
        if self.rGoalScrollableUI:onFinger(touch, x, y, props) then
            bHandled = true
        end
		return bHandled
	end
	
    function Ob:inside(wx, wy)
        local bHandled = Ob.Parent.inside(self, wx, wy)
        self.rGoalScrollableUI:inside(wx, wy)
		self.rBackButton:inside(wx, wy)
        for i, rEntry in ipairs(self.rGoalScrollableUI.tItems) do
            if rEntry:inside(wx, wy) then
                bHandled = true
            end
        end
        return bHandled
    end
	
    return Ob
end

function m.new(...)
    local Ob = m.create()
    Ob:init(...)
	
    return Ob
end

return m
