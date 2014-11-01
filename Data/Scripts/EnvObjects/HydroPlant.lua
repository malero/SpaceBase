local Class=require('Class')
local DFUtil = require("DFCommon.Util")
local DFGraphics = require('DFCommon.Graphics')
local Renderer=require('Renderer')
local Inventory=require('Inventory')
local EnvObject=require('EnvObjects.EnvObject')
local PathUtil=require('PathUtil')
local ObjectList=require('ObjectList')
local PlantData=require('Foods.PlantData')
local Pickup=require('Pickups.Pickup')
local MiscUtil = require("MiscUtil")
local DFMath = require("DFCommon.Math")
local Character=require('CharacterConstants')
local GameRules = require('GameRules')
local Base = require('Base')
local ResearchData = require('ResearchData')

local HydroPlant = Class.create(EnvObject, MOAIProp.new)

-- sickly but not dead plants can still be eaten from
HydroPlant.DEAD_PLANT_HEALTH = 20
HydroPlant.PLANT_HEALTH_NEEDED_TO_MAINTAIN = 90
HydroPlant.PLANT_HEALTH_NEEDED_TO_GROW = 65
-- ratio * 100 / growth time to 100%
-- TODO: move this into PlantData so some plants can be more/less hardy
HydroPlant.AGE_TO_DECAY_RATIO = 0.4
HydroPlant.MIN_HEALTH_PCT_HEALED_PER_MAINTAIN = 10
HydroPlant.MAX_HEALTH_PCT_HEALED_PER_MAINTAIN = 40
HydroPlant.DEFAULT_HEALTH = 100
-- "sickly" = equivalent to envobject "damaged"
HydroPlant.SICKLY_HEALTH = 50

HydroPlant.tConditions=
{
    {nBelow=101, linecode = 'INSPEC095TEXT' },
    {nBelow=HydroPlant.SICKLY_HEALTH, linecode = 'INSPEC096TEXT' },
    {nBelow=1, linecode = 'INSPEC097TEXT' },
}

function HydroPlant:init(sName, wx, wy, bFlipX, bFlipY, bForce, tSaveData, nTeam)
    local tData = EnvObject.getObjectData(sName)
    
    self.nPlantAge = 0
    self.nPlantHealth = HydroPlant.DEFAULT_HEALTH
    self.bSeeded = false
    if tSaveData then
        if tSaveData.nPlantAge then
            self.nPlantAge = tSaveData.nPlantAge
        end
        if tSaveData.nPlantHealth then
            self.nPlantHealth = tSaveData.nPlantHealth
        end
        self.bSeeded = tSaveData.bSeeded or (self.nPlantAge > 0)
        if tSaveData.sPlantType then 
            self.sPlantType = tSaveData.sPlantType 
        end
        self.nEatMeCooldown = tSaveData.nEatMeCooldown
    end
    -- for now we just get plants at random
    if not self.sPlantType or not PlantData.tPlants[self.sPlantType] then
		self.sPlantType = MiscUtil.randomKey(PlantData.tPlants)
		-- HOLIDAY FUN: only plant candy cane trees in december!
		local tDate = os.date('*t', os.time())
		if tDate.month ~= 12 then
			while self.sPlantType == 'CandyCane' do
				self.sPlantType = MiscUtil.randomKey(PlantData.tPlants)
			end
		end
    end
    self.rPlantData = PlantData.tPlants[self.sPlantType]
	-- remember plant name for tooltip etc
	self.sPlantName = g_LM.line(PlantData.tPlants[self.sPlantType].sPlantLC)

    self.healthDecayPerSecond = HydroPlant.AGE_TO_DECAY_RATIO * 100 / self.rPlantData.nLifeTime
    
    local tActivityData=
    {
        rTargetObject=self,
        bNoPathToNearestDiagonal=true,
        utilityGateFn=function(rChar,rAO)
            return self:_harvestAndDeliverGate(rChar,rAO)
        end,
    }    
    local tMaintainActivityData=
    {
        rTargetObject=self,
        bNoPathToNearestDiagonal=true,
        utilityGateFn=function(rChar,rAO)
            return self:_maintainPlantGate(rChar,rAO)
        end,
        utilityOverrideFn=function(rChar,rAO,nOriginalUtility) 
            return self:getMaintainPlantUtility(rChar,nOriginalUtility) 
        end,
    }
    local tEatPlantData=
    {
        rTargetObject=self,
        bNoPathToNearestDiagonal=true,
        utilityGateFn=function(rChar,rAO)
            return self:_eatPlantGate(rChar,rAO)
        end,
    }

    self.rHarvestOption = g_ActivityOption.new('HarvestAndDeliverFood',tActivityData)
    self.rMaintainPlantOption = g_ActivityOption.new('MaintainPlants', tMaintainActivityData)
    self.rEatPlantOption = g_ActivityOption.new('EatPlant', tEatPlantData)

    EnvObject.init(self,sName, wx, wy, bFlipX, bFlipY, bForce, tSaveData, nTeam)
    -- create the plant prop
    self.rPlantSpriteSheet = DFGraphics.loadSpriteSheet(EnvObject.spriteSheetPath, false, false, false)
    if self.rPlantSpriteSheet then
        self.rPlantProp = MOAIProp.new()
        self.rPlantProp:setDeck(self.rPlantSpriteSheet)
		-- ref so GuiManager._getTargetAt can recognize it
		self.rPlantProp.rEnvObjParent = self
        MiscUtil.setTransformVisParent(self.rPlantProp, self)
        self.rPlantProp:setLoc(-64, -26)
        Renderer.getRenderLayer(self.layer):insertProp(self.rPlantProp)
    end
    self:_adjustVisuals()
