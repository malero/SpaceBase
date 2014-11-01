local DFUtil = require("DFCommon.Util")
local DFMath = require("DFCommon.Math")
local UIElement = require('UI.UIElement')
local Character = require('CharacterConstants')
local Renderer = require('Renderer')
local World = require('World')
local Room = require('Room')
local Oxygen = require('Oxygen')
local ObjectList = require('ObjectList')
local Topics = require('Topics')
local DIM = require('DebugInfoManager')
local MiscUtil = require('MiscUtil')
local GameRules = require('GameRules')

local m = {}

m.sRule = '\n-----------------------------------------'

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())
    
    Ob.offsetX = 100
    Ob.offsetY = -20
    Ob.width = 500
    Ob.height = 600
    
    Ob.bgColor = {0.25, 0.25, 0.25, 0.5}
    Ob.textColor = {1, 1, 1, 1}
    
    function Ob:init(sRenderLayerName, rDebugObject)
        Ob.Parent.init(self, sRenderLayerName)
        
        -- the object or character we're displaying info for
        self.rDebugObject = rDebugObject
        self.text = "DEBUG"
        self:setLoc(self.offsetX, self.offsetY)
        -- (use of setScl for UIElements considered harmful! scale gets blown out for text elements)
        self.hintBox = self:addRect(self.width, self.height, unpack(self.bgColor))
        self.hintText = self:addTextToTexture(self.text, self.hintBox, "nevisSmallTitle")
        self.hintText:setLoc(0,0,5)
        self.hintText:setColor(unpack(self.textColor))
        
        local objType = ObjectList.getObjType(self.rDebugObject)
        -- attach to debug object
        if objType== 'Character' then
            self:setAttrLink( MOAITransform.INHERIT_TRANSFORM, rDebugObject, MOAITransform.TRANSFORM_TRAIT )
        elseif objType== 'Room' then
            local GameRules = require('GameRules')
			-- draw at center of room
			local cx, cy = World._getWorldFromTile(self.rDebugObject.nCenterTileX, self.rDebugObject.nCenterTileY)
            self:setLoc(cx, cy)
        elseif objType== ObjectList.ENVOBJECT then
			-- set loc rather than attach, else scale-flip affects the text
            --self:setAttrLink( MOAITransform.INHERIT_TRANSFORM, rDebugObject, MOAITransform.TRANSFORM_TRAIT )
			self:setLoc(self.rDebugObject:getLoc())
        end
    end
    
    function Ob:refresh()
        local objType = ObjectList.getObjType(self.rDebugObject)
        -- get text based on object type
        if objType == ObjectList.CHARACTER then
			-- pass in argument so other things (eg UI) can call these functions
            self.text = m.getCharacterDebugText(self.rDebugObject)
        elseif objType == ObjectList.ROOM then
            self.text = m.getRoomDebugText(self.rDebugObject)
        elseif objType == ObjectList.ENVOBJECT then
            self.text = m.getEnvObjectDebugText(self.rDebugObject)
        end
		self.hintText:setString(self.text)
		-- size box according to amount of text in it
		local numLines = self.hintText:getNumLines()
		self.height = numLines * 36
		self.hintBox:setScl(self.width, self.height)
    end
    
    return Ob
end

function m.new(...)
    local Ob = m.create()
    Ob:init(...)
    
    return Ob
end

function m.getCharacterTitleText(rChar)
	local s = string.format('%s (%s) (%s)', rChar.tStats.sName, rChar.tStats.sUniqueID, rChar.sSex)
	s = s .. '\n' .. m.getCharacterLocText(rChar)
	s = s .. m.getCharacterTaskText(rChar.rCurrentTask)
	s = s .. m.sRule
	return s
end

function m.getCharacterLocText(rChar)
	local x, y, z = rChar:getLoc()
    local tx,ty = g_World._getTileFromWorld(x,y)
	z = z or 0
	return string.format('LOC: %.1f, %.1f, %.1f (%i, %i)', x, y, z, tx, ty)
end

