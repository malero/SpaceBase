local Task=require('Utility.Task')
local Class=require('Class')
local World=require('World')
local Log=require('Log')
local GameRules=require('GameRules')

local PickUpFloorItem = Class.create(Task)

PickUpFloorItem.PICKUP_DURATION = 1
--PickUpFloorItem.emoticon = 'work'

function PickUpFloorItem:init(rChar,tPromisedNeeds,rActivityOption)
    self.super.init(self,rChar,tPromisedNeeds,rActivityOption)
    self.nDuration = PickUpFloorItem.PICKUP_DURATION
    self.rTargetObject = rActivityOption.tData.rTargetObject
    self.sObjectKey = rActivityOption.tData.sObjectKey
    self:setPath(rActivityOption.tBlackboard.tPath)
end

function PickUpFloorItem:onUpdate(dt)
    if self.rTargetObject.bDestroyed then
        self:interrupt("item destroyed")
        return
    end
    if self.sObjectKey and not self.rTargetObject.tInventory[self.sObjectKey] then
        self:interrupt("object no longer holds target item")
        return
    end

    if self:interacting() then
        if self:tickInteraction(dt) then
            local tItem = self.rTargetObject:transferItemTo(self.rChar, self.sObjectKey)
            assertdev(tItem)
			-- spaceface about picking up a thing maybe
			-- if thing we're picking up has tags we like, mention it
			local _,tFavTag = self.rChar:getMostLikedTag(tItem)
			if tFavTag then
				local tLogData = {
					sPickupItem = self.sObjectKey,
					sFavTag = g_LM.line(tFavTag.lc),
				}
				Log.add(Log.tTypes.PICKUP_ITEM, self.rChar, tLogData)
			end
            return true
        end
    elseif self.tPath then
        self:tickWalk(dt)
    else
        local tx,ty = g_World._getTileFromWorld(self.rTargetObject:getLoc())
        if self:attemptInteractWithTile('interact',tx,ty,self.nDuration) then
            -- nothing
        else
            self:interrupt('Unable to reach target item.')
        end
    end
end

return PickUpFloorItem
