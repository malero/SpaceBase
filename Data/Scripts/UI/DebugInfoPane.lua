local DFUtil = require("DFCommon.Util")
local UIElement = require('UI.UIElement')
local Renderer = require('Renderer')
local DIM = require('DebugInfoManager')
local ObjectDebugInfo = require('UI.ObjectDebugInfo')
local ObjectList = require('ObjectList')
local UtilityAI = require('Utility.UtilityAI')
local MiscUtil = require('MiscUtil')
local GameRules = require('GameRules')
local Room = require('Room')
local World = require('World')
local DFInput = require('DFCommon.Input')
local Needs = require('Utility.Needs')
local Character = require('CharacterConstants')
local CharacterManager = require('CharacterManager')
local DFMath = require('DFCommon.Math')
local EventController = require('EventController')

local m = {}

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())
    
    Ob.x = 425
    Ob.y = 0
    Ob.width = kVirtualScreenWidth - Ob.x
    Ob.height = 1800
	
    Ob.bgColor = {0, 0, 0, 0}
    Ob.textColor = {1, 1, 1, 1}
    
	Ob.graphStartX = 1000
	Ob.graphStartY = -400
	Ob.graphWidth = 500
	Ob.graphHeight = 500
    Ob.graphNodesToDraw = 200
    Ob.moraleGraphColor = {1, 0, 1}
    Ob.stuffGraphColor = {1, 0.5, 0.15}
    Ob.defaultGraphColor = {0.8, 0.8, 0.8}
	Ob.labelWidth = 190
	Ob.labelHeight = 75
    
    function Ob:init()
        Ob.Parent.init(self)

        self:setRenderLayer("UIOverlay")

        self.selectedTextBox = self:addRect(self.width, self.height, unpack(self.bgColor))
        self.selectedTextBox:setLoc(self.x, self.y)
        self.selectedText = self:addTextToTexture("", self.selectedTextBox, "debugmono")
        -- cursor/build-centric debug info
        self.cursorTextBox = self:addRect(600, 600, unpack(self.bgColor))
        self.cursorText = self:addTextToTexture("", self.cursorTextBox, "debugmono")
        -- always-up info
        self.globalTextBox = self:addRect(1000, 600, unpack(self.bgColor))
        self.globalTextBox:setLoc(kVirtualScreenWidth - 475, -800)
        self.globalText = self:addTextToTexture("", self.globalTextBox, "debugmono")
        g_GuiManager.dSelectionChanged:register(self.refresh,self)
        -- event forecast, also always visible
        self.eventForecastTextBox = self:addRect(1000, 600, unpack(self.bgColor))
        self.eventForecastTextBox:setLoc(20, -520)
        self.eventForecastText = self:addTextToTexture("", self.eventForecastTextBox, "debugmono")
        EventController.dForecastGenerated:register(self.refresh, self)
        self.visible = true


        self.debugQuadDeck = MOAIGfxQuad2D.new()
        self.debugQuadDeck:setRect(0, 0, 1, -1)
        self.debugQuadProp = MOAIProp.new()
        self.debugQuadProp:setDeck(self.debugQuadDeck)
        self.debugQuadDeck:setTexture(Renderer.getGlobalTexture("white"))
        self.debugQuadProp:setVisible(false)
        local kDEBUG_TEXTURE_SIZE = 800
        self.debugQuadProp:setScl(kDEBUG_TEXTURE_SIZE, kDEBUG_TEXTURE_SIZE)
        self.debugQuadProp:setLoc(Renderer.rUIViewport.sizeX - kDEBUG_TEXTURE_SIZE, -Renderer.rUIViewport.sizeY + kDEBUG_TEXTURE_SIZE)

        Renderer.getRenderLayer("UIBackground"):insertProp(self.debugQuadProp)
        
		-- debug graphs
		local rDebugPaneScriptDeck = MOAIScriptDeck.new()
		rDebugPaneScriptDeck:setRect(0, 0, kVirtualScreenWidth, kVirtualScreenHeight)
		rDebugPaneScriptDeck:setDrawCallback(Ob.drawGraph)
		local rDebugPaneScriptDeckProp = MOAIProp2D.new ()
		rDebugPaneScriptDeckProp:setDeck ( rDebugPaneScriptDeck )
		rDebugPaneScriptDeckProp:setBlendMode( MOAIProp.GL_SRC_ALPHA, MOAIProp.GL_ONE_MINUS_SRC_ALPHA )
		Renderer.getRenderLayer('UIOverlay'):insertProp(rDebugPaneScriptDeckProp)
        -- graph labels
        self.tCommonGraphLabels = {}
		self.tMoraleNeedsGraphLabels = {}
		self.tStatsGraphLabels = {}
        -- color-coded text for each line
        local x, y = self.graphStartX, self.graphStartY - self.graphHeight - 40
        local w, h = self.labelWidth, self.labelHeight
        local color = self.moraleGraphColor
        -- 7th arg = key for this label, used to reposition specific ones
		-- 8th arg = add label to this list instead of the common labels list
        self:createGraphLabel(0, 0, w, h, color, 'Morale', 'Morale', self.tMoraleNeedsGraphLabels)
        y = y - 20
		color = self.stuffGraphColor
        self:createGraphLabel(0, 0, w, h, color, 'Stuff', 'Stuff', self.tMoraleNeedsGraphLabels)
        y = y - 20
        for needName,_ in pairs(Needs.tNeedList) do
            color = Needs.tNeedList[needName].graphColor
            self:createGraphLabel(0, 0, w, h, color, needName, needName, self.tMoraleNeedsGraphLabels)
            y = y - 20
        end
		-- stats page: duty XP
		self:createGraphLabel(0, 0, w, h, self.defaultGraphColor, 'XP', 'XP', self.tStatsGraphLabels)
        -- common y axis labels
		-- (axis label text is set in self:setGraphLabels depending on page)
        color = self.textColor
        x = x - 70
        y = self.graphStartY + 20
        self:createGraphLabel(x, y, w, h, color, 'MAX Y', 'MaxY')
        y = self.graphStartY - (self.graphHeight / 2) + 10
        self:createGraphLabel(x, y, w, h, color, 'MID Y', 'MidY')
        y = self.graphStartY - self.graphHeight + 20
        self:createGraphLabel(x, y, w, h, color, 'MIN Y', 'MinY')
        -- x axis labels: time before present (far right = present)
        y = self.graphStartY - self.graphHeight
        x = self.graphStartX - 20
        self:createGraphLabel(x, y, w, h, color, 'MIN X', 'MinX')
        -- 3/4 to oldest
        x = x + self.graphWidth * 0.25
        self:createGraphLabel(x, y, w, h, color, '3/4 X', 'ThreeQuarterX')
        -- 1/2 to oldest
        x = x + self.graphWidth * 0.25
        self:createGraphLabel(x, y, w, h, color, '1/2 X', 'HalfX')
        -- 1/4 to oldest
        x = x + self.graphWidth * 0.25
        self:createGraphLabel(x, y, w, h, color, '1/4 X', 'OneQuarterX')
        -- 0
        x = x + self.graphWidth * 0.25
        self:createGraphLabel(x, y, w, h, color, 'MAX X', 'MaxX')
        -- hide this mess
        self:hideGraphLabels()
    end
    
    function Ob:createGraphLabel(x, y, w, h, color, labelText, key, tLabelList)
		tLabelList = tLabelList or self.tCommonGraphLabels
        local box = self:addRect(w, h, unpack(self.bgColor))
        box:setLoc(x, y)
        local text = self:addTextToTexture("", box, "debugmono")
        text:setColor(unpack(color))
        text:setString(labelText or 'TEST')
        -- if a key name is supplied, use that so we can grab it easily later
        if key then
            tLabelList[key] = text
        else
            table.insert(tLabelList, text)
        end
    end
	
    function Ob:updateCursorText()
        local GridUtil = require('GridUtil')

        -- shows cursor location and drag size on cursor
        local cx,cy = GameRules.cursorX, GameRules.cursorY
        local wx,wy = Renderer.getWorldFromCursor(cx,cy)
        local tx,ty = World._getTileFromCursor(cx, cy)

        local nHealth = 999
        local tHealth = World.getTileHealth(tx, ty)
        if tHealth then
           nHealth = tHealth.nHealth
        end

        local text = 'cursor: '..tx..', '..ty
        -- anchor on cursor, with slight offset
        cx,cy = Renderer.getRenderLayer('UI'):wndToWorld(cx,cy)
        cx,cy = cx + 20, cy - 30
        self.cursorTextBox:setLoc(cx, cy)
        self.cursorText:setLoc(cx, cy)
        local sqX,sqY = GridUtil.IsoToSquare(tx, ty)
        text = text .. '\nsq-coord: ' .. tostring(sqX) .. ', ' .. tostring(sqY)

        -- show drag area size
        if GameRules.nDragging == DFInput.MOUSE_LEFT then
            local curX,curY = World._getTileFromCursor(GameRules.startDragX, GameRules.startDragY)
            text = text..'\nstart: '..curX..', '..curY

            local Cursor = require('UI.Cursor')
            local width, height = Cursor.getDragSize()
            width = MiscUtil.padString(width, 4)
            height = MiscUtil.padString(height, 4, true)
            text = text..'\ndrag: '..width..' x '..height

        end

        local tWall = Room.getWallAtTile(tx,ty)
        if tWall then
            text = text..'\nwall adj rooms: '
            for k,v in pairs(World.directions) do
                if tWall.tDirs[v] then
                    text = text..k..' '..tWall.tDirs[v]..', '
                end
            end
        end

        text = text ..'\nhealth: '..nHealth

        self.cursorText:setString(text)
    end

    function Ob:updateGlobalText()
        local text = 'DEBUG INFO (F4 to toggle)'
		local bDebugKeys = 'DISABLED'
		if require('GameScreen').bUseDebugKeys then
			bDebugKeys = 'ENABLED'
		end
		text = text .. '\nDebug keys: ' .. bDebugKeys
        text = text .. string.format('\nElapsed time: %.2f', GameRules.elapsedTime)
		local nHours = math.floor(GameRules.elapsedTime / (60*60))
		local sMinutes = math.floor(GameRules.elapsedTime / 60) - (nHours * 60)
		if sMinutes < 10 then
			sMinutes = '0'..sMinutes
		end
		local sSeconds = string.format('%.2f', GameRules.elapsedTime % 60)
		if GameRules.elapsedTime % 60 < 10 then
			sSeconds = '0'..sSeconds
		end
		text = text .. ' ('..nHours..':'..sMinutes..':'..sSeconds..')'
        text = text .. '\nOwned tiles: ' .. Room.getNumOwnedTiles()
		local _,nPlayerRooms,nHiddenRooms = Room.getRoomsOfTeam(Character.TEAM_ID_PLAYER)
		text = text .. '\nExplored/unexplored rooms: '..nPlayerRooms..'/'..nHiddenRooms
		-- TODO: citizens vs non-citizens
		
		local _,nCitizens = CharacterManager.getTeamCharacters(Character.TEAM_ID_PLAYER)
		local nOthers = #CharacterManager.getCharacters() - nCitizens
		text = text .. '\nCitizens/non-citizens: '..nCitizens..'/'..nOthers
        local camera = Renderer.getGameplayCamera()
        local cx, cy, cz = camera:getLoc()
        text = text .. string.format('\nCamera: %.1f, %.1f, %.1f', cx, cy, cz)
        text = text .. '\nCamera zoom: ' .. GameRules.currentZoom
        text = text .. ObjectDebugInfo.sRule
        text = text .. '\nNext event: '
        local tEventData = EventController.tS.tNextEventData
        if not tEventData then
            text = text .. '???'
        else
            local nTimeTilNext = tEventData.nStartTime - GameRules.elapsedTime
            local sNextEventType = tEventData.sEventType
            if sNextEventType == 'none' then
                sNextEventType = '[next check]'
            end
            text = text..string.format('%s in %.2f', sNextEventType, nTimeTilNext)
            -- if meteor, show location
            if tEventData.tx then
                text = text..string.format(' at %i, %i', tEventData.tx, tEventData.ty)
            end
        end
        self.globalText:setString(text)

        local selected = g_GuiManager.getSelected()

        if not selected then
            local f = EventController.getForecastDebugText()
            self.eventForecastText:setVisible(true)
            self.eventForecastText:setString(f)
            self.eventForecastTextBox:setLoc(20, -520)
            self.eventForecastText:setLoc(0,0)
        elseif ObjectList.getObjType(selected) == ObjectList.ROOM then
            local f = Room.getPowerDebugText()
            self.eventForecastText:setVisible(true)
            self.eventForecastText:setString(f)
            self.eventForecastTextBox:setLoc(400, -920)
            self.eventForecastText:setLoc(400,-300)
        else
            self.eventForecastText:setVisible(false)
        end
    end

    function Ob:refresh()
        if not DIM.drawSelectedDebug or not GameRules.bInitialized then
            return
        end
        self:updateCursorText()
        self:updateGlobalText()

        if DIM.debugTexture then
            self.debugQuadDeck:setTexture(DIM.debugTexture)
            self.debugQuadProp:setVisible(true)
        else
            self.debugQuadProp:setVisible(false)
        end

        local selected = g_GuiManager.getSelected()

        local s = ""
        local objType = ObjectList.getObjType(selected)
        if not objType then
        elseif objType == ObjectList.CHARACTER then
            s = ObjectDebugInfo.getCharacterDebugText(selected)
        elseif objType == ObjectList.ROOM then
            s = ObjectDebugInfo.getRoomDebugText(selected)
        elseif objType == ObjectList.ENVOBJECT then
            s = ObjectDebugInfo.getEnvObjectDebugText(selected)
        end
        self.selectedText:setString(s)
    end
	
    function Ob:inside(wx,wy)
        return false
    end

    function Ob:onTick(dt)
        self:refresh()
    end
    
    function Ob:showGraphLabels(tLabelList)
		tLabelList = tLabelList or self.tCommonGraphLabels
        for _,label in pairs(tLabelList) do
            label:setVisible(true)
        end
	end
    
    function Ob:hideGraphLabels(tLabelList)
		tLabelList = tLabelList or self.tCommonGraphLabels
        for _,label in pairs(tLabelList) do
            label:setVisible(false)
        end
	end
    
	function Ob:setGraphLabels(page,selected)
		local minY, midY, maxY
		if page == DIM.kDEBUG_PAGE_MORALE_NEEDS then
			-- y axis label contents
			minY, midY, maxY = Ob:getGraphYRange(DIM.kDEBUG_PAGE_MORALE_NEEDS)
			maxY = '+'..maxY
			midY = MiscUtil.padString(midY, 4)
			minY = tostring(minY)
			-- show graph-specific labels
			Ob:showGraphLabels(Ob.tMoraleNeedsGraphLabels)
		elseif page == DIM.kDEBUG_PAGE_STATS then
			minY, midY, maxY = Ob:getGraphYRange(DIM.kDEBUG_PAGE_STATS)
			maxY = tostring(maxY)
			midY = tostring(midY)
			minY = MiscUtil.padString(minY, 3)
			Ob:showGraphLabels(Ob.tStatsGraphLabels)
			-- graph line label shows level
			if selected.tStats.tJobExperience[selected.tStats.nJob] then
				local lvl = selected:getCurrentLevelByJob(selected.tStats.nJob) + 1
				Ob.tStatsGraphLabels.XP:setString('XP (to lvl '..lvl..')')
			else
				Ob.tStatsGraphLabels.XP:setString('(no duty)')
			end
		end
		-- y axis
		Ob.tCommonGraphLabels.MaxY:setString(maxY)
		Ob.tCommonGraphLabels.MidY:setString(midY)
		Ob.tCommonGraphLabels.MinY:setString(minY)
		-- x axis: same for both pages (for now)
		local x = Ob.graphNodesToDraw * -Character.GRAPH_TICK_RATE
		local deltaX = x / 4
		Ob.tCommonGraphLabels.MinX:setString(x..'s')
		x = x - deltaX
		Ob.tCommonGraphLabels.ThreeQuarterX:setString(x..'s')
		x = x - deltaX
		Ob.tCommonGraphLabels.HalfX:setString(x..'s')
		x = x - deltaX
		Ob.tCommonGraphLabels.OneQuarterX:setString(x..'s')
		x = 0
		Ob.tCommonGraphLabels.MaxX:setString(x..'s')
	end
	
	function Ob:getGraphYRange(page)
		local minY, midY, maxY = -1, 0, 1
		if page == DIM.kDEBUG_PAGE_MORALE_NEEDS then
			maxY = Needs.MAX_VALUE
			midY = (Needs.MAX_VALUE + Needs.MIN_VALUE) / 2
			minY = Needs.MIN_VALUE
		elseif page == DIM.kDEBUG_PAGE_STATS then
			maxY = Character.EXPERIENCE_PER_LEVEL
			midY = Character.EXPERIENCE_PER_LEVEL / 2
			minY = 0
		end
		return minY, midY, maxY
	end
	
	function Ob:drawGraph()
        Ob:hideGraphLabels()
        Ob:hideGraphLabels(Ob.tMoraleNeedsGraphLabels)
        Ob:hideGraphLabels(Ob.tStatsGraphLabels)
        -- only draw if character is selected and pane is on an appropriate page
		if not DIM.drawSelectedDebug then
			return
		end
        local selected = g_GuiManager.getSelected()
		local objType = ObjectList.getObjType(selected)
        if not objType then
            return
        elseif objType ~= ObjectList.CHARACTER then
			return
		elseif DIM.nDebugInfoPage ~= DIM.kDEBUG_PAGE_MORALE_NEEDS and DIM.nDebugInfoPage ~= DIM.kDEBUG_PAGE_STATS then
			return
		end
        Ob:showGraphLabels()
		Ob:setGraphLabels(DIM.nDebugInfoPage,selected)
		-- draw graph background
		local x0,y0 = Ob.graphStartX, Ob.graphStartY
		local x1,y1 = x0 + Ob.graphWidth, y0 - Ob.graphHeight
		MOAIGfxDevice.setPenColor( 0.5, 0.5, 0.5, 0.25 )
        MOAIDraw.fillRect ( x0, y0, x1, y1 )
		-- darker bg behind labels
		MOAIGfxDevice.setPenColor( 0.15, 0.15, 0.15, 0.5 )
        MOAIDraw.fillRect ( x1, y0, x1 + Ob.labelWidth, y1 )
		-- draw graph axes
		MOAIGfxDevice.setPenColor( 1, 1, 1, 1 )
		MOAIDraw.drawLine( x0, y0, x0, y1 )
		MOAIDraw.drawLine( x0, y1, x1, y1 )
		-- mid line
		MOAIGfxDevice.setPenColor( 0.5, 0.5, 0.5, 1 )
		y1 = y0 - (Ob.graphHeight / 2)
		MOAIDraw.drawLine( x0, y1, x1, y1 )
        -- mid-mid lines
		MOAIGfxDevice.setPenColor( 0.25, 0.25, 0.25, 1 )
		y1 = y0 - (Ob.graphHeight / 4)
		MOAIDraw.drawLine( x0, y1, x1, y1 )
		y1 = y0 - (Ob.graphHeight * 3/4)
		MOAIDraw.drawLine( x0, y1, x1, y1 )
        -- colored lines for each item
        for graph,items in pairs(selected.tStats.tHistory.tGraphItems) do
			local minY, midY, maxY = Ob:getGraphYRange(DIM.nDebugInfoPage)
			if graph == 'XP' and DIM.nDebugInfoPage == DIM.kDEBUG_PAGE_STATS then
				Ob:drawGraphLine(graph, items, Ob.tStatsGraphLabels, minY, midY, maxY)
			elseif graph ~= 'XP' and DIM.nDebugInfoPage == DIM.kDEBUG_PAGE_MORALE_NEEDS then
				Ob:drawGraphLine(graph, items, Ob.tMoraleNeedsGraphLabels, minY, midY, maxY)
			end
        end
	end
    
    function Ob:drawGraphLine(graphName, graphItems, tLabelList, minY, midY, maxY)
        local color
        if graphName == 'Morale' then
            color = Ob.moraleGraphColor
		elseif graphName == 'Stuff' then
			color = Ob.stuffGraphColor
		elseif graphName == 'XP' then
			color = Ob.defaultGraphColor
        else
            color = Needs.tNeedList[graphName].graphColor
        end
        MOAIGfxDevice.setPenColor( unpack(color) )
        local x = Ob.graphStartX + Ob.graphWidth
        local y = Ob.graphStartY - (Ob.graphHeight / 2)
        local prevX,prevY = x,y
        -- x distance between graph updates
        local tickWidth = Ob.graphWidth / Ob.graphNodesToDraw
        -- only draw most recent slice of graphItems
        -- (reverse and slice list)
        local tPoints = {}
        for i=0,Ob.graphNodesToDraw do
            tPoints[i] = graphItems[#graphItems-i]
        end
        -- draw the lines
        local bFirstPoint = true
        for i,item in pairs(tPoints) do
			y = Ob:getGraphY(item, minY, maxY)
            --MOAIDraw.fillCircle(x, y, 3)
            if bFirstPoint then
                prevY = y
                bFirstPoint = false
            end
            MOAIDraw.drawLine( x, y, prevX, prevY )
            prevX, prevY = x, y
            x = x - tickWidth
        end
        -- reposition text label
		if not tPoints[1] then
			return
		end
        x = Ob.graphStartX + Ob.graphWidth
		y = Ob:getGraphY(tPoints[1], minY, maxY) + 15
        tLabelList[graphName]:setLoc(x, y)
    end
	
	function Ob:getGraphY(value, minY, maxY)
		-- normalize value
		value = (value + math.abs(minY)) / (maxY + math.abs(minY))
		return (Ob.graphStartY - Ob.graphHeight) + (value * Ob.graphHeight)
	end
	
    return Ob
end

function m.new(...)
    local Ob = m.create()
    Ob:init(...)

    return Ob
end

return m