function m.getCharacterStatsText(rChar)
	local s = m.getCharacterTitleText(rChar)
	s = s .. '\nJOIN TIME: '
	if rChar.tStats.nJoinTime then
		s = s .. string.format('%.2f', rChar.tStats.nJoinTime)
		local GameRules = require('GameRules')
		local sJoinDate = GameRules.getStardateTotalDays(rChar.tStats.nJoinTime) .. "." .. GameRules.getStardateHour(rChar.tStats.nJoinTime)
		local nDays = GameRules.elapsedTime - rChar.tStats.nJoinTime
		nDays = math.floor(nDays / (60 * 24))
		s = s .. string.format(' (%s, %s days ago)', sJoinDate, nDays)
	else
		s = s .. '???'
	end
	--
	-- health, damage, etc
	--
	s = s .. '\nHEALTH: ' .. rChar:getHealth()
    local nHP,nMaxHP = rChar:getHP()
    s = s .. ' (' .. DFMath.roundDecimal(nHP, 0) .. '/' .. nMaxHP .. ')'
	s = s..'\nMALADIES: '
    if rChar.tStatus.tMaladies and next(rChar.tStatus.tMaladies) then
        for k,v in pairs(rChar.tStatus.tMaladies) do
            local nTimeToSymptoms = (v.nSymptomStart and string.format('%.2f', math.max(0, v.nSymptomStart - GameRules.elapsedTime))) or '?'
            local sTimeToContagious = (v.bContagious and 'true') or 'false'
            if not v.bContagious and v.nContagiousStart then
                sTimeToContagious = string.format('%.2f', math.max(0, v.nContagiousStart - GameRules.elapsedTime))
            end
            local nTimeToEnd = (v.nMaladyEnd and string.format('%.2f', v.nMaladyEnd - GameRules.elapsedTime)) or '?'
            s=s..'\n     '..k..' (Contagious: '..sTimeToContagious..', Symptoms: '..nTimeToSymptoms..', Ends: '..nTimeToEnd..')'
        end
    else
		s = s..'None'
	end
    s = s .. '\nSPEED: ' .. string.format('%.2f', rChar:getAdjustedSpeed())
    s = s .. '\nDAMAGE REDUCTION: ' .. DFMath.roundDecimal(rChar:currentDamageReductionValue(), 2)*100 .. '%  (TeamTactics: '..rChar:_getTeamTacticsCount()..')'
    s = s .. '\nTOUGHNESS: ' .. DFMath.roundDecimal(rChar.tStats.nToughness, 2)
    s = s .. '\nARMOR: ' .. DFMath.roundDecimal(rChar:currentArmorValue(), 2)
	--
	-- oxygen
	--
	s = s .. m.sRule
    s = s .. '\nAVERAGE OXYGEN: ' .. DFMath.roundDecimal(rChar.nAverageOxygen, 2)
	s = s .. '\nSUFFOCATION: ' .. rChar.tStatus.suffocationTime .. '/' .. Character.OXYGEN_SUFFOCATION_UNTIL_DEATH
    s = s .. string.format('\nSUIT OXYGEN: %.2fs', rChar.tStatus.suitOxygen / Character.OXYGEN_PER_SECOND)
    if rChar:spacewalking() then
		s = s .. '\n  (spacewalking'..((rChar:isElevated() and ', elevated)') or ')')
	end
	-- hunger
	s = s .. '\nStarvation: '..math.floor(rChar.tStatus.nStarveTime)..'/'..Character.TIME_BEFORE_STARVATION
	s = s .. m.sRule
	s = s .. '\nPERSONALITY: '
    s = s .. '\n  Self-esteem: ' .. rChar:getAffinity(rChar.tStats.sUniqueID)
    -- sort this list alphabetically to make it readable
    local tTraits = {}
    for n in pairs(Character.PERSONALITY_TRAITS) do
        table.insert(tTraits, n)
    end
    table.sort(tTraits)
	for _,trait in pairs(tTraits) do
        if string.find(trait, 'n') == 1 then
            s = s .. string.format('\n  %s: %.2f', MiscUtil.padString(trait, 15), rChar.tStats.tPersonality[trait])
        else
            s = s .. string.format('\n  %s: %s', MiscUtil.padString(trait, 15), rChar.tStats.tPersonality[trait])
        end
	end
	s = s .. m.sRule
	s = s .. '\nDUTY: ' .. g_LM.line(Character.JOB_NAMES_CAPS[rChar.tStats.nJob])
	s = s .. '\nSKILL MORALE MODIFIER: ' .. rChar:getMoraleCompetencyModifier()
	s = s .. '\nSKILLS: '
	for _,job in pairs(Character.DISPLAY_JOBS) do
		if job ~= Character.UNEMPLOYED then
			local sJob = g_LM.line(Character.JOB_NAMES_CAPS[job])
			sJob = MiscUtil.padString(sJob, 12)
			local nCompetence = rChar.tStats.tJobCompetency[job]
			local nLevel = rChar:getCurrentLevelByJob(job)
			local nXP = math.floor(rChar.tStats.tJobExperience[job])
			s = s .. string.format('\n  %s: %i  lvl %s (%s xp)', sJob, nCompetence, nLevel, nXP)
		end
	end
	return s