end

function HydroPlant:setBaseColor(r,g,b)
    EnvObject.setBaseColor(self,r,g,b)
    if self.rPlantProp then
        if self:slatedForTeardown(false,true) then
            self.rPlantProp:setColor(unpack(self.pendingVaporizeColor))
        else
            self.rPlantProp:setColor(r,g,b,1.0)
        end        
    end
end

function HydroPlant:hover(hoverTime)
	EnvObject.hover(self, hoverTime)
	-- tint plant prop as well
    local alpha = math.abs(math.sin(hoverTime * 4)) / 2 + 0.5
    self.rPlantProp:setColor(g_GuiManager.AMBER[1]*alpha, g_GuiManager.AMBER[2]*alpha, g_GuiManager.AMBER[3]*alpha, 1.0)
end

function HydroPlant:unHover()
    EnvObject.unHover(self)
    if self.rPlantProp then
        if self:slatedForTeardown(false,true) then
            self.rPlantProp:setColor(unpack(self.pendingVaporizeColor))
        elseif self.baseColor then
            self.rPlantProp:setColor(unpack(self.baseColor))
        else
            self.rPlantProp:setColor(1, 1, 1, 1)
        end    
    end
end

function HydroPlant:remove()
    if self.rPlantProp then
        Renderer.getRenderLayer(self.layer):removeProp(self.rPlantProp)
    end
    EnvObject.remove(self)
end

function HydroPlant:_shouldGenerateOxygen()
	-- sickly plants don't produce oxygen
    return self.tData.oxygenLevel and not self:shouldDestroy() and self.nCondition > 0 and self.nPlantHealth > HydroPlant.SICKLY_HEALTH
end

function HydroPlant:_harvestAndDeliverGate(rChar,rAO)
    if not self:canBeHarvested() and (not rChar:heldItem() or rChar:heldItem().sTemplate ~= 'FoodCrate') then
        return false, 'cannot be harvested'
    end
    if self:getNearbyFridge() then
        return EnvObject.gateJobActivity(self.sName, rChar, false, self)
    end
    return false, 'no reachable refrigerator'
end

function HydroPlant:_eatPlantGate(rChar,rAO)
    if not self.bCanBeEaten then
        return false, 'plant not old enough'
    end
    if self.nEatMeCooldown and self.nEatMeCooldown > GameRules.elapsedTime then
        if not self.rChar or self.rChar.tNeeds['Hunger'] > Character.NEEDS_HUNGER_STARVATION then
            return false, 'cooling down'
        end
    end
    return true
end

function HydroPlant:_maintainPlantGate(rChar,rAO)    
    return EnvObject.gateJobActivity(self.sName, rChar, false, self)   
end

function HydroPlant:getNearbyFridge()
    if not self:isFunctioning() then return end

    local callback=function(rProp)
        if rProp.getFridgeSpace and rProp:getFridgeSpace() > 0 then return true end
    end

    local rFridge
    if not self.nFridgeTX then
        if self.nClearFridgeTimer and self.nClearFridgeTimer > 0 then return end
        local tx,ty,tw = self:getTileLoc()
        rFridge = PathUtil.findNearbyProp(tx,ty,tw, 70, callback)
        if rFridge then
            self.nFridgeTX,self.nFridgeTY,self.nFridgeTW = rFridge:getTileLoc()
        end
    else
        rFridge = ObjectList.getObjAtTile(self.nFridgeTX,self.nFridgeTY,ObjectList.ENVOBJECT)
        if rFridge and not rFridge.getFridgeSpace then
            rFridge = nil
        end
        if not rFridge then self.nFridgeTX = nil end
    end

    return rFridge
