local Class=require('Class')
local DFUtil = require("DFCommon.Util")
local MiscUtil = require("MiscUtil")
local Renderer = require("Renderer")
local EnvObject=require('EnvObjects.EnvObject')
local Character=require('CharacterConstants')
local Topics=require('Topics')

local PubTable = Class.create(EnvObject, MOAIProp.new)

function PubTable:init(sName, wx, wy, bFlipX, bFlipY, bForce, tSaveData, nTeam)
    EnvObject.init(self,sName, wx, wy, bFlipX, bFlipY, bForce, tSaveData, nTeam)

    local tx,ty,tw = self:getTileLoc()
    local atx,aty = g_World._getAdjacentTile(tx,ty,g_World.directions.NW)
    local pathX,pathY = g_World._getWorldFromTile(atx,aty,1)
    local tData=
    {
        pathX=pathX, pathY=pathY,
        tableTX=tx, tableTY=ty,
        utilityGateFn=function(rChar,rAO) return self:_eatGate(rChar,rAO) end,
        rTable=self,
    }
    self.rEatOption = g_ActivityOption.new('EatAtTable',tData)

    tData=
    {
        pathToNearest=true,
        bNoPathToNearestDiagonal=true,
        tableTX=tx, tableTY=ty,
        targetLocationFn=function()
            local rFridge = self:getFridgeWithFood()
            if rFridge then
                local fridgeTX,fridgeTY = rFridge:getTileLoc()
                return g_World._getWorldFromTile( fridgeTX,fridgeTY )
            end
        end,
        utilityGateFn=function(rChar,rAO) return self:_serveGate(rChar,rAO) end,
        rTable=self,
    }
    self.rServeOption = g_ActivityOption.new('ServeFoodAtTable',tData)
end

function PubTable:_eatGate(rChar,rAO)
    if self:getTeam() ~= rChar:getTeam() then return false, 'wrong team' end
    if rChar:getJob() == Character.BARTENDER and rChar:wantsWorkShiftTask() then
        return false, 'on-duty bartenders not allowed to eat at table'
    end

    return self:isActive(true)
end

function PubTable:_serveGate(rChar,rAO)
    if self:getTeam() ~= rChar:getTeam() then return false, 'wrong team' end
    if not self.rWaitingCustomerTask then return false, 'no waiting customer' end
    if self:hasFood() then return false, 'table already has food' end

    if self.bDestroyed or self.nCondition < 1 then
        return false, 'destroyed'
    end

    if rChar:heldItem() and rChar:heldItem().sTemplate == 'CookedMeal' then return true end

    return self:isActive(true)
end

function PubTable:waitingForFood(rActivity,bWaiting)
    if bWaiting then
        self.rWaitingCustomerTask = rActivity
    else
        if self.rWaitingCustomerTask == rActivity then self.rWaitingCustomerTask = nil end
    end
end

function PubTable:getWaitingCustomer()
    return self.rWaitingCustomerTask
end

--[[
function PubTable:foodServed(bSuccess,tItem)
    if self.rWaitingCustomerTask then
        self.rWaitingCustomerTask:foodServed(bSuccess)
    end
    self:_showFood(bSuccess)
end
]]--

function PubTable:_refreshDisplaySlots()
    EnvObject._refreshDisplaySlots(self)
    local bShow = next(self.tInventory) ~= nil
    if bShow then
        if not self.rFoodProp then
            self.rFoodProp = MOAIProp.new()
            self.rFoodProp:setDeck(self.spriteSheet)
            self.rFoodProp:setIndex(self.spriteSheet.names['food01'])
            MiscUtil.setTransformVisParent(self.rFoodProp, self)
            --self.rFoodProp:setLoc(-64, -26)
            self.rFoodProp:setLoc(0,0)
            Renderer.getRenderLayer(self.layer):insertProp(self.rFoodProp)
        end
    else
        if self.rFoodProp then
            Renderer.getRenderLayer(self.layer):removeProp(self.rFoodProp)
            self.rFoodProp = nil
        end
    end
end

function PubTable:foodConsumed()
    local sFoodName = next(self.tInventory)
    local tFood = nil
    if sFoodName then
        tFood = self:destroyItem(sFoodName)
    end
    return tFood
end

function PubTable:hasFood()
    return next(self.tInventory) ~= nil
end

function PubTable:getStove()
    local tStoves, nStoves = self.rRoom:getPropsOfName('Stove')
    local bStove = false
    local tArr = {}
    for rStove,_ in pairs(tStoves) do
        if not rStove.bDestroyed and rStove.nCondition > 0 and rStove:isFunctioning() then
            table.insert(tArr,rStove)
            bStove = true
        end
    end
    if bStove then
        return MiscUtil.randomValue(tArr)
    end
end

function PubTable:isActive(bCheckFood)
    if self.bDestroyed or self.nCondition < 1 then
        return false, 'destroyed'
    end

    local r = self:getRoom()
    local z = r and r.zoneObj
    if (not z or not z.hasBarTender or not z:hasBarTender()) then
        return false, 'no bartender'
    end

    if bCheckFood and (not self:getFridgeWithFood()) then
        return false, 'no fridge with food'
    end

    if not self:getStove() then
        return false, 'no stove'
    end

    return true
end

function PubTable:getFridgeWithFood()
    local tFridges, nFridges = self.rRoom:getPropsOfName('Fridge')
    for rProp,_ in pairs(tFridges) do
        if rProp:hasFood() then
            return rProp
        end
    end
end

function PubTable:getAvailableActivities()    
    local tActivities = EnvObject.getAvailableActivities(self)
    
    if self.rEatOption then
        table.insert(tActivities,self.rEatOption)
        table.insert(tActivities,self.rServeOption)
    end

    return tActivities
end



return PubTable

