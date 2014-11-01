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

local Pub = Class.create(Zone)

function Pub:init(rRoom)
    self.nBartenders=0
    self.tBartenders={}
    self.nBars=0
	Zone.init(self, rRoom)
    self.activityOptionList = ActivityOptionList.new(self)
    local tData = {
        targetLocationFn = function() 
            if self.rRoom then return self.rRoom:randomLocInRoom(false,true,true) end
        end,
        bInfinite=true,
        rPub=self,
    }
    self.activityOptionList:addOption( g_ActivityOption.new('MaintainPub',tData) )

    tData = {
        targetLocationFn = function() 
            if self.rRoom then return self.rRoom:randomLocInRoom(false,true,true) end
        end,
        bInfinite=true,
        utilityGateFn=function() return not self:hasBarTender(), 'pub already open' end,
        rPub=self,
    }
    self.activityOptionList:addOption( g_ActivityOption.new('OpenPub',tData) )

end

function Pub:onTick(dt)
    Zone.onTick(self,dt)
	self:_updateJobList()
end

function Pub:getCapacity()
    if not self:hasBarTender() then return 0 end
	-- returns # of people who can safely(?) fit in here
	return self.rRoom:getSize() / Character.PUB_CAPACITY + self:getTotalBarTenders() * Character.PUB_CITIZENS_PER_BARTENDER
end

function Pub:atCapacity()
	local _,nOccupants = self.rRoom:getCharactersInRoom()
	return nOccupants-self:getTotalBarTenders() >= self:getCapacity()
end

function Pub:hasBar()
    return self.nBars > 0
end

function Pub:hasBarTender(rNotThisDude)
    if not self:hasBar() then return false end
    
    if rNotThisDude and self.tBartenders[rNotThisDude] then return self.nBartenders > 1 end

    return self.nBartenders > 0
end

function Pub:getTotalBarTenders()
    return self.nBartenders
end

function Pub:_updateJobList()
    self.nBartenders = 0
    self.tBartenders = {}
    local rChars = self.rRoom:getCharactersInRoom()
    for rChar,_ in pairs(rChars) do
        if rChar:getJob() == Character.BARTENDER and rChar:wantsWorkShiftTask() then
            if rChar:getRoom() ~= self.rRoom then
                Print(TT_Warning, 'Bartender is both in the room and not in the room.')
            end
            self.nBartenders = self.nBartenders+1
            self.tBartenders[rChar] = true
        end
    end
    local _, nBars = self.rRoom:getPropsOfName('Bar')
    self.nBars = nBars
end

function Pub:getActivityOptions(rChar, tObjects)
    tObjects = tObjects or {}
    table.insert(tObjects, self.activityOptionList:getListAsUtilityOptions())
    return tObjects
end

return Pub
