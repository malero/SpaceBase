local DFUtil = require("DFCommon.Util")
local UIElement = require('UI.UIElement')
local Renderer=require('Renderer')
local GameRules = require('GameRules')
local Cursor = require('UI.Cursor')
local DFInput = require('DFCommon.Input')
local EnvObject = require('EnvObjects.EnvObject')
local Zone = require('Zones.Zone')
local SoundManager=require('SoundManager')

local m = {}

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())
	
	Ob.width = 480
    Ob.height = 320
    Ob.x = 340
    Ob.y = -210
	
	Ob.bgColor = {0,0,0,0}
	Ob.font = 'dosissemibold30'
	
    function Ob:init()
        Ob.Parent.init(self)
		self.layer = Renderer.getRenderLayer('UI')
        self.textBox = self:addRect(self.width, self.height, unpack(self.bgColor))
        self.text = self:addTextToTexture("AAAA", self.textBox, self.font)
        self.tLastDragSize = {x=0, y=0}
        -- fixed screen location
		self.textBox:setLoc(self.x, self.y)
		self.text:setLoc(self.x, self.y)
    end
	
	function Ob:getSizeText()
		local w, h = Cursor.getDragSize()
		if w == 0 and h == 0 then
			return
		end
        -- show player floor area, not floor + wall
        if GameRules.currentMode == GameRules.MODE_BUILD_ROOM then
            w = math.max(0, w - 2)
            h = math.max(0, h - 2)
        end
        -- "floor area:" text
		return string.format('%s %s x %s', g_LM.line('HUDHUD039TEXT'), w, h)
	end
	
	function Ob:getTotalCostText()
		local cost, items
        if Cursor.tempCommand then
            cost,items = Cursor.tempCommand:getMatterCost()
        end
		if not cost then
			return
		end
        -- "cost:" text
        local text = string.format('%s %s (', g_LM.line('HUDHUD042TEXT'), tostring(cost))
		if items.wall then
			text = text .. items.wall .. ' ' .. g_LM.line('HUDHUD040TEXT') .. ', '
		end
		if items.floor then
			text = text .. items.floor .. ' ' .. g_LM.line('HUDHUD041TEXT')
		end
		text = text .. ')'
		return text
	end
	
    function Ob:getCapacityInDimension(nObjSize, nObjMargin, nFloorSize)
        -- returns 1D capacity for a given total floor space / object size and margin
        nFloorSize = nFloorSize - (nObjSize + (nObjMargin * 2))
        if nFloorSize < 0 then
            -- not even room for 1
            return 0
        end
        -- start at 1 to account for double margin of 1st
        local nCapacity = 1
        while nFloorSize > 0 do
            nFloorSize = nFloorSize - (nObjSize + nObjMargin)
            nCapacity = nCapacity + 1
        end
        -- if we ran past 0, we didn't actually have room for the last one
        if nFloorSize < 0 then
            nCapacity = nCapacity - 1
        end
       return nCapacity
    end
    
	function Ob:getCapacityText()
		-- returns a table of strings, each describing the current drag area's
		-- zone:object capacity
		local tLines = {}
		local tPropsToCheck = { 'OxygenRecycler', 'Bed', 'RefineryDropoff', 'Generator' }
		local w, h = Cursor.getDragSize()
        -- floor area, not floor + wall
        if GameRules.currentMode == GameRules.MODE_BUILD_ROOM then
            w = w - 2
            h = h - 2
        end
		for _,prop in pairs(tPropsToCheck) do
			local propData = EnvObject.getObjectData(prop)
			local sZoneName = Zone[propData.zoneName].name
			-- determine footprint in each dimension, normal and flipped
            local capacityX = self:getCapacityInDimension(propData.width, propData.margin, w)
            local capacityY = self:getCapacityInDimension(propData.height, propData.margin, h)
            local capacityXflipped = self:getCapacityInDimension(propData.height, propData.margin, w)
            local capacityYflipped = self:getCapacityInDimension(propData.width, propData.margin, h)
			-- use flipped capacity if it's higher
			local capacity = math.max(capacityX * capacityY, capacityXflipped * capacityYflipped)
			local sPropName = g_LM.line(propData.friendlyNameLinecode)
			local text = string.format('%s: %i %s', sZoneName, capacity, sPropName)
			-- only show lines for things we have room for
			if capacity > 0 then
				table.insert(tLines, text)
			end
		end
		return tLines
	end
	
    function Ob:refresh(str)
		if not GameRules.isBuildMode(GameRules.currentMode) then
			self:hide()
			return
		end
		self:show()
		-- only show if left mouse is dragging
		if GameRules.nDragging ~= DFInput.MOUSE_LEFT then
			self:hide()
			return
		end
		local sSizeText = self:getSizeText()
		if not sSizeText then
			self:hide()
			return
		end
		local sTotalCostText = self:getTotalCostText()
		if not sTotalCostText then
			self:hide()
			return
		end
		local text = string.format('%s\n%s', sSizeText, sTotalCostText)
		local tCapacityLines = self:getCapacityText()
		if GameRules.currentMode == GameRules.MODE_BUILD_ROOM and #tCapacityLines > 0 then
			text = text .. '\n' .. g_LM.line('HUDHUD043TEXT')
			for _,line in ipairs(tCapacityLines) do
				text = text .. '\n   ' .. line
			end
		end
		self.text:setString(text)
		--self:centerOnCursor()
        local x,y = Cursor.getDragSize()
        if self.tLastDragSize.x ~= x or self.tLastDragSize.y ~= y then
            SoundManager.playSfx('buildscroll')
            self.tLastDragSize = {x=x,y=y}
        end
    end
	
	function Ob:centerOnCursor()
		self.x, self.y = self.layer:wndToWorld(GameRules.cursorX, GameRules.cursorY)
		self.x = self.x + 30
		self.y = self.y - 50
		self.textBox:setLoc(self.x, self.y)
		self.text:setLoc(self.x, self.y)
	end
	
	function Ob:onTick(dt)
        self:refresh()
    end
	
	return Ob
end

function m.new(...)
    local Ob = m.create()
    Ob:init(...)

    return Ob
end

return m
