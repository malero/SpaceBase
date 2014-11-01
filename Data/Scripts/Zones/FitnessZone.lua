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

local FitnessZone = Class.create(Zone)

function FitnessZone:init(rRoom)
	Zone.init(self, rRoom)
    self.activityOptionList = ActivityOptionList.new(self)
    local tData = {
        targetLocationFn = function()
            if self.rRoom then
				return self.rRoom:randomLocInRoom(false,true,true)
			end
        end,
        --bInfinite=true,
    }
    self.activityOptionList:addOption(g_ActivityOption.new('WorkOutInGym',tData))
end

function FitnessZone:getActivityOptions(rChar, tObjects)
    tObjects = tObjects or {}
    table.insert(tObjects, self.activityOptionList:getListAsUtilityOptions())
    return tObjects
end

return FitnessZone
