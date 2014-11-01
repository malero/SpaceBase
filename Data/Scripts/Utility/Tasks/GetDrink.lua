local Task=require('Utility.Task')
local World=require('World')
local Class=require('Class')
local Room=require('Room')
local Malady=require('Malady')
local Log=require('Log')
local CharacterConstants=require('CharacterConstants')

local GetDrink = Class.create(Task)

GetDrink.emoticon = 'beer'

GetDrink.DURATION_MIN = 8
GetDrink.DURATION_MAX = 18

function GetDrink:init(rChar,tPromisedNeeds,rActivityOption)
    Task.init(self, rChar, tPromisedNeeds, rActivityOption)
    self.duration = math.random(GetDrink.DURATION_MIN, GetDrink.DURATION_MAX)
    self.bInterruptOnPathFailure = true
    self:setPath(rActivityOption.tBlackboard.tPath)
    self.pathTargetX,self.pathTargetY = rActivityOption.tBlackboard.tileX,rActivityOption.tBlackboard.tileY
    self.rBar = rActivityOption.tData.rBar
    self.nBarSlot = rActivityOption.tData.nBarSlot
    local dir = self.rBar:getFacing()
    self.nBarTX,self.nBarTY = rActivityOption.tData.barTX,rActivityOption.tData.barTY
end

function GetDrink:drinkServed()
    self:_receiveDrink()
end

function GetDrink:_waitForDrink()
    self:attemptInteractWithTile('breathe', self.nBarTX,self.nBarTY, 1)
    self.bWaitingForDrink = true
    self.rBar:waitingForDrink(self,self.nBarSlot,true)
end

function GetDrink:_receiveDrink()
    Malady.interactedWith(self.rChar,self.rBar)
    self.bReceivedDrink=true
    self.nDrinkingDuration = self.duration
    self.bWaitingForDrink=false
    local rRoom = self.rChar:getRoom()
    if rRoom and rRoom ~= Room.getSpaceRoom() then
        local cx,cy = self.rChar:getLoc()
        local tx,ty = self.rChar:getNearbyTile()
        if tx then
            local wx,wy = g_World._getWorldFromTile(tx,ty)
            self.bInterruptOnPathFailure = false
            self:createPath(cx,cy,wx,wy)
        end
    end
    if self.tPath then
    else
        self:_drinkInPlace()
    end
end

function GetDrink:onComplete(bSuccess)
    Task.onComplete(self,bSuccess)
    self.rBar:waitingForDrink(self,self.nBarSlot,false)
end

function GetDrink:_drinkInPlace()
    local tx,ty = self.rChar:getTileLoc()
    self:attemptInteractWithTile('drinkbooze', tx,ty, math.random(5,10))

    if not self.bLogged then
        if self.rChar:getRoom() and self.rChar:getRoom() ~= Room.getSpaceRoom() then
	        local tLogData = {
		        sLinkTarget = self.rChar:getRoom() and self.rChar:getRoom().id,
	        }
	        local logType = Log.tTypes.DRINK_GOOD_MORALE
	        if self.rChar.tStats.nMorale < 0 then
		        logType = Log.tTypes.DRINK_BAD_MORALE
	        end
	        Log.add(logType, self.rChar, tLogData)
        end
        self.bLogged = true
    end
end

function GetDrink:onUpdate(dt)
    if self.nDrinkingDuration then
        self.nDrinkingDuration = self.nDrinkingDuration - dt
    end

    if self:interacting() then
        self:tickInteraction(dt)
    elseif self.nDrinkingDuration and self.nDrinkingDuration < 0 then
        return true
    elseif self.bWaitingForDrink then
        if self.rBar:getWaiter(self.nBarSlot) ~= self then
            self:interrupt('we got bumped from our drink slot')
        elseif self.bReceivedDrink then
            self:_startDrinking()
        elseif not self.rBar:isActive(self.rChar) then
            self:interrupt('bar stopped existing or being tended')
        end
    elseif self:tickWalk(dt) then
        if self.nDrinkingDuration then
            self:_drinkInPlace()
        else
            self:_waitForDrink()
        end
	end
end

return GetDrink
