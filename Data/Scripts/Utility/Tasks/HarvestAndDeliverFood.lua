local Task=require('Utility.Task')
local Class=require('Class')
local World=require('World')
local Log=require('Log')
local Inventory=require('Inventory')
local GameRules=require('GameRules')
local Character=require('CharacterConstants')
local GameRules = require('GameRules')
local Pickup = require('Pickups.Pickup')
local EnvObject = require('EnvObjects.EnvObject')

local HarvestAndDeliverFood = Class.create(Task)

HarvestAndDeliverFood.HARVEST_MIN_DURATION = 8
HarvestAndDeliverFood.HARVEST_MAX_DURATION = 12

HarvestAndDeliverFood.DROPOFF_MIN_DURATION = 3
HarvestAndDeliverFood.DROPOFF_MAX_DURATION = 3

HarvestAndDeliverFood.HARVEST_ANIM_DURATION = 2.8
HarvestAndDeliverFood.FRIDGE_ANIM_DURATION = 0.5

function HarvestAndDeliverFood:init(rChar,tPromisedNeeds,rActivityOption)
    self.super.init(self,rChar,tPromisedNeeds,rActivityOption)
    self.nDuration = self:getDuration(HarvestAndDeliverFood.HARVEST_MIN_DURATION, HarvestAndDeliverFood.HARVEST_MAX_DURATION, Character.BOTANIST)
    
    if self.rChar:heldItem() and self.rChar:heldItem().sTemplate == 'FoodCrate' then
        -- HACK: allows delivery of food crate on game load, if it's in the bearer's inventory.
        -- But it still relies on the plant to locate a fridge, so it's a half-step towards real
        -- activity save+resume.
        self.rTarget = rActivityOption and rActivityOption.tData.rTargetObject
        self:setUpFoodDelivery()
    else
        self.rTarget,self.tPath = self:findPlantToHarvest(rActivityOption)
        if not self.tPath then
            self:interrupt('Could not find a plant to harvest.')
            return
        end
        self:setPath(self.tPath)
    end
end

function HarvestAndDeliverFood:setUpFoodDelivery()
    if self.rChar:heldItem() and self.rChar:heldItem().sTemplate == 'FoodCrate' then
        self.rTarget = self:findFridge()
        if not self.tPath then
            self:interrupt('Could not find a fridge.')
            return
        end
        self.nDuration = self:getDuration(HarvestAndDeliverFood.DROPOFF_MIN_DURATION, HarvestAndDeliverFood.DROPOFF_MAX_DURATION, Character.BOTANIST)
        self.bDelivering=true
    else
        self:interrupt('not holding an item that can be delivered')
        return
    end
end

function HarvestAndDeliverFood:findPlantToHarvest(rAO)
    if rAO and rAO.tData.rTargetObject and rAO.tData.rTargetObject.bCanBeHarvested then
        return rAO.tData.rTargetObject,rAO.tBlackboard.tPath
    end
end

function HarvestAndDeliverFood:findFridge()
    local rFridge = self.rTarget and self.rTarget.getNearbyFridge and self.rTarget:getNearbyFridge()
    if rFridge then
        self:createPathTo(rFridge,rFridge:getFacing())
        if self.tPath then return rFridge end
    end
end

function HarvestAndDeliverFood:onUpdate(dt)
    if self:interacting() then
        if self:tickInteraction(dt) then
            if self.bDelivering then
                local tItemData = self.rChar:destroyItem(self.rChar:heldItemName())
                if self.rTarget and tItemData and not self.rTarget.bDestroyed then
                    for sName,tData in pairs(tItemData.tContents) do
                        self.rTarget:addItem(tData)
                    end
                    -- spaceface log            
                    local tLogData = {}
                    Log.add(Log.tTypes.DUTY_BOTANIST_HARVEST, self.rChar, tLogData)
					-- morale
					self.rChar:alterMorale(Character.MORALE_DELIVERED_FOOD, 'DeliveredFood')
                    return true
                else
                    self:interrupt('fridge destroyed during interaction')
                end
            else
                if self.rTarget and not self.rTarget.bDestroyed then
                    local tHarvested = self.rTarget:harvest(self.rChar:getJobCompetency(Character.BOTANIST))
                    local tContainer = Inventory.createItem('FoodCrate')
                    Inventory.putItemListIntoContainer(tContainer,tHarvested)
                    self.rChar:pickUpItem(tContainer)
                    self:setUpFoodDelivery()
                else
                    self:interrupt('plant destroyed during interaction')
                end
            end
        end
    elseif self.tPath then
        self:tickWalk(dt)
    else
        local bSuccess, sReason
        if self.bDelivering then
            --interact with fridge
            bSuccess, sReason = self:attemptInteractWithObject('fridge',self.rTarget,HarvestAndDeliverFood.FRIDGE_ANIM_DURATION, true)
        else
            --interact with plant
            bSuccess, sReason = self:attemptInteractWithObject('harvest',self.rTarget,HarvestAndDeliverFood.HARVEST_ANIM_DURATION, true)
        end
        if not bSuccess then
            if sReason == 'object busy' then
                if not self.nTimeWaitingForBusyObject then
                    self.nTimeWaitingForBusyObject = 0
                else
                    self.nTimeWaitingForBusyObject = self.nTimeWaitingForBusyObject + dt
                    if self.nTimeWaitingForBusyObject > self.HARVEST_MAX_DURATION then
                        self:interrupt('Object busy.')
                    end
                end
            else
                self:interrupt('Unable to reach dropoff point.')
            end
        end
    end
end

function HarvestAndDeliverFood:onComplete(bSuccess)
    Task.onComplete(self,bSuccess)
    -- in case of interruption.
    if not bSuccess and self.rChar:heldItemName() then self.rChar:dropItemOnFloor(self.rChar:heldItemName()) end
end

return HarvestAndDeliverFood
