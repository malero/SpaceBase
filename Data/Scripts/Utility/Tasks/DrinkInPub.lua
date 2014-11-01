local Task=require('Utility.Task')
local World=require('World')
local Class=require('Class')
local Room=require('Room')
local Log=require('Log')
local CharacterConstants=require('CharacterConstants')

local DrinkInPub = Class.create(Task)

DrinkInPub.emoticon = 'beer'

DrinkInPub.DURATION_MIN = 8
DrinkInPub.DURATION_MAX = 18

function DrinkInPub:init(rChar,tPromisedNeeds,rActivityOption)
    Task.init(self, rChar, tPromisedNeeds, rActivityOption)
	self.pathX, self.pathY = rActivityOption.tData.pathX, rActivityOption.tData.pathY
    self.duration = math.random(DrinkInPub.DURATION_MIN, DrinkInPub.DURATION_MAX)
    self.bInterruptOnPathFailure = true
	self:_walk()
end

function DrinkInPub:_drink()
    self.rChar:playAnim('drinkbooze')
	self.bDrinking = true
	-- spaceface when starting to drink
	local tLogData = {
		sLinkTarget = self.rChar:getRoom() and self.rChar:getRoom().id,
	}
	local logType = Log.tTypes.DRINK_GOOD_MORALE
	if self.rChar.tStats.nMorale < 0 then
		logType = Log.tTypes.DRINK_BAD_MORALE
	end
	Log.add(logType, self.rChar, tLogData)
end

function DrinkInPub:_walk()
    local cx,cy = self.rChar:getLoc()
    self:createPath(cx, cy, self.pathX, self.pathY)
end

function DrinkInPub:onUpdate(dt)
    if self.duration < 0 then
		-- JPL TODO: bonus based on affinity for drink + bartender skill
		local nBonus = math.random(CharacterConstants.MORALE_DRANK_BASE, CharacterConstants.MORALE_DRANK_MAX)
		self.rChar:alterMorale(nBonus, 'DrankInPub')
        return true
    end
	if self:tickWalk(dt) and not self.bDrinking then
		self:_drink()
	end
	if self.bDrinking then
		self.duration = self.duration - dt
	end
end

return DrinkInPub