end

function HydroPlant:onTick(dt)
    local diff = g_GameRules.simTime - self.lastUpdate

    -- tick condition down once per second.
    if diff > 1 then
        if self.bSeeded then
            if self.nCondition > 0 and self:isPlantHealthy() then -- only ages when in good condition
                self:agePlant(diff)
            end
            -- deteriorate the plant health
            self:damagePlantHealth(self.healthDecayPerSecond * diff)
        end
        if self.nClearFridgeTimer and self.nClearFridgeTimer > 0 then
            self.nClearFridgeTimer = self.nClearFridgeTimer - dt
            if self.nClearFridgeTimer <= 0 then
                self.nFridgeTX,self.nFridgeTY = nil,nil
            end
        end
    end
    EnvObject.onTick(self,dt)
--    print("PLANT HEALTH: "..self.nPlantHealth)
--    print("PLANT AGE:    "..self.nPlantAge)
end

function HydroPlant:maintainPlant(healthAtStartOfMaintain, rBotanist)
    if not self.bSeeded then
        self.bSeeded = true
    end
    local nBotanistCompetence = rBotanist:getJobCompetency(Character.BOTANIST)

    -- little hack: give back the object's health that decayed during maintenance.
    if healthAtStartOfMaintain and self.nPlantHealth < healthAtStartOfMaintain then
        self.nPlantHealth = healthAtStartOfMaintain
    end
    local bSuper = rBotanist:getInventoryItemOfTemplate('SuperGreenThumb')

    -- health improved based on maintainer competence
    local nHealthRaised = DFMath.lerp(HydroPlant.MIN_HEALTH_PCT_HEALED_PER_MAINTAIN, HydroPlant.MAX_HEALTH_PCT_HEALED_PER_MAINTAIN, nBotanistCompetence)
    if Base.hasCompletedResearch('PlantLevel2') or bSuper then
        nHealthRaised = nHealthRaised * ResearchData['PlantLevel2'].nConditionMultiplier
    end
    
    local newHealth = math.min(self.nPlantHealth+nHealthRaised, 100)
    local nImprovement = newHealth - self.nPlantHealth
    self:_setPlantHealth(newHealth)    

    if bSuper then
        self:agePlant(60*5)
    end

    return nImprovement
end

function HydroPlant:agePlant(amt)
	-- plants can't grow without light (room has power)
    if self.nPlantHealth > HydroPlant.PLANT_HEALTH_NEEDED_TO_GROW and self.rRoom:hasPower() then
        self.nPlantAge = math.min(self.nPlantAge + amt, self.rPlantData.nLifeTime)
    end
    -- fix up visuals as necessary
    self:_adjustVisuals()
end

function HydroPlant:damagePlantHealth(amt)
    self.nPlantHealth = math.max(0, self.nPlantHealth - amt)
    self:_adjustVisuals()    
end

function HydroPlant:isPlantHealthy()
    return self.nPlantHealth > HydroPlant.SICKLY_HEALTH
end

function HydroPlant:getPlantHealth()
    return self.nPlantHealth     
end

function HydroPlant:_setPlantHealth(amt)
    self.nPlantHealth = amt
    self:_adjustVisuals()
end

function HydroPlant:getSaveTable(xShift,yShift)
    local tSaved = EnvObject.getSaveTable(self,xShift,yShift)
    tSaved.nPlantAge = self.nPlantAge
    tSaved.sPlantType = self.sPlantType
    tSaved.nPlantHealth = self.nPlantHealth
    tSaved.bSeeded = self.bSeeded
    tSaved.sPlantName = self.sPlantName
    tSaved.nEatMeCooldown = self.nEatMeCooldown
    return tSaved
end

function HydroPlant:setCanBeHarvested(bCanBeHarvested)
    self.bCanBeHarvested = bCanBeHarvested
end

function HydroPlant:canBeHarvested()
    return self.bCanBeHarvested and self:isPlantHealthy()
end

function HydroPlant:eatMe()
    self.nPlantAge = math.max(0,self.nPlantAge - 3)
    self.nEatMeCooldown = GameRules.elapsedTime + 90
end

