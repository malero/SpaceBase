local ObjectList=require('ObjectList')
local Class=require('Class')
local MiscUtil=require('MiscUtil')
local Zone=require('Zones.Zone')
local Room=require('Room')
local Base=require('Base')
local ActivityOptionList=require('Utility.ActivityOptionList')
g_ActivityOption=g_ActivityOption or require('Utility.ActivityOption')
local GameRules=require('GameRules')
local Character=require('CharacterConstants')
local World=require('World')

local BedZone = Class.create(Zone)

function BedZone:init(rRoom)
	Zone.init(self, rRoom)
    self.tAssignmentSlots = {}
end

function BedZone:getAssignmentSlots()
    if self.lastCheckTime and GameRules.elapsedTime-self.lastCheckTime < 1 then
        return self.tAssignmentSlots,self.nAssigned
    end

    self.tAssignmentSlots = {}
    self.nAssigned=0
    local tBeds = self.rRoom:getPropsOfName('Bed')
    for rBed,_ in pairs(tBeds) do
        local bedTag = ObjectList.getTag(rBed)
        local sUniqueID = rBed:getUniqueID() -- just for sorting.
        if bedTag and sUniqueID then
            table.insert(self.tAssignmentSlots, {bed=bedTag,sUniqueID=sUniqueID})
        end
    end
    table.sort(self.tAssignmentSlots, function(a,b) 
        return a.sUniqueID > b.sUniqueID
    end)

    self.lastCheckTime=GameRules.elapsedTime

    return self.tAssignmentSlots,self.nAssigned
end

function BedZone:assignChar(nSlotIdx,rChar)
    if rChar and not rChar:isPlayersTeam() then rChar = nil end
    
    local t = self.tAssignmentSlots[nSlotIdx]
    if not t or not t.bed then return end
    local rBed = ObjectList.getObject(t.bed)
    if not rBed then return end
    Base.assignBed(rChar,rBed)
end

function BedZone:isCharAssigned(rChar)
    local tBeds = self.rRoom:getPropsOfName('Bed')
    for rBed,_ in pairs(tBeds) do
        if Base.tBedToChar[rBed.tag] == rChar then return true end
    end
    return false
end

-- return: {rChar=1,rChar=1,...}, nAssignedBeds, nUnassignedBeds
--[[
function BedZone:getAssignedChars()
    if self.lastCheckTime and GameRules.elapsedTime-self.lastCheckTime < 1 then
        return self.tCharsLast,self.nAssignedLast,self.nUnassignedLast
    end

    local tBeds = self:getPropsOfName('Bed')
    local tChars={}
    local nAssigned=0
    local nUnassigned=0
    for rBed,_ in pairs(tBeds) do
        local rOwner = rBed:getOwner()
        if rOwner then 
            tChars[rOwner] = 1 
            nAssigned=nAssigned+1
        else
            nUnassigned=nUnassigned+1
        end
    end
    self.tCharsLast=tChars
    self.nAssignedLast=nAssigned
    self.nUnassignedLast=nUnassigned
    self.lastCheckTime=GameRules.elapsedTime
    return tChars,nAssigned,nUnassigned
end
]]--

return BedZone
