local Class=require('Class')
local DFUtil = require('DFCommon.Util')
local ObjectList=require('ObjectList')
local Inventory=require('Inventory')
local Character=require('CharacterConstants')
local EnvObject=require('EnvObjects.EnvObject')
local ObjectList=require('ObjectList')
local GameRules=require('GameRules')
local PickupData=require('Pickups.PickupData')
local Room = require('Room')

local Pickup = Class.create(EnvObject, MOAIProp.new)

Pickup.spriteSheetPath='PropSprites/Pickups'

-- A Pickup is a simple subclass of EnvObject that:
-- * pulls from PickupData instead of EnvObjectData
-- * automatically advertises ActivityOptions from its inventory

-- Creates the appropriate Pickup, and puts the item into its inventory.
function Pickup.dropInventoryItemAt(tItem,wx,wy)
    if tItem.bAutocreated or Inventory.disappearOnDrop(tItem) then return end

    local sPickupName = Inventory.getPickupName(tItem)
    local tInventory = {}
    tInventory[tItem.sName] = tItem
    local rPickup = Pickup.createPickupAt(sPickupName, wx,wy, {tInventory=tInventory})
    return rPickup
end

function Pickup.createPickupAt(sPickupName, wx,wy, tSaveData, nTeam)
    local tData = PickupData.tObjects[sPickupName]
    local rProp = nil
    local rRoom = Room.getRoomAt(wx,wy,0,1)
	
    if tData.customClass then
        rProp = require(tData.customClass).new(sPickupName,wx,wy,false, false, true,tSaveData, nTeam)
    else
        rProp = Pickup.new(sPickupName,wx,wy, false, false, true,tSaveData, nTeam)
    end

    local rRoom = Room.getRoomAt(wx,wy,0,1)
    if rRoom then
        rRoom:addProp(rProp)
    elseif Room.getSpaceRoom() then
		Room.getSpaceRoom():addProp(rProp)
    end

    -- hack to handle some bad save data.
    if rProp.sName == 'ResearchDatacube' then
        local tCube = rProp.tInventory and rProp.tInventory['Research Datacube']
        if tCube then
            if tCube.sResearchData then
                -- it's fine.
            elseif rProp.sResearchData then
                -- we can port
                tCube.sResearchData = rProp.sResearchData
            end
        elseif rProp.sResearchData then
            tCube = Inventory.createItem('ResearchDatacube', rProp.sResearchData)
            rProp:addItem(tCube)
        end
        if not tCube or not tCube.sResearchData then
            rProp.tInventory = {}
        end
    end
    
    if not next(rProp.tInventory) then
        rProp:remove()
        rProp = nil
    end
	
    return rProp
end

function Pickup:init(sName, wx, wy, bFlipX, bFlipY, bForce, tSaveData, nTeam)
    self.bPickup = true
    EnvObject.init(self, sName, wx, wy, bFlipX, bFlipY, bForce, tSaveData, nTeam)

    self:_updateNameAndDesc()

	-- draw 3D model when on ground instead of sprite
	if self.tData.bDrawRigOnGround then
        local tRigArgs, tGroundOffsetPosition, tGroundRotation, tGroundScale
		tRigArgs = {
			sResource = self.tData.sRigPath,
			sMaterial = "meshSingleTexture",
			sTextureOverride = self.tData.sTexture,
		}
        tGroundOffsetPosition = self.tData.tGroundOffsetPosition
        tGroundRotation = self.tData.tGroundRotation
        tGroundScale = self.tData.tGroundScale

		local rRenderLayer = require('Renderer').getRenderLayer(require('CharacterConstants').RENDER_LAYER)
		local rGroundEntity = require('Entity').new(self, rRenderLayer, self.sUniqueName)
		self.rGroundRig = require('Rig').new(rGroundEntity, tRigArgs, require('GameRules').worldAssets)
		self.rGroundRig.name = sName
		self.rGroundRig.tEntity = rGroundEntity
		if tGroundOffsetPosition then self.rGroundRig.tOff = tGroundOffsetPosition end
		if tGroundRotation then self.rGroundRig.rUnscaledRootJointProp:setRot(unpack(tGroundRotation)) end
		if tGroundScale then self:setScl(unpack(tGroundScale)) end
		-- show rig, hide sprite
		self.rGroundRig:activate()
		self:setVisible(false)
    --elseif self.tData.bNoSprite then
		--self:setVisible(false)
        --g_LastPickup=self
	end
