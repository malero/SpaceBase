local DFUtil = require("DFCommon.Util")
local UIElement = require('UI.UIElement')
local Renderer = require('Renderer')
local ObjectList = require('ObjectList')
local MiscUtil = require('MiscUtil')
local GameRules = require('GameRules')
local Needs = require('Utility.Needs')
local Character = require('CharacterConstants')

local m = {}

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())
    Ob.bgColor = {0, 0, 0, 0}
    Ob.textColor = {1, 1, 1, 1}
	Ob.labelWidth = 75
	Ob.labelHeight = 50
	Ob.nBottomMargin = 25
	Ob.graphWidth = 418 - Ob.labelWidth
	Ob.graphHeight = 418 - Ob.nBottomMargin
	Ob.graphStartX = 0
	Ob.graphStartY = -kVirtualScreenHeight + Ob.graphHeight + Ob.nBottomMargin
    Ob.graphNodesToDraw = 200
    Ob.moraleGraphColor = {1, 0, 1}
    Ob.stuffGraphColor = {1, 0.5, 0.15}
    Ob.defaultGraphColor = {0.8, 0.8, 0.8}
    function Ob:init()
        Ob.Parent.init(self)
        self:setRenderLayer('UI')
        self.bVisible = false
		-- debug graphs
		local rDebugPaneScriptDeck = MOAIScriptDeck.new()
		rDebugPaneScriptDeck:setRect(0, 0, kVirtualScreenWidth, kVirtualScreenHeight)
		rDebugPaneScriptDeck:setDrawCallback(self.drawGraph)
		local rDebugPaneScriptDeckProp = MOAIProp2D.new ()
		rDebugPaneScriptDeckProp:setDeck ( rDebugPaneScriptDeck )
		rDebugPaneScriptDeckProp:setBlendMode( MOAIProp.GL_SRC_ALPHA, MOAIProp.GL_ONE_MINUS_SRC_ALPHA )
		Renderer.getRenderLayer('UI'):insertProp(rDebugPaneScriptDeckProp)
		-- table of label Y locations, used by CitizenPsychTab
		self.tLabels = {}
    end
	
	function Ob:inside(wx,wy)
        return false
    end
	
    function Ob:onTick(dt)
        if not GameRules.bInitialized then
            return
        end
    end
	
	function Ob:getGraphYRange()
		local maxY = Needs.MAX_VALUE
		local midY = (Needs.MAX_VALUE + Needs.MIN_VALUE) / 2
		local minY = Needs.MIN_VALUE
		return minY, midY, maxY
	end
	
	function Ob:drawGraph()
		if not Ob.bVisible then
			return
		end
        -- only draw if character is selected and pane is on an appropriate page
        local selected = g_GuiManager.getSelected()
		if not selected then
			return
		end
        local objType = ObjectList.getObjType(selected)
        if objType ~= ObjectList.CHARACTER then
			return
		end
		-- draw graph background
		local x0,y0 = Ob.graphStartX, Ob.graphStartY
		local x1,y1 = x0 + Ob.graphWidth, y0 - Ob.graphHeight
		MOAIGfxDevice.setPenColor( 0.5, 0.5, 0.5, 0.15 )
        MOAIDraw.fillRect ( x0, y0, x1, y1 )
		-- darker bg behind labels
		--MOAIGfxDevice.setPenColor( 0.15, 0.15, 0.15, 0.5 )
        --MOAIDraw.fillRect ( x1, y0, x1 + Ob.labelWidth, y1 )
		-- mid line
		MOAIGfxDevice.setPenColor( 0.5, 0.5, 0.5, 0.75 )
		y1 = y0 - (Ob.graphHeight / 2)
		MOAIDraw.drawLine( x0, y1, x1, y1 )
        -- mid-mid lines
		MOAIGfxDevice.setPenColor( 0.25, 0.25, 0.25, 0.5 )
		y1 = y0 - (Ob.graphHeight / 4)
		MOAIDraw.drawLine( x0, y1, x1, y1 )
		y1 = y0 - (Ob.graphHeight * 3/4)
		MOAIDraw.drawLine( x0, y1, x1, y1 )
        -- colored lines for each item
        for graph,items in pairs(selected.tStats.tHistory.tGraphItems) do
			local minY, midY, maxY = Ob:getGraphYRange()
			if graph ~= 'XP' then
				Ob:drawGraphLine(graph, items, minY, midY, maxY)
			end
        end
	end
    
    function Ob:drawGraphLine(graphName, graphItems, minY, midY, maxY)
        local color
        if graphName == 'Morale' then
            color = Ob.moraleGraphColor
        elseif graphName == 'Stuff' then
			color = Ob.stuffGraphColor
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
		Ob.tLabels[graphName] = {x=x, y=y}
    end
	
	function Ob:getGraphY(value, minY, maxY)
		-- normalize value
		value = (value + math.abs(minY)) / (maxY + math.abs(minY))
		return (Ob.graphStartY - Ob.graphHeight) + (math.min(value, 1) * Ob.graphHeight)
	end
	
    return Ob
end

function m.new(...)
    local Ob = m.create()
    Ob:init(...)

    return Ob
end

return m