end

function m.getCharacterTaskText(rTask)
	local task = 'NONE'
	if rTask then
		task = rTask.activityName
		local target = rTask.rTarget
		if not target then
			target = rTask.rTargetObject
		end
		if target then
			local objType = ObjectList.getObjType(target)
			if objType == ObjectList.CHARACTER then
				task = task .. ' @ ' .. target.tStats.sUniqueID
			elseif objType == ObjectList.ROOM then
				task = task .. ' @ ' .. target.uniqueZoneName
			elseif objType == ObjectList.ENVOBJECT then
				if target.sUniqueName then
					task = task .. ' @ ' .. target.sUniqueName
				elseif target.sFriendlyName then
					task = task .. ' @ ' .. target.sFriendlyName
				elseif target.sName then
					task = task .. ' @ ' .. target.sName
				end
			end
		end
        if rTask:getLeafTask() ~= rTask then
            task = task .. ' -- LEAF: ' .. rTask:getLeafTask().activityName
        end
	end
	local s = '\nTASK: ' .. task
	if rTask and rTask.duration then
		s = s .. ' for ' .. string.format('%.1f', rTask.duration) .. 's'
	end
	return s
end

function m.getCharacterMoraleText(rChar)
	local s = m.getCharacterTitleText(rChar)
	s = s .. '\nNEEDS:'
	for need,value in pairs(rChar.tNeeds) do
        if type(value) ~= 'table' then
            s = s .. '\n ' .. MiscUtil.padString(need, 10) .. ': ' .. tostring(value)
        end
	end
	
	s = s .. m.sRule
	local nNeedsAvg = rChar.tStats.nAllNeedsAverage or '???'
	s = s .. '\nNEEDS AVG: ' .. nNeedsAvg
	s = s .. '\nMORALE: ' .. rChar.tStats.nMorale
	s = s .. '\nANGER: ' .. rChar.tStatus.nAnger
	s = s .. '\nAverage room satisfaction: ' .. rChar:getAverageRoomMorale() / Character.MAX_ROOM_MORALE_BOOST
    s = s .. '\nRecent morale events:'
    if not rChar.tStats.tHistory.tMoraleEvents then
        return s
    end
    local t = {}
    -- reverse list (most recent first)
    for i,v in ipairs(rChar.tStats.tHistory.tMoraleEvents) do
        t[i] = rChar.tStats.tHistory.tMoraleEvents[#rChar.tStats.tHistory.tMoraleEvents - i + 1]
    end
    for _,entry in pairs(t) do
        local reason = MiscUtil.padString(entry.reason, 17, false)
        local amt = string.format('%.7f', entry.amount)
        if entry.amount > 0 then
            amt = '+' .. amt
        end
		-- don't log 0 events
		if entry.amount ~= 0 then
			s = s .. string.format('\n  %s %s %s', entry.time, reason, amt)
		end
    end
	
	return s
end

function m.getCharacterAffinityText(rChar)
	local s = m.getCharacterTitleText(rChar)
	for category,_ in pairs(Topics.TopicList) do
		s = s .. string.format('\n%s:', category)
		local tAff = rChar:getSortedAffinityList(category)
		for _,t in ipairs(tAff) do
			local name = MiscUtil.padString(t.name, 34)
			local aff = MiscUtil.padString(tostring(t.aff), 3)
			s = s .. string.format('\n  %s: %s', name, aff)
            -- also show familiarity for people
            if category == 'People' then
                local fam = rChar.tFamiliarity[t.id]
                if not fam then
                    fam = 'n/a'
                end
                s = s .. '  Familiarity: ' .. fam
            end
		end
	end
	return s
end

function m.getCharacterDecisionText(rChar)
	local s = m.getCharacterTitleText(rChar)
	if rChar.lastDecisionLog then
		s = s .. '\n\n\nLast decision for ' .. rChar.tStats.sUniqueID .. ':\n'
		s = s .. rChar.lastDecisionLog
	end
	return s
end

function m.getCharacterTaskHistoryText(rChar)
	local s = m.getCharacterTitleText(rChar)
	s = s..'\n\n\n'
	if not rChar.tStats.tHistory.tTaskLog then
		return s .. '[NO TASK LOG FOUND]'
	end
	s = s .. 'Task history:'
    -- reverse list (most recent first)
	local t = {}
    for i,v in ipairs(rChar.tStats.tHistory.tTaskLog) do
        t[i] = rChar.tStats.tHistory.tTaskLog[#rChar.tStats.tHistory.tTaskLog - i + 1]
    end
	for i,task in pairs(t) do
		s = s..'\n'..MiscUtil.padString(task.time, 13)
		s = s..': '..task.sTaskName
		if not task.bSuccess then
			if task.sInterruptReason then
				s = s..' (INTERRUPTED: '..task.sInterruptReason..')'
			else
				s = s..' (FAILED)'
			end
		end
	end
	return s
end

function m.getCharacterDebugText(rChar)
	if DIM.nDebugInfoPage == DIM.kDEBUG_PAGE_STATS then
		return m.getCharacterStatsText(rChar)
	elseif DIM.nDebugInfoPage == DIM.kDEBUG_PAGE_MORALE_NEEDS then
		return m.getCharacterMoraleText(rChar)
	elseif DIM.nDebugInfoPage == DIM.kDEBUG_PAGE_AFFINITY then
		return m.getCharacterAffinityText(rChar)
	elseif DIM.nDebugInfoPage == DIM.kDEBUG_PAGE_DECISION then
		return m.getCharacterDecisionText(rChar)
	elseif DIM.nDebugInfoPage == DIM.kDEBUG_PAGE_TASK then
		return m.getCharacterTaskHistoryText(rChar)
	end
end

function m.getRoomDebugText(rRoom)
    local numWalls = 0
    for addr,_ in pairs(rRoom.tWalls) do
        numWalls = numWalls+1
    end
    local numDoors = 0
    for addr,_ in pairs(rRoom.tDoors) do
        numDoors = numDoors+1
    end
    local tAdjoining = rRoom:getAdjoiningRooms()
    local sAdjoining = ""
    for _,nAdjoiningID in pairs(tAdjoining) do
        sAdjoining = sAdjoining .. (nAdjoiningID..", ")
    end

	local text = 'ROOM ' .. rRoom.id
	text = text .. '\nName: ' .. rRoom.uniqueZoneName
	text = text .. '\nID: ' .. rRoom.id
    if rRoom.bBreach then
        text = text .. '\n   BREACHED'
    end
    if rRoom:isDangerous() then
        text = text .. '\n   Dangerous'
    end
	text = text .. '\nZone: ' .. rRoom:getZoneName()
	text = text .. '\nSize: ' .. rRoom:getSize()
	text = text .. '\nWalls: ' .. numWalls
	text = text .. '\nDoors: ' .. numDoors
	text = text .. '\nAdjacentTo: ' .. sAdjoining
	local _,nOccupants = rRoom:getCharactersInRoom()
	text = text .. '\nOccupants: ' .. nOccupants
    if rRoom.nMoraleScore then
        text = text .. '\nMorale score: ' .. rRoom.nMoraleScore
    end
    local o2score,o2total,o2avg = rRoom:getOxygenScore()
	text = text .. '\nOxygen: Score: ' .. string.format('%.2f', o2score)
	text = text .. ' Total: ' .. string.format('%.2f', o2total)
	text = text .. ' Avg: '.. string.format('%.2f', o2avg)
--	text = text .. ' Last give: '..(string.format('%.2f', (rRoom.nLastGive or 0)) or '0')
	local numObjects = 0
	for k,v in pairs(rRoom.tProps) do
		numObjects = numObjects + 1
	end
	text = text .. '\nPower draw: ' .. rRoom.nPowerDraw or 'n/a'
	text = text .. '\nPower supplied: ' .. rRoom.nPowerSupplied or 'n/a'
	text = text .. '\n# of EnvObjects: ' .. numObjects
	if rRoom.bBurning then
		text = text .. '\nBurning!'
	end
    if rRoom.zoneName == 'AIRLOCK' then
        text = text .. '\nAirlock: '
        text = text .. ((rRoom.zoneObj.bFunctional and 'functional') or 'non-functional')
        if rRoom.zoneObj.bRunning then text = text..'; running' end
    end
    local nOutput = rRoom.zoneObj:getPowerOutput()
    if nOutput > 0 then
        text = text .. '\nPowering:       grant / draw (requested) '
        local nTotalRequest = 0
        local nTotalGrant = 0
        local sLongText = ''
        for i,rProp in ipairs(rRoom.zoneObj.tOrderedThingsPowered) do
            local tPowerInfo = rRoom.zoneObj.tThingsPowered[rProp]
            if rProp:getPowerDraw() > 0 then
                sLongText = sLongText .. '\n    ' .. rProp:getUniqueName() .. ': '..tPowerInfo.nPowerGranted .. '/' .. rProp:getPowerDraw() .. '('..tPowerInfo.nPowerRequested..')'
                nTotalRequest = nTotalRequest+tPowerInfo.nPowerRequested
                nTotalGrant = nTotalGrant+tPowerInfo.nPowerGranted
            end
        end
        text = text .. '\n  TOTAL: '..nTotalGrant..'/'..nOutput..'/'..nTotalRequest..'  (grant / output / request)'
        text = text .. sLongText
    end
	return text
end

function m.getEnvObjectDebugText(rObj)
	local text = ''
	if rObj.sFriendlyName then
		text = text .. rObj.sFriendlyName
    end
	if rObj.sUniqueName then
		text = text .. ' (' .. rObj.sUniqueName .. ')'
	end
    if rObj.tParams and rObj.tParams.spawnerName then
        text = text .. ": " .. rObj.tParams.spawnerName
    end
	local x, y = rObj:getLoc()
    local tx,ty = g_World._getTileFromWorld(x,y)
	text = text .. string.format('\nLOC: %.1f, %.1f, (%i, %i)', x, y, tx, ty)
	text = text .. string.format('\nActive: %s', rObj.bActive)
	text = text .. string.format('\nFlipX: %s', rObj.bFlipX)
	text = text .. string.format('\nFlipY: %s', rObj.bFlipY)
	text = text .. '\nRoom: '
	local rRoom = rObj:getRoom()
	if rRoom and rRoom.id and rRoom.uniqueZoneName then
		text = text .. rRoom.uniqueZoneName..' ('..rRoom.id..')'
	else
		text = text .. '???'
	end
	text = text .. '\nPower draw: '
	if rObj.tData.nPowerDraw then
		text = text .. rObj.tData.nPowerDraw
	else
		text = text .. 0
	end
	text = text .. '\nCondition: ' .. rObj.nCondition
    if rObj.tMaladies and next(rObj.tMaladies) then
        text = text..'\nMALADIES: '
        for sName,tMaladyData in pairs(rObj.tMaladies) do
            local nTimeToEnd = math.max(0, tMaladyData.nEndTime - GameRules.elapsedTime)
            text = sName..' ('..nTimeToEnd..'), '
        end
        text = text..'\n'
    end
	text = text .. '\nDecay Rate: ' .. rObj.decayPerSecond
	-- special plant info
	if rObj.sPlantName then
		text = text .. '\nPlant Type: ' .. rObj.sPlantName
		if rObj.bSeeded then
			text = text .. '\nPlant Health: ' .. rObj.nPlantHealth
			text = text .. '\nPlant Age: '..math.floor(rObj.nPlantAge)..'/'..rObj.rPlantData.nLifeTime
		end
	end
	local builder = rObj.sBuilderName or 'UNKNOWN'
	text = text .. '\nBuilder: ' .. builder
	local buildtime = rObj.sBuildTime or 'UNKNOWN'
	text = text .. '\nBuild Date: ' .. buildtime
	local maintainer = rObj.sLastMaintainer or 'UNKNOWN'
	text = text .. '\nLast Maintained By: ' .. maintainer
	local lastmaint = rObj.sLastMaintainTime or 'UNKNOWN'
	text = text .. '\nLast Maintained: ' .. lastmaint
    if rObj.sName == 'Door' or rObj.sName == 'Airlock' or rObj.sName == 'HeavyDoor' then
        local sOperation
        local sState
        local Door=require('EnvObjects.Door')
        if rObj.operation == Door.operations.LOCKED then sOperation='locked'
        elseif rObj.operation == Door.operations.FORCED_OPEN then sOperation='forced open'
        else sOperation='normal' end
        
        if rObj.doorState == Door.doorStates.OPEN then sState='open'
        elseif rObj.doorState == Door.doorStates.CLOSED then sState='closed'
        elseif rObj.doorState == Door.doorStates.LOCKED then sState='locked'
        elseif rObj.doorState == Door.doorStates.BROKEN_OPEN then sState='broken open'
        elseif rObj.doorState == Door.doorStates.BROKEN_CLOSED then sState='broken closed' end
        text = text .. '\nOperation: ' .. sOperation .. ' State: '..sState
    end
	if rObj:slatedForTeardown(true) then
		text = text .. '\nSLATED FOR RESEARCH'
	end
	
	if rObj.nAngle then
		text = text .. '\nAngle: ' .. rObj.nAngle
	end
	if rObj.sLastTargetFiredAtID then
		text = text .. '\nLast Target: ' .. rObj.sLastTargetFiredAtID
	end
	return text
end

return m
