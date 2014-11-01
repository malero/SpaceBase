local Task=require('Utility.Task')
local World=require('World')
local Class=require('Class')
local Inventory=require('Inventory')
local ObjectList=require('ObjectList')
local Room=require('Room')
local Log=require('Log')
local Pickup=require('Pickups.Pickup')
local Character=require('CharacterConstants')
local Topics=require('Topics')

local ServeFoodAtTable = Class.create(Task)

ServeFoodAtTable.emoticon = 'beer'

ServeFoodAtTable.DURATION_MIN = 8
ServeFoodAtTable.DURATION_MAX = 18

function ServeFoodAtTable:init(rChar,tPromisedNeeds,rActivityOption)
    Task.init(self, rChar, tPromisedNeeds, rActivityOption)

    self.duration = math.random(ServeFoodAtTable.DURATION_MIN, ServeFoodAtTable.DURATION_MAX)
    if self.rChar:heldItem() and self.rChar:heldItem().sTemplate == 'CookedMeal' then
        self:_pathToStove()
    else
        self:setPath(rActivityOption.tBlackboard.tPath)
        self.pathTargetWX,self.pathTargetWY = rActivityOption.tBlackboard.nPathEndWX,rActivityOption.tBlackboard.nPathEndWY
        self.pathTargetTX,self.pathTargetTY = g_World._getTileFromWorld(self.pathTargetWX,self.pathTargetWY)
        self.rTable = rActivityOption.tData.rTable
        self.nTableTX,self.nTableTY = rActivityOption.tData.tableTX,rActivityOption.tData.tableTY
        self.sDest = 'Fridge'
        self.rFridge = ObjectList.getObjAtTile(self.pathTargetTX,self.pathTargetTY,ObjectList.ENVOBJECT) --,'Fridge')
        if self.rFridge and self.rFridge.sFunctionality ~= 'Fridge' then
            self.rFridge = nil
        end
        if not self.rFridge then
            self:interrupt('Bartender unable to find fridge.')
        end
    end
end

function ServeFoodAtTable:_pathToStove()
	local rStove = self.rTable:getStove()
	if not rStove then
		self:interrupt('Lost stove.')
		return
	end
	if not self:createPathTo(rStove,rStove:getFacing()) then
		if not self:createPathTo(rStove) then
			self:interrupt('cannot path to stove')
			return
		end
	end
	self.pathTargetTX,self.pathTargetTY = rStove:getTileLoc()
	self.sDest = 'Stove'
end

function ServeFoodAtTable:onUpdate(dt)
    if not self.rTable:isActive(self.sDest == 'Fridge') then
        self:interrupt('PubTable no longer active')
        return
    end

    if self:interacting() then
        if self:tickInteraction(dt) then
            if self.sDest == 'Fridge' then
				if not self.rFridge:isFunctioning() then
					self:interrupt('Fridge stopped functioning.')
					return
				end
                local sName = self.rFridge:hasFood()
                if not sName then
                    self:interrupt('Fridge ran out of food.')
                    return
                end
                local tItem = self.rFridge:transferItemTo(self.rChar,sName,1)
                assertdev(tItem)
                self:_pathToStove()
            elseif self.sDest == 'Stove' then
				if self.rTable then
					local rStove = self.rTable:getStove()
					if not rStove:isFunctioning() then
						self:interrupt('Stove stopped functioning.')
						return
					end
				end
				-- pick meal from existing names, place in CookedMeal container
				-- (meal is a key in Topics.tTopics)
				local sRandomTopic = Topics.getRandomTopic('Foods')
                local sFoodName = Topics.tTopics[sRandomTopic].name
				local tMealItem = Inventory.createItem('CookedMeal', {sName=sFoodName, sTopicID=sRandomTopic})
				-- remember who cooked this meal
				tMealItem.sCreatorID = self.rChar.tStats.sUniqueID
                self.rChar:pickUpItem(tMealItem,true)
                if not self:createPathTo(self.rTable,g_World.directions.SE) then
                    self:interrupt('cannot path to PubTable')
                    return
                end
                self.pathTargetTX,self.pathTargetTY = self.rTable:getTileLoc()
                self.sDest = 'PubTable'
            elseif self.sDest == 'PubTable' then
				-- other stuff happens in onComplete below
                return true
            end
        end
    elseif self:tickWalk(dt) then
        local sAnim
        if self.sDest == 'Fridge' then
            sAnim = 'fridge'
        elseif self.sDest == 'Stove' then
            self.rChar:destroyItem(self.rChar:heldItemName())
            sAnim = 'cook'
        elseif self.sDest == 'PubTable' then
            sAnim = 'interact'
        end

        if not self:attemptInteractWithTile(sAnim, self.pathTargetTX,self.pathTargetTY, 1, true) then
            self:interrupt('Failed to interact with '..self.sDest)
            return
        end
    end
end

function ServeFoodAtTable:onComplete(bSuccess)
    Task.onComplete(self,bSuccess)
	-- increment "meals served"
	if bSuccess then
		require('Base').incrementStat('nMealsServed')
	end
	-- placing food on table = adding "dropped" item to its inventory
    local tItem
    if bSuccess and self.rChar:heldItemName() then
        tItem = self.rChar:transferItemTo(self.rTable, self.rChar:heldItemName())
    end
	if tItem then
		self.rChar:alterMorale(Character.MORALE_SERVED_MEAL, 'ServedMeal')
		-- JPL TODO: increase server/diner familiarity by Character.FAMILIARITY_SERVE_MEAL
	end
end

return ServeFoodAtTable
