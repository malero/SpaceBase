local Character=require('CharacterConstants')
local InventoryData=require('InventoryData')
local ObjectList=require('ObjectList')
local MiscUtil=require('MiscUtil')
local GameRules=require('GameRules')
local CompoundProp=require('CompoundProp')
local DFGraphics = require('DFCommon.Graphics')
local DFUtil=require('DFCommon.Util')
local Inventory = {}

Inventory.TIME_UNWANTED_BEFORE_INCINERATE_MIN = 60*5
Inventory.TIME_UNWANTED_BEFORE_INCINERATE_MAX = 60*20
Inventory.JOB_ITEM_NO_INCINERATE_MULT = 4

function Inventory.dupeItem(tItem)
    local tItemTemplate = InventoryData.tTemplates[tItem.sTemplate]
    local tNew=DFUtil.deepCopy(tItem)
    if tItemTemplate.bStackable then
        assertdev(not tNew.tag)
        tNew.tag = nil
    else
        tNew.tag = ObjectList.addObject(ObjectList.INVENTORYITEM, tItem.sTemplate, tNew, nil, false, false, nil, nil, false)
    end
    return tNew
end

function Inventory.getIncinerateBias(tItem)
    if not tItem.nTimeUnwanted then return 0 end
    local nDiff = GameRules.elapsedTime - tItem.nTimeUnwanted
    local nMin = Inventory.TIME_UNWANTED_BEFORE_INCINERATE_MIN
    local nMax = Inventory.TIME_UNWANTED_BEFORE_INCINERATE_MAX
    local _,bJobItem = Inventory.getItemJob(tItem)
    if bJobItem then 
        nMin = nMin * Inventory.JOB_ITEM_NO_INCINERATE_MULT
        nMax = nMax * Inventory.JOB_ITEM_NO_INCINERATE_MULT
    end
    if nDiff < Inventory.TIME_UNWANTED_BEFORE_INCINERATE_MIN then return 0 end
    nDiff = math.min(nDiff, Inventory.TIME_UNWANTED_BEFORE_INCINERATE_MAX) - Inventory.TIME_UNWANTED_BEFORE_INCINERATE_MIN
    return nDiff / (Inventory.TIME_UNWANTED_BEFORE_INCINERATE_MAX - Inventory.TIME_UNWANTED_BEFORE_INCINERATE_MIN)
end

function Inventory.allowIncinerate(tItem)
    if tItem.bEligibleForIncinerate then return true end
    local _,bJobItem = Inventory.getItemJob(tItem)
    local nTimeToIncinerate = Inventory.TIME_UNWANTED_BEFORE_INCINERATE_MIN
    if bJobItem then nTimeToIncinerate = nTimeToIncinerate * Inventory.JOB_ITEM_NO_INCINERATE_MULT end
    if tItem.nTimeUnwanted and GameRules.elapsedTime - tItem.nTimeUnwanted > nTimeToIncinerate then
        tItem.bEligibleForIncinerate = true
        return true
    end
    return false
end

function Inventory.getWeaponData(tItem)
    local tItemTemplate = InventoryData.tTemplates[tItem.sTemplate]
    if tItemTemplate then
        return tItemTemplate.nDamage,tItemTemplate.nDamageType,tItemTemplate.nRange,tItemTemplate.sStance
    end
end

function Inventory.getArmorData(tItem)
    local tItemTemplate = InventoryData.tTemplates[tItem.sTemplate]
    if tItemTemplate then
        return tItemTemplate.nDamageReduction, tItemTemplate.nDodgeChance
    end
end

function Inventory.getItemJob(tItem)
    local tItemTemplate = InventoryData.tTemplates[tItem.sTemplate]
    if tItemTemplate then
        return tItemTemplate.Job,tItemTemplate.bJobTool
    end
end

function Inventory.getOutfitOverride(tItem)
    local tItemTemplate = InventoryData.tTemplates[tItem.sTemplate]
    if tItemTemplate and tItemTemplate.sOutfit then
        return tItemTemplate.sOutfit, tItemTemplate.Job
    end
end

function Inventory.removeItemFromContainer(tContainer,sObjectKey,nCount)
    local tData = tContainer[sObjectKey]
    if tData then
        if not nCount or tData.nCount <= nCount then
            tContainer[sObjectKey] = nil
            tData.tContainer = nil
            return tData
        else
            local tNewItem = Inventory.dupeItem(tData)
            tData.nCount = tData.nCount - nCount
            tNewItem.nCount = nCount
            return tNewItem
        end
    end