end

function Pickup:addItem(tData)
    EnvObject.addItem(self,tData)
    if not tData.nTimeUnwanted then tData.nTimeUnwanted  = GameRules.elapsedTime end
    self:_updateNameAndDesc()
end

function Pickup:_updateNameAndDesc()
    self.nPortraitOffX,self.nPortraitOffY = nil,nil
    self.nPortraitScl = nil
    if self.tData.bUseItemNameAndDesc then
        if next(self.tInventory) then
            local k = next(self.tInventory)
            local tItem = self.tInventory[k]
            if not tItem.nTimeUnwanted then tItem.nTimeUnwanted = GameRules.elapsedTime end
            
            self.sFriendlyName = tItem.sName or ''
            self.sDescription = Inventory.getDesc(tItem) or ''
            self.sFlavorText = Inventory.getFlavorText(tItem)
            local sPortrait,sPortraitPath,sTintSprite,tTintColor,nPortraitScl,nPortraitOffX,nPortraitOffY = Inventory.getPortrait(tItem)
            
            self.sPortrait = sPortrait or self.tData.sPortrait
            self.sPortraitPath = sPortraitPath
            self.sPortraitTintSprite = sTintSprite
            self.tPortraitTintColor = tTintColor
            
            if not self.sPortrait then
                self.sPortrait = 'portrait_generic'
                self.sPortraitPath = 'UI/Portraits'
            end
            
            self.nPortraitScl = nPortraitScl
            self.nPortraitOffX,self.nPortraitOffY = nPortraitOffX,nPortraitOffY
            if self.sPortraitPath == 'Environments/Objects' then
                self.nPortraitOffX,self.nPortraitOffY = nPortraitOffX or -200,nPortraitOffY or -240
            end
            
            self.researchPrereq = tItem.researchPrereq
            self.bHasResearchData = tItem.bHasResearchData or (tItem.sResearchData ~= nil)
            
            if tItem.bSlatedForResearchTeardown then
                self:slateForResearchTeardown(true)
            end
        else
            self.sFriendlyName = g_LM.line('PROPSX035TEXT')
            self.sDescription = g_LM.line('PROPSX036TEXT')
        end
    end
end

function Pickup:shouldDestroy()
    return false
end

function Pickup:_refreshDisplaySlots()
    EnvObject._refreshDisplaySlots(self)
    if self.tData.bUseDisplaySpriteAsPropSprite and self.tDisplaySlots and self.tDisplaySlots[1].rProp then
        self:setVisible(false)
    else
        self:setVisible(true)
    end
end

function Pickup:updateActivityOptionList()
    local tActivities = {}

    -- Iterate over all items in inventory and advertise the appropriate activities.
    if not self.bHasResearchData or self.bSlatedForResearchTeardown then
        for k,tItem in pairs(self.tInventory) do
            --local rOption = self:_getActivityOption(v)
            --if rOption then table.insert(tActivities,rOption) end
            local sSatisfies,eJob = Inventory.getHeldItemSatisfier(tItem)
            if sSatisfies then
                local tSatisfies = { HeldItem=sSatisfies }
                local r = self:getRoom()
                if not r or r:isDangerous() then
                    tSatisfies.HeldItemInDanger=sSatisfies
                end
                
                table.insert(tActivities, g_ActivityOption.new('PickUpFloorItem', { rTargetObject=self, sObjectKey=k,
                        utilityGateFn=function(rChar)
                            if rChar:getJob() == eJob then return true end
                            return false, 'wrong job'
                        end,
                        tSatisfies=tSatisfies} ))
            end
        end
    end

    if not self.bHasResearchData then
        self:_addInvItemOptions(tActivities)
    end

    self.activityOptionList:set(tActivities)
end

function Pickup:getSaveTable(xShift,yShift)
    local tSaved = EnvObject.getSaveTable(self,xShift,yShift)
    return tSaved
end

function Pickup:_removeItem(sObjectKey,nCount) 
    local t = EnvObject._removeItem(self,sObjectKey,nCount)
    -- persist this across pickup/drop in case the deliver action gets interrupted.
    if self.bSlatedForResearchTeardown then
        t.bSlatedForResearchTeardown = true
    end
    if not next(self.tInventory) then
        self:remove()
    else
        self:_updateNameAndDesc()
    end
    return t
end

return Pickup
