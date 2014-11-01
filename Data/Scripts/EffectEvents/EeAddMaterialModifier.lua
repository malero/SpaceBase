local Util = require('DFCommon.Util')
local DFDataCache = require('DFCommon.DataCache')
local DFFile = require('DFCommon.File')
local DFGraphics = require('DFCommon.Graphics')
local Class = require('Class')
local SeqCommand = require('SeqCommand')
local EffectEvent = require('EffectEvent')
local EeAddMaterialModifier = Class.create(EffectEvent)

local EeCreateParticleSystem = require('EffectEvents.EeCreateParticleSystem')

-- ATTRIBUTES --
EeAddMaterialModifier.Name = nil
EeAddMaterialModifier.MaterialMod = nil

local DFSchema = require('DFCommon.DFSchema')
local tFields = Util.deepCopy(EffectEvent.rSchema.tFieldSchemas)
tFields['Name'] = DFSchema.string(nil, "Name of the material modifier, so it can be stopped later")
tFields['MaterialMod'] = DFSchema.resource(nil, 'Data', '.matmod', "The path to the material modifier")

EeAddMaterialModifier.rSchema = DFSchema.object(
	tFields,
	"Adds a material modifier to the specified materials."
)
SeqCommand.addEditorSchema('EeAddMaterialModifier', EeAddMaterialModifier.rSchema)

-- VIRTUAL FUNCTIONS --
function EeAddMaterialModifier:onExecute()
	
    if not self.rEffect.rEntity then
    
        if self:_getDebugFlags().DebugLoading then
            Trace("Effect isn't attached to a entity, can't apply material modifier!")
        end
    else
    
        -- Get all the materials to modify
        local tAllMaterials = {}
    
        local rEntity = self.rEffect.rEntity
        if rEntity.CoRig ~= nil then
        
            local tMaterials = rEntity.CoRig:getMaterials()
            local numMaterials = #tMaterials
            for i=1,numMaterials do
                table.insert(tAllMaterials, tMaterials[i])
            end
        else
        
            -- ToDo: Implement CoTexture, CoCompoundTexture, ...
            Trace("Entity doesn't support material modifiers!")
        end
    
        self:_applyMaterialMods(tAllMaterials)
    end
end

function EeAddMaterialModifier:onCleanup()

    self:_clearMaterialMod()
end

function EeAddMaterialModifier:isDone()

    return true
end

-- PROTECTED FUNCTIONS --
function EeAddMaterialModifier:_applyMaterialMods(tMaterials)

    assert(self.tMaterials == nil)
    self.tMaterials = {}
    
    assert(self.tLoadedTextures == nil)
    self.tLoadedTextures = {}
    
    local numMaterials = #tMaterials
    if numMaterials <= 0 then
        return
    end
    
    if self.MaterialMod ~= nil and #self.MaterialMod > 0 then
    
        local filePath = DFFile.getDataPath( self.MaterialMod )
        local tData = DFDataCache.getData( "matmod", filePath )
        if not tData then 
            Print(TT_Error, "Failed to load material modifier at ", self.MaterialMod, filePath )
            return 
        end
        
        self.sModifierSetName = self.MaterialMod
        
        -- Create the look-up table if necessary
        if tData.tMaterialSelectorLUT == nil then
            tData.tMaterialSelectorLUT = {}
            if tData.tMaterialSelector ~= nil then
                local numSelectors = #tData.tMaterialSelector
                for i=1,numSelectors do
                    tData.tMaterialSelectorLUT[tData.tMaterialSelector[i]] = true
                end
            end
        end
    
        -- Apply the modifier to the selected materials
        for i=1,numMaterials do
        
            local rMaterial = tMaterials[i]
            local sMaterialPath = rMaterial.path
            
            local bAccept = true
            if tData.bExcludingSelector == false then
                -- Include materials
                bAccept = false
                if tData.tMaterialSelectorLUT[sMaterialPath] ~= nil then
                    bAccept = true
                end
            else
                -- Exclude materials
                bAccept = true
                if tData.tMaterialSelectorLUT[sMaterialPath] ~= nil then
                    bAccept = false
                end
            end
            
            if bAccept then
                table.insert(self.tMaterials, rMaterial)
                self:_applyMaterialMod(rMaterial, tData)
            end
        end
        
    else
    
        if self:_getDebugFlags().DebugLoading then
            Trace("No material modifier specified!")
        end
    end
end

function EeAddMaterialModifier:_applyMaterialMod(rMaterial, tModData)

    if tModData.tColor ~= nil then
        local tData = tModData.tColor
        local r,g,b,a = unpack(tData.tValue)
        rMaterial:setColorMod(self.sModifierSetName, r, g, b, a, tData.fadeIn, tData.fadeOut, tData.animMode, tData.animRate, tData.animScale)
    end
    
    if tModData.sTexture ~= nil then
        local rTexture = DFGraphics.loadTexture(tModData.sTexture)
		if not rTexture then
            Print(TT_Warning, "Failed to load texture: ", tModData.sTexture )
        else
            table.insert(self.tLoadedTextures, tModData.sTexture)
            rMaterial:setTextureMod(self.sModifierSetName, rTexture)
        end
    end
    
    if tModData.tShaderValues ~= nil then
        local tData = tModData.tShaderValues
        local numShaderValues = #tData
        for i=1,numShaderValues do
            local tValMod = tData[i]
            rMaterial:setColorMod(self.sModifierSetName, tValMod.tValue, tData.fadeIn, tData.fadeOut, tData.animMode, tData.animRate, tData.animScale)
        end
    end
    
    if tModData.tPermutationFlags ~= nil then
        local tData = tModData.tPermutationFlags
        for sName, bFlag in pairs(tData) do
            rMaterial:setPermutationFlagMod(self.sModifierSetName, sName, bFlag)
        end
    end
    
    if tModData.tPermutationSwitches ~= nil then
        -- ToDo: Implement
        assert(0)
    end
end

function EeAddMaterialModifier:_clearMaterialMod()

    if self.tMaterials ~= nil then
    
        local numMaterials = #self.tMaterials
        for i=1,numMaterials do
            local rMaterial = self.tMaterials[i]
            rMaterial:clearModifierSet(self.sModifierSetName)
        end
    
        self.tMaterials = nil
    end
    
    if self.tLoadedTextures ~= nil then
    
        local numTextures = #self.tLoadedTextures
        for i=1,numTextures do
            local sTexture = self.tLoadedTextures[i]
            DFGraphics.unloadTexture(sTexture)
        end
    
        self.tLoadedTextures = nil
    end
end

return EeAddMaterialModifier