end

function Inventory.createRandomStartingStuff()
    local idx = math.random(1,#InventoryData.tStuffNames)
    return Inventory.createItem(InventoryData.tStuffNames[idx])
end

function Inventory.portFromSave(sKey,tItem)
    if not tItem then return end
    if type(tItem) == 'number' then
        -- old save
        if sKey and InventoryData.tTemplates[sKey] then
            tItem = Inventory.createItem(sKey, { nCount = tItem })
        else
            tItem = nil
        end
    elseif tItem.tag and tItem.tag.bInvalid then 
        return 
    elseif not tItem.tag then
        if InventoryData.tTemplates[tItem.sName] then
            if InventoryData.tTemplates[tItem.sName].bStackable then
                -- nothing: stackable items don't get tags
            else
                tItem = Inventory.createItem(tItem.sName, {nCount = tItem.nCount or 1})
            end
        else
            tItem = nil
        end
    else
        -- New save.
        -- Fall through, allow the other tests to verify the item template still exists.
        assertdev(tItem.sTemplate)
        assertdev(tItem.sName)
    end
    if not tItem then return end
    
    -- MTF TODO: remove after alpha 6. just have some inprogress saves with this issue,
    -- but none in the wild.
    if tItem.sName == 'Asteroid Chunk' then tItem.sTemplate = 'Rock' end
    
    if tItem.tag and tItem.tag.bInvalid then
        assertdev(false)
    end
    
    if tItem.sTemplate == 'ResearchDatacube' then
        if not tItem.sResearchData then
            return
        end
    end
    
    local tItemTemplate = InventoryData.tTemplates[tItem.sTemplate]
    if not tItemTemplate or tItemTemplate.bDisappearOnDrop then return nil end
    if not tItem.nCount then tItem.nCount = 1 end
    
    if tItemTemplate.sTintSprite and (not tItem.Color or not InventoryData.tTags.Color[tItem.Color]) then
        tItem.Color = MiscUtil.randomKey(InventoryData.tTags.Color)
    end
    
    return tItem
end

function Inventory.getSaveTable(tItem)
    if ObjectList.isValidObject(tItem) then return tItem end
end

function Inventory.getDesc(tItem)
    if tItem.sDesc then return tItem.sDesc end
    local tItemTemplate = InventoryData.tTemplates[tItem.sTemplate]
    if tItemTemplate.sDesc then return g_LM.line(tItemTemplate.sDesc) end
end

function Inventory.getFlavorText(tItem)
    local tItemTemplate = InventoryData.tTemplates[tItem.sTemplate]
    if tItemTemplate.sFlavorText then return g_LM.line(tItemTemplate.sFlavorText) end
end

function Inventory.assignOwner(tItem,rOwner)
    tItem.tOwnerTag = ObjectList.getTag(rOwner)
end

function Inventory.alreadyHasSingleton(tItem,rChar)
    if tItem and rChar and InventoryData.tTemplates[tItem.sTemplate] and InventoryData.tTemplates[tItem.sTemplate].bSingleton then
        for _,tHeldItem in pairs(rChar.tInventory) do
            if tHeldItem.sTemplate == tItem.sTemplate then
                return true
            end
        end
    end
    return false
end

function Inventory.getOwner(tItem)
    local tOwner = tItem.tOwnerTag
    local rOwner = tOwner and ObjectList.getObject(tOwner)
    if tOwner and not rOwner then tItem.tOwnerTag = nil end
    return rOwner
end

function Inventory.getPortrait(tItem)
    local tItemTemplate = InventoryData.tTemplates[tItem.sTemplate]
    local sSpriteSheet = tItemTemplate.sSpriteSheet or InventoryData.DEFAULT_SPRITE_SHEET
	local sSprite = tItemTemplate.sPortraitSprite
	if not sSprite and tItemTemplate.tPortraitSprites then
		sSprite = MiscUtil.randomValue(tItemTemplate.tPortraitSprites)
	end
    
    local sTintSprite = tItemTemplate.sTintSprite
    local tColor = tItem.Color and InventoryData.tTags.Color[ tItem.Color ].color

    local nPortraitScl = 1
    if tItemTemplate.nPortraitScl then nPortraitScl = tItemTemplate.nPortraitScl
    elseif sSpriteSheet == 'Environments/Objects' then nPortraitScl = 2 end
    
    return sSprite,sSpriteSheet, sTintSprite,tColor,nPortraitScl,tItemTemplate.nPortraitOffX,tItemTemplate.nPortraitOffY
end

function Inventory.getDisplaySprite(tItem)
    local tItemTemplate = InventoryData.tTemplates[tItem.sTemplate]
    local sSprite = tItemTemplate.sDisplaySprite or tItemTemplate.sPortraitSprite
	if not sSprite and tItemTemplate.tPortraitSprites then
		sSprite = MiscUtil.randomValue(tItemTemplate.tPortraitSprites)
	end
    local sSpriteSheet = tItemTemplate.sSpriteSheet or InventoryData.DEFAULT_SPRITE_SHEET
    return sSprite, sSpriteSheet, tItemTemplate.tScl
end

-- per every needs reduce tick, 14.4 seconds
function Inventory.getAffinityDecay(tItem)
    if tItem.nAffinityDecay then return tItem.nAffinityDecay end
    if InventoryData.tTemplates[tItem.sTemplate] then
        if InventoryData.tTemplates[tItem.sTemplate].nAffinityDecay then 
            return InventoryData.tTemplates[tItem.sTemplate].nAffinityDecay
        end
    end
    local job,bJobTool = Inventory.getItemJob(tItem)
    if bJobTool then
        return 0
    end

    return InventoryData.DEFAULT_AFFINITY_DECAY
end

function Inventory.createDisplayProps(tItem,bFlipX)
    local rProp = CompoundProp.new()
    local tItemTemplate = InventoryData.tTemplates[tItem.sTemplate]
    local sSprite,sSpriteSheet = Inventory.getDisplaySprite(tItem)
    local sTintSprite = tItemTemplate.sTintSprite
    --local rSpriteSheet = DFGraphics.loadSpriteSheet(sSpriteSheet, false, false, false)
    rProp:addSprite(sSprite,sSpriteSheet)
    if sTintSprite then
        local rTintProp = rProp:addSprite(sTintSprite,sSpriteSheet)
        local tagData = InventoryData.tTags.Color[ tItem.Color ]
        local r,g,b = unpack(tagData.color)
        rTintProp:setColor(r,g,b,1)
        rTintProp.tColor={r,g,b}
        rProp.rTintProp = rTintProp
    end
    local sclX,sclY = 1,1
    if bFlipX then sclX=-sclX end
    rProp:setScl(sclX,sclY) 
    
    return rProp
end

function Inventory.getMaxStacks(itemTableOrTemplateName)
    local sTemplate = itemTableOrTemplateName
    if type(sTemplate) == 'table' then sTemplate = sTemplate.sTemplate end
    local tItemTemplate = InventoryData.tTemplates[sTemplate]
    if not tItemTemplate.bStackable then return 1 end
    return tItemTemplate.nMaxStacks or InventoryData.nDefaultMaxStacks
end

function Inventory.getHeldItemSatisfier(tItem)
    local tItemTemplate = InventoryData.tTemplates[tItem.sTemplate]
    if tItemTemplate.bSatisfier then
        return tItem.sTemplate,tItemTemplate.Job
    end
end

function Inventory.putItemIntoContainer(tContainer,tItem)
    local tContainerTemplate = InventoryData.tTemplates[tContainer.sTemplate]
    
    assertdev(tContainerTemplate.bContainer)
    if not tContainerTemplate.bContainer then return end
   
    tItem.tContainer = ObjectList.getTag(tContainer)
    
        if tContainer.tContents[tItem.sName] then
            local tItemTemplate = InventoryData.tTemplates[tItem.sTemplate]
            if tItemTemplate.bStackable then
                local nMaxStacks = tItemTemplate.nMaxStacks or InventoryData.nDefaultMaxStacks
                tContainer.tContents[tItem.sName].nCount = math.min(nMaxStacks, tContainer.tContents[tItem.sName].nCount+tItem.nCount)
            end
        else
            tContainer.tContents[tItem.sName] = tItem
        end
end

function Inventory.putItemListIntoContainer(tContainer,tList)
    for k,v in pairs(tList) do
        Inventory.putItemIntoContainer(tContainer,v)
    end
end

function Inventory.getPickupName(tItem)
    local tItemTemplate = InventoryData.tTemplates[tItem.sTemplate]
    return tItemTemplate.Pickup or InventoryData.sDefaultPickup
end

function Inventory.isStuff(tItem)
    local tItemTemplate = InventoryData.tTemplates[tItem.sTemplate]
    return tItemTemplate.bStuff
end

function Inventory.disappearOnDrop(tItem)
    local tItemTemplate = InventoryData.tTemplates[tItem.sTemplate]
    return tItemTemplate.bDisappearOnDrop
end

function Inventory.heldOnly(tItem)
    local tItemTemplate = InventoryData.tTemplates[tItem.sTemplate]
    return tItemTemplate.bHeldOnly
end

function Inventory.createItemAtCursor(sTemplate, tOverrides)
    if not sTemplate then
        local idx = math.random(1,#InventoryData.tStuffNames)
        sTemplate = InventoryData.tStuffNames[idx]
    end
    if sTemplate == 'ResearchDatacube' then
        if not tOverrides then tOverrides = {} end
        if not tOverrides.sResearchData then
            tOverrides.sResearchData = require('GameEvents.Event')._getRandomDatacubeResearch()
        end
    end
    local tItem = Inventory.createItem(sTemplate, tOverrides)
    local DFInput = require('DFCommon.Input')
    local x,y = DFInput.m_x, DFInput.m_y
    local wx,wy = require('Renderer').getWorldFromCursor(x,y)
    local rPickup = require('Pickups.Pickup').dropInventoryItemAt(tItem,wx,wy)
    return rPickup,tItem
end

function Inventory.createItem(sTemplate, tOverrides)
    local tItem = {sTemplate=sTemplate}
    local tItemTemplate = InventoryData.tTemplates[sTemplate]

    tItem.nCount = 1
    if tItemTemplate.bContainer then
        tItem.tContents = {}
    end

    if tOverrides then
        for k,v in pairs(tOverrides) do
            tItem[k] = v
        end
    end

    if tItemTemplate.bStackable then
        -- Stackable items are defined entirely by a combo of the tItem table and the tItemTemplate table.
    else
        -- Unique items contain lots of additional data.
        tItem.tag = ObjectList.addObject(ObjectList.INVENTORYITEM, sTemplate, tItem, nil, false, false, nil, nil, false)
        if tItemTemplate.tPossibleTags then
			-- pick between 0 and 2 / # of allowed tags
			-- cap # of tags for name / behavior readability
			-- eg Teddy Bear, Blue Teddy Bear, Fuzzy Hip Teddy Bear, but NOT
			-- Punk Yellow Wood Bumpy Teddy Bear
            local nTotalTags = #tItemTemplate.tPossibleTags
			local nTags = math.min(math.random(0, #tItemTemplate.tPossibleTags),2)
            local tPossible = {}
            for i=1,nTotalTags do table.insert(tPossible,i) end
			local tTags = {}
            for i=1,nTags do
                local idx = math.random(#tPossible)
                local nTag = tPossible[idx]
                table.remove(tPossible,idx)
                local sTag = tItemTemplate.tPossibleTags[nTag]
				tTags[sTag] = MiscUtil.randomKey(InventoryData.tTags[sTag])
			end
        end
		-- populate "forced" tags
		if tItemTemplate.tForcedTags then
			for k,v in pairs(tItemTemplate.tForcedTags) do
				tItem[k] = v
			end
		end
    end

    if not tItem.sName then
        if tItemTemplate.sName then
            tItem.sName = g_LM.line(tItemTemplate.sName)
        elseif tItemTemplate.sSuffix then
            tItem.sName = Inventory._generateName(tItem)
        end
    end

    if tItemTemplate.sTintSprite and not tItem.Color then
        tItem.Color = MiscUtil.randomKey(InventoryData.tTags.Color)
    end

    assertdev(tItem.sName)
    if not tItem.sName then tItem.sName = '' end

    return tItem
end

function Inventory._generateName(tItem)
    local tItemTemplate = InventoryData.tTemplates[tItem.sTemplate]
    local sName = tItemTemplate.sSuffix
    assertdev(sName)
    if not sName then
        sName = ''
    else
        sName = g_LM.line(sName)
    end
    local tTags={}
    for k,v in pairs(InventoryData.tTags) do
		-- exclude tag if intrinsic
        if tItem[k] and (not tItemTemplate.tForcedTags or not tItemTemplate.tForcedTags[k]) then
            table.insert(tTags, {tagName=k, tagValue=tItem[k]})
        end
    end
	for _,tTag in pairs(tTags) do
        local tTagData = InventoryData.tTags[tTag.tagName][tTag.tagValue]
		local sTagStr = g_LM.line(tTagData.lc):gsub("^%l", string.upper)
		sName = sTagStr .. ' ' .. sName
	end
    return sName
end

function Inventory.canStack(tItemA,tItemB)
    return tItemA.sTemplate == tItemB.sTemplate and InventoryData.tTemplates[tItemA.sTemplate].bStackable
end

return Inventory
