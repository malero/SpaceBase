local Task=require('Utility.Task')
local World=require('World')
local Class=require('Class')
local Room=require('Room')
local Log=require('Log')
local Character=require('CharacterConstants')
local Topics=require('Topics')
local DFMath = require('DFCommon.Math')
local CharacterManager = require('CharacterManager')

local EatAtTable = Class.create(Task)

EatAtTable.emoticon = 'beer'

EatAtTable.DURATION_MIN = 20
EatAtTable.DURATION_MAX = 35

function EatAtTable:init(rChar,tPromisedNeeds,rActivityOption)
    Task.init(self, rChar, tPromisedNeeds, rActivityOption)
    self.duration = math.random(EatAtTable.DURATION_MIN, EatAtTable.DURATION_MAX)
    self.bInterruptOnPathFailure = true
    self:setPath(rActivityOption.tBlackboard.tPath)
    self.pathTargetX,self.pathTargetY = rActivityOption.tBlackboard.tileX,rActivityOption.tBlackboard.tileY
    self.rTable = rActivityOption.tData.rTable
    self.nTableTX,self.nTableTY = rActivityOption.tData.tableTX,rActivityOption.tData.tableTY
end

function EatAtTable:_foodServed(dt)
    self.bReceivedFood=true
    self.bWaitingForFood=false
    self.rTable:waitingForFood(self,false)
    if not self:attemptInteractWithObject('eat_cooked_food', self.rTable, self.duration) then
        self:interrupt('Failed to interact with table: eat')
    else
        self.duration = self.duration - dt
    end
end

function EatAtTable:_waitForFood()
    if not self:attemptInteractWithTile('breathe', self.nTableTX,self.nTableTY, 1) then
        self:interrupt('Failed to interact with table: breathe')
        return
    end
    self.bWaitingForFood = true
    self.rTable:waitingForFood(self,true)
end

function EatAtTable:onComplete(bSuccess)
    Task.onComplete(self,bSuccess)
	-- if we were starving, reset timer (stave off death!)
	if bSuccess and self.rChar.tStatus.nStarveTime > 0 then
		self.rChar.tStatus.nStarveTime = 0
	end
    if not self.rTable or self.rTable.bDestroyed then
		return
	end
	self.rTable:waitingForFood(self,false)
	if not bSuccess then
		return
	end
	local tFood = self.rTable:foodConsumed()
	if not tFood then
		return
	end
	local nMealAffinity = 0
	local sMealName = tFood.sName
	local sMealTopicID = tFood.sTopicID or sMealName
	local nBonus = nil
	local nAnger = nil
	if not Topics.tTopics[sMealTopicID] then
		-- Rare: can happen from old saves.
		Print(TT_Warning, "Food not in topic list:",sMealTopicID)
		nBonus = 0
	else
		-- alpha 2 era save data might still use sCreatedBy
		local sCookID = tFood.sCreatorID or tFood.sCreatedBy
		local rCook = CharacterManager.getCharacterByUniqueID(sCookID)
		local logType = Log.tTypes.EAT_COOKED_MEAL_GOOD
		local nMealAffinity = self.rChar:getAffinity(sMealTopicID)
		local nAnger
		if self.rChar:getFavorite('Foods') == sMealTopicID then
			logType = Log.tTypes.EAT_COOKED_MEAL_FAVORITE
		elseif nMealAffinity < 0 then
			logType = Log.tTypes.EAT_COOKED_MEAL_BAD
			-- bad meal? get a little angry
			nAnger = Character.ANGER_BAD_FOOD
			if self.rChar.tStats.tPersonality.bGourmand then
				-- moreso if we're a gourmand
				nAnger = nAnger * 2
			end
		end
		local tLogData = { sMealName = Topics.tTopics[sMealTopicID].name, }
		Log.add(logType, self.rChar, tLogData)
		-- morale boost = (50/50) affinity for meal + bartender skill
		local nAffinityBonus = math.max(0, nMealAffinity) / Character.STARTING_AFFINITY
		local nQualityBonus = (rCook and rCook:getJobCompetency(Character.BARTENDER)) or 0
		nBonus = DFMath.lerp(Character.MORALE_ATE_MEAL_BASE, Character.MORALE_ATE_MEAL_MAX, (nAffinityBonus + nQualityBonus) / 2)
	end
	self.rChar:alterMorale(nBonus, 'AteMeal')
	-- apply anger /after/ log, morale etc
	if nAnger then
		self.rChar:angerEvent(nAnger)
	end
end

function EatAtTable:onUpdate(dt)
    if self:interacting() then
        if self:tickInteraction(dt) then
            if self.bWaitingForFood then
            else
                return true
            end
        end
    elseif self.bWaitingForFood then
        if not self.rTable or self.rTable.bDestroyed then
            self:interrupt('table destroyed')
        elseif self.rTable:hasFood() then
            self:_foodServed(dt)
        elseif self.rTable:getWaitingCustomer() ~= self then
            self:interrupt('we got bumped from our food slot')
        elseif not self.rTable:isActive() then
            self:interrupt('bar stopped existing or being tended')
        end
    elseif self:tickWalk(dt) then
        self:_waitForFood()
	end
end

return EatAtTable
