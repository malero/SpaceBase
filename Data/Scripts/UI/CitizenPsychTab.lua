local m = {}

local DFUtil = require("DFCommon.Util")
local DFInput = require('DFCommon.Input')
local Character = require('CharacterConstants')
local UIElement = require('UI.UIElement')
local Needs = require('Utility.Needs')
local PsychGraph = require('UI.PsychGraph')

local sUILayoutFileName = 'UILayouts/CitizenPsychTabLayout'

local tGraphLabels = {
	Morale = 'GraphLabelMorale',
	Duty = 'GraphLabelDuty',
	Energy = 'GraphLabelEnergy',
	Social = 'GraphLabelSocial',
	Amusement = 'GraphLabelAmusement',
	Hunger = 'GraphLabelHunger',
	Stuff = 'GraphLabelStuff',
}

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())
    Ob.rCitizen = nil
    Ob.bDoRolloverCheck = true

    function Ob:init()
        self:processUIInfo(sUILayoutFileName)
        Ob.Parent.init(self)
		self.rPsychGraph = PsychGraph.new()
        self.rSelfEsteemText = self:getTemplateElement('SelfEsteemText')
        self.rRoomSatisfactionText = self:getTemplateElement('RoomSatisfactionText')
        self.rJobSatisfactionText = self:getTemplateElement('JobSatisfactionText')
        self.rPersonalityText = self:getTemplateElement('PersonalityText')
		-- list of graph label element names
		self.tGraphLabels = {}
		for sNeed,sLabel in pairs(tGraphLabels) do
			self.tGraphLabels[sNeed] = self:getTemplateElement(sLabel)
		end
		self.rHalfGraphX = self:getTemplateElement('GraphLabelX2')
		self.rEndGraphX = self:getTemplateElement('GraphLabelX3')
    end
	
    function Ob:onTick(dt)
        if not self.rCitizen then
			return
		end
		-- nothing that dynamically updates in hostile mode RN
		if self.bHostileMode then
			return
		end
		self.rPsychGraph:onTick(dt)
		self.rSelfEsteemText:setString(self:_getSelfEsteemString())
		self.rRoomSatisfactionText:setString(self:_getRoomString())
		self.rJobSatisfactionText:setString(self:_getJobSatString())
		self.rPersonalityText:setString(self:_getPersonalityString())
		-- graph labels
		if not self.rPsychGraph then
			return
		end
		-- sort graph labels by Y, process them in order
		local tLabels = {}
		for sNeed,tLabelPos in pairs(self.rPsychGraph.tLabels) do
			table.insert(tLabels, {sNeed=sNeed, x=tLabelPos.x, y=tLabelPos.y})
		end
		local f = function(x,y) return x.y > y.y end
		table.sort(tLabels, f)
		-- getDims for label height doesn't reflect rendered text size,
		-- use a hand-tuned value
		local nLabelHeight = 20
		for i,tLabelInfo in pairs(tLabels) do
			-- label color
			local rLabel = self.tGraphLabels[tLabelInfo.sNeed]
			local tColor
			if tLabelInfo.sNeed == 'Morale' then
				tColor = self.rPsychGraph.moraleGraphColor
			elseif tLabelInfo.sNeed == 'Stuff' then
				tColor = self.rPsychGraph.stuffGraphColor
			else
				tColor = Needs.tNeedList[tLabelInfo.sNeed].graphColor
			end
			rLabel:setColor(unpack(tColor))
			-- label position
			local x,y = tLabelInfo.x, tLabelInfo.y
			-- push Y down if overlap with previous
			if i > 1 and y > tLabels[i-1].y - nLabelHeight then
				y = tLabels[i-1].y - nLabelHeight
				-- write back to table so lower needs check correctly
				tLabelInfo.y = y
			end
			-- offset for surrounding UI layout
			y = y + self.rPsychGraph.graphHeight + 100
			rLabel:setLoc(x, y)
		end
		-- set X axis labels for # of seconds ago, based on graph tick rate
		local nEndGraphTime = (Character.GRAPH_TICK_RATE * Character.GRAPH_MAX_ENTRIES) / 60
		self.rEndGraphX:setString('-'..nEndGraphTime..'h')
		self.rHalfGraphX:setString('-'..(nEndGraphTime/2)..'h')
    end
	
    function Ob:setCitizen(rCitizen)
        self.rCitizen = rCitizen
    end
	
    function Ob:setHostileMode(bSet)
        self.bHostileMode = bSet
        if bSet then
            local tOverrides = self:getExtraTemplateInfo('tHostileMode')
            if tOverrides then
                self:applyTemplateInfos(tOverrides)
            end
        else
            local tOverrides = self:getExtraTemplateInfo('tCitizenMode')
            if tOverrides then
                self:applyTemplateInfos(tOverrides)
            end
        end
    end
	
    function Ob:show(n)
        local n2 = Ob.Parent.show(self,n)
		self.rPsychGraph.bVisible = true
        return n2
    end
    
    function Ob:hide()
        Ob.Parent.hide(self)
		self.rPsychGraph.bVisible = false
    end
	
    function Ob:onSelected(bSelected)
        if bSelected then
            self:setHostileMode(self.bHostileMode)
        end
    end
	
	function Ob:_getSelfEsteemString()
		local sLC = 'INSPEC132TEXT' -- "average"
		local nSelfEsteem = self.rCitizen:getAffinity(self.rCitizen.tStats.sUniqueID)
		for _,tLine in ipairs(Character.SELF_ESTEEM_LINE) do
			if nSelfEsteem >= tLine.nMin then
				sLC = tLine.linecode
			end
		end
		return g_LM.line(sLC)
	end
	
	function Ob:_getRoomString()
		local nRoomSatisfaction = self.rCitizen:getAverageRoomMorale() * 100
		local sLC
		-- reuse morale text range, for now
        for i, tTextInfo in ipairs(Character.MORALE_UI_TEXT) do
            if nRoomSatisfaction >= tTextInfo.nMinMorale then
                sLC = tTextInfo.linecode
            end
        end
		return g_LM.line(sLC)
	end
	
	function Ob:_getJobSatString()
		local nJob = self.rCitizen.tStats.nJob
		-- "N/A" if unassigned
		if nJob == Character.UNEMPLOYED then
			return g_LM.line('INSPEC079TEXT')
		end
		local nAff = self.rCitizen:getJobAffinity(nJob)
		-- affinity is -10 to 10, rebase to +/-100 to use morale text
		nAff = nAff * 10
		local sLC
        for i,tTextInfo in ipairs(Character.MORALE_UI_TEXT) do
            if nAff >= tTextInfo.nMinMorale then
                sLC = tTextInfo.linecode
            end
        end
		return g_LM.line(sLC)
	end
	
	function Ob:_getMoraleString()
		return ''
	end
	
    function Ob:_getNeedsString()
		-- JPL TODO: draw from a table mapping needs to linecodes?
		-- (not now; we may display needs data in some cooler way in the future)
		local s = ''
		local crit = Character.MORALE_NEEDS_LOW
		if self.rCitizen:getNeedValue('Duty') < crit then
			s = s .. g_LM.line('INSPEC071TEXT') .. ', '
		end
		if self.rCitizen:getNeedValue('Social') < crit then
			s = s .. g_LM.line('INSPEC073TEXT') .. ', '
		end
		if self.rCitizen:getNeedValue('Amusement') < crit then
			s = s .. g_LM.line('INSPEC074TEXT') .. ', '
		end
		if self.rCitizen:getNeedValue('Energy') < crit then
			s = s .. g_LM.line('INSPEC072TEXT') .. ', '
		end
		if self.rCitizen:getNeedValue('Hunger') < crit then
			s = s .. g_LM.line('INSPEC085TEXT')
		end        
		-- snip last comma if needed
		if s:find(',', -2) then
			s = s:sub(0, -3)
		end
		-- display "none" if everything's groovy
		if s == '' then
			s = g_LM.line('INSPEC075TEXT')
		end
        return s
    end
	
	function Ob:_getPersonalityString()
		-- -1/+1 threshold past which we consider a value interestingly high/low
		local nTraitThreshold = 0.3
		local nTraitsToShow = 2
		local tTraitsToShow = {}
		local tQuirksToShow = {}
		-- narrow down list of traits n quirks
		for k,_ in pairs(Character.PERSONALITY_TRAITS) do
			-- trait or quirk? (float or boolean)
			if string.find(k, 'b') == 1 then
				if self.rCitizen.tStats.tPersonality[k] == true then
					table.insert(tQuirksToShow, Character.QUIRK_LINE[k])
				end
			elseif string.find(k, 'n') == 1 then
				local nValue = self.rCitizen.tStats.tPersonality[k]
				-- normalize to easily sort by abs()
				nValue = (nValue - 0.5) * 2
				-- only show notably high or low values
				if nValue > nTraitThreshold or nValue < -nTraitThreshold then
					table.insert(tTraitsToShow, {sTrait=k, val=nValue})
				end
			end
		end
		-- sort and prune list of traits
		local f = function(x,y) return math.abs(x.val) > math.abs(y.val) end
		table.sort(tTraitsToShow, f)
		while #tTraitsToShow > nTraitsToShow do
			table.remove(tTraitsToShow, #tTraitsToShow)
		end
		-- build string from list
		local tItems = {}
		for _,tTrait in pairs(tTraitsToShow) do
			-- get magnitude adjective eg somewhat, very
			local sAdjLC
			for i,tAdj in ipairs(Character.PERSONALITY_ADJECTIVE_LINE) do
				if math.abs(tTrait.val) >= tAdj.nMin then
					sAdjLC = tAdj.linecode
				end
			end
			-- get word for trait, positive or negative
			local sTraitLC
			if tTrait.val > 0 then
				sTraitLC = Character.PERSONALITY_LINE[tTrait.sTrait].nHigh
			elseif tTrait.val < 0 then
				sTraitLC = Character.PERSONALITY_LINE[tTrait.sTrait].nLow
			end
			-- "empty" adjective: drop the extra space
			-- [for now: drop adjectives to keep string length down]
--[[
			if g_LM.line(sAdjLC) ~= '' then
				table.insert(tItems, g_LM.line(sAdjLC)..' '..g_LM.line(sTraitLC))
			end
]]--
			table.insert(tItems, g_LM.line(sTraitLC))
		end
		-- no remarkable traits found? booriing
		if #tItems == 0 then
			table.insert(tItems, g_LM.line('PERSON025TEXT'))
		end
		-- list quirks (simpler)
		for _,sQuirk in pairs(tQuirksToShow) do
			table.insert(tItems, g_LM.line(sQuirk))
		end
		return table.concat(tItems, ', ')
	end
	
    return Ob
end

function m.new(...)
    local Ob = m.create()
    Ob:init(...)

    return Ob
end

return m
