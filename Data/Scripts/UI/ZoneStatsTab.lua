local m = {}

local DFUtil = require('DFCommon.Util')
local DFInput = require('DFCommon.Input')
local UIElement = require('UI.UIElement')
local Oxygen = require('Oxygen')

local sUILayoutFileName = 'UILayouts/ZoneStatsTabLayout'

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())
    Ob.rRoom = nil
    Ob.bDoRolloverCheck = true

    function Ob:init()
        self:processUIInfo(sUILayoutFileName)
        Ob.Parent.init(self)

        self.rSurfaceAreaText = self:getTemplateElement('SurfaceAreaText')
		self.rOxygenText = self:getTemplateElement('OxygenText')
		self.rOccupantsText = self:getTemplateElement('OccupantsText')
        self.rRoomContentsText = self:getTemplateElement('RoomContentsText')
        self.rPowerDrawLabel = self:getTemplateElement('PowerDrawLabel')
        self.rPowerDrawText = self:getTemplateElement('PowerDrawText')
		
        self.sSizeUnitString = g_LM.line("INSPEC057TEXT")
		self.sOccupantsString = g_LM.line("INSPEC061TEXT")
		self.sOccupantSingularString = g_LM.line("INSPEC063TEXT")
    end

    function Ob:onTick(dt)
        if not self.rRoom then
			return
		end
		-- surface area
		self.rSurfaceAreaText:setString(self.rRoom:getSize().." "..self.sSizeUnitString)
		-- o2 level
		local oxygen = math.floor(self.rRoom:getOxygenScore() / Oxygen.TILE_MAX * 100) .. '%'
		self.rOxygenText:setString(oxygen)
		-- (living) occupants
		local _,nOccupants = self.rRoom:getCharactersInRoom()
		local sOcc = self.sOccupantsString
		if nOccupants == 1 then
			sOcc = self.sOccupantSingularString
		end
		self.rOccupantsText:setString(nOccupants..' '..sOcc)
		-- if room draws power, show "power draw"
		local nOutput = self.rRoom.zoneObj:getPowerOutput()
		local nDraw = self.rRoom:getPowerDraw()
		local sLabel = g_LM.line('INSPEC163TEXT')
		local sPower = tostring(nDraw - nOutput)
		-- if room generates power, show "power output"
		if nOutput > nDraw then
			sLabel = g_LM.line('INSPEC167TEXT')
			sPower = tostring(nOutput - nDraw)
		end
		self.rPowerDrawLabel:setString(sLabel)
		self.rPowerDrawText:setString(sPower..' '..g_LM.line('INSPEC166TEXT'))
		-- props in room
		local tProps = self.rRoom:getProps()
		local tPropInfo = {}
		local sPropString = ""
		for rProp, _ in pairs(tProps) do
			if rProp.sFriendlyName then
				if not tPropInfo[rProp.sFriendlyName] then
					tPropInfo[rProp.sFriendlyName] = 0
				end
				tPropInfo[rProp.sFriendlyName] = tPropInfo[rProp.sFriendlyName] + 1
			end
		end
		for sPropName, nNumProps in pairs(tPropInfo) do
			local plural = ''
			if nNumProps > 1 then plural = 's' else plural = '' end
			sPropString = sPropString.." "..nNumProps.." "..sPropName..plural..'\n'
		end 
		self.rRoomContentsText:setString(sPropString)
    end

    function Ob:setRoom(rRoom)
        self.rRoom = rRoom
    end

    return Ob
end

function m.new(...)
    local Ob = m.create()
    Ob:init(...)

    return Ob
end

return m