function HydroPlant:harvest(nBotanistCompetence)
    local tHarvestedItems = {}
    if self.rPlantData and self.rPlantData.tHarvestableFoods then
        -- for now we harvest every one
        for sFoodType, rInfo in pairs(self.rPlantData.tHarvestableFoods) do
            local nNumHarvested = 1
            if rInfo.tNumHarvestedRange and rInfo.tNumHarvestedRange[1] and rInfo.tNumHarvestedRange[2] then                
                if nBotanistCompetence then
                    nNumHarvested = math.floor(DFMath.lerp(rInfo.tNumHarvestedRange[1], rInfo.tNumHarvestedRange[2], nBotanistCompetence))
                else
                    nNumHarvested = math.random(rInfo.tNumHarvestedRange[1], rInfo.tNumHarvestedRange[2])
                end
            end
            local tItem = Inventory.createItem(sFoodType,{nCount=nNumHarvested})
            tHarvestedItems[tItem.sName] = tItem
        end
    end
    self:reset()
    return tHarvestedItems
end

function HydroPlant:reset()
    -- reset the age
    self.nPlantAge = 0
    self.nPlantHealth = HydroPlant.DEFAULT_HEALTH
    self.bCanBeHarvested = false
    self.bSeeded = false
    self:_adjustVisuals()
end

function HydroPlant:onConditionSet()
    self:_adjustVisuals()
end

function HydroPlant:getMaintainPlantUtility(rChar,nOriginalUtility)
    local adjust = 1
    if self.bSeeded then
        adjust = .5 - self.nPlantHealth / 100    
    end
    return nOriginalUtility + nOriginalUtility * adjust
end

function HydroPlant:getPlantHealthUIInfo()
	local sString = ''
    for i=1,#HydroPlant.tConditions do
        if self.nPlantHealth < HydroPlant.tConditions[i].nBelow then
            sString = g_LM.line(HydroPlant.tConditions[i].linecode)
			sString = sString .. ' ('..math.floor(self.nPlantHealth)..'%)'
        end
    end
    return sString
end

function HydroPlant:_getCurAgeTextureName()
    local sTextureName = nil
    local nGetCurAgePct = self.nPlantAge / self.rPlantData.nLifeTime
    if self.rPlantData.ageInfo then
        for i, rInfo in ipairs(self.rPlantData.ageInfo) do
            if nGetCurAgePct > rInfo.nAbove then
                sTextureName = rInfo.spriteName
                self:setCanBeHarvested(rInfo.bCanBeHarvested)
                self.bCanBeEaten = rInfo.bCanBeEaten
            end
        end
    end
    return sTextureName
end

function HydroPlant:_adjustVisuals()
    if self.rPlantProp then
        -- get the age appropriate sprite name
        local sTextureName = self:_getCurAgeTextureName()
        local sSuffix = ''
        if sTextureName then
            self.rPlantProp:setVisible(true)
            if not self:isPlantHealthy() then
                sSuffix = '_dead'
            end
            local spriteName = sTextureName..sSuffix
            if self.rPlantSpriteSheet then
                local index = self.rPlantSpriteSheet.names[spriteName] 
                if index then
                    self.rPlantProp:setIndex(index)
                end
            end
        else
            -- plantprop set to be invisible
            self.rPlantProp:setVisible(false)
        end
    end
end

function HydroPlant:getToolTipTextInfos()
    EnvObject.getToolTipTextInfos(self)
	-- line 1: if we have a plant, show plant name
	if not self.sPlantName or not self.bSeeded then
		return self.tToolTipTextInfos
	end
	self.tToolTipTextInfos[1].sString = self.sPlantName
	
	-- line 2: condition/health
	local sString = g_LM.line('INSPEC093TEXT')..' '..self:getPlantHealthUIInfo()
	self:setToolTipBulletPoint(self.tToolTipTextInfos[2], sString)
	
	-- line 3: plant age, where applicable
	local nAgePct = math.floor((self.nPlantAge / self.rPlantData.nLifeTime) * 100)
	sString = g_LM.line('INSPEC094TEXT')..' '..tostring(nAgePct)..'%'
	self:setToolTipBulletPoint(self.tToolTipTextInfos[3], sString)
	
    return self.tToolTipTextInfos
end

function HydroPlant:getAvailableActivities()
    local tActivities = EnvObject.getAvailableActivities(self)
    -- only be available when on the player team
    if self:getTeam() == Character.TEAM_ID_PLAYER then    
        table.insert(tActivities, self.rHarvestOption)
        if not self.bSeeded or self.nPlantHealth < HydroPlant.PLANT_HEALTH_NEEDED_TO_MAINTAIN then
            table.insert(tActivities, self.rMaintainPlantOption)
        end
        if self.bSeeded and self.nPlantHealth > HydroPlant.DEAD_PLANT_HEALTH then
            table.insert(tActivities, self.rEatPlantOption)
        end
    end
    return tActivities
end

return HydroPlant
