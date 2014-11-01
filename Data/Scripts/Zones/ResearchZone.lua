local ObjectList=require('ObjectList')
local Class=require('Class')
local MiscUtil=require('MiscUtil')
local Zone=require('Zones.Zone')
local Room=require('Room')
local ActivityOptionList=require('Utility.ActivityOptionList')
g_ActivityOption=g_ActivityOption or require('Utility.ActivityOption')
local GameRules=require('GameRules')
local Character=require('CharacterConstants')
local World=require('World')
local Base=require('Base')

local ResearchZone = Class.create(Zone)

ResearchZone.sZoneInspector = 'ZoneResearchPane'

function ResearchZone:init(rRoom)
	Zone.init(self, rRoom)
end

function ResearchZone:setActiveResearch(sKey)
    -- tell hint system player knows how to research a thing
    if not GameRules.bHasStartedResearch then
        GameRules.bHasStartedResearch = true
    end
    self.sCurrentResearch = sKey
end

function ResearchZone:getSaveTable()
    local t = {}
    t.sCurrentResearch = self.sCurrentResearch
    return t
end

function ResearchZone:initFromSaveTable(t)
    self:setActiveResearch(t.sCurrentResearch)
end

function ResearchZone:getActiveResearch()
    return self.sCurrentResearch
end

function ResearchZone:getResearchStatus()
    return self.sCurrentResearch
end

function ResearchZone:onTick(dt)
    Zone.onTick(self,dt)
    if self.sCurrentResearch and not Base.canResearch(self.sCurrentResearch) then
        self.sCurrentResearch = nil
    end
end

return ResearchZone
