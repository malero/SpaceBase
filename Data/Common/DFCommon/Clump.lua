local DFUtil = require('DFCommon.Util')
local DFFile = require('DFCommon.File')
local DFGraphics = require('DFCommon.Graphics')
local DFParticles = require('DFCommon.Particles')

local Clump = {}

-- CONSTRUCTOR --
function Clump.new( )
	
	-- PRE-CONSTRUCTOR --
    local self = DFUtil.deepCopy( Clump )	
    
	self.tAssets = {}
    
    return self
end

-- PUBLIC FUNCTIONS --
function Clump:addTexture( sFilename, sParentReference )
	
    return self:_addAsset(sFilename, sParentReference, "tex", "texture", true)
end

function Clump:addCompoundTexture( sFilename, sParentReference )
	
    return self:_addAsset(sFilename, sParentReference, "lua", "compoundTexture", true)
end

function Clump:addSpriteSheet( sFilename, sParentReference )
	
    local sNormFilename = DFFile.stripSuffix(sFilename)
    sNormFilename = sNormFilename .. ".lua"
    
    return self:_addAsset(sNormFilename, sParentReference, "lua", "spriteSheet", true)
end

function Clump:addShader( sFilename, sParentReference )

    return self:_addAsset(sFilename, sParentReference, "shd", "shader", true)
end

function Clump:addMaterial( sFilename, sParentReference )
	
    local rAssetRef = self:_addAsset(sFilename, sParentReference, "material", "material", false)
    if rAssetRef ~= nil then
    
        local rMaterial = DFGraphics.loadMaterial(sFilename)
        local sID = rAssetRef:getFilename()
        
        -- Add shader reference
        if rMaterial.shader ~= nil then
            self:addShader(rMaterial.shader.path, sID)
        end
        
        -- Add texture references
        if rMaterial.textures ~= nil then
            local numTextures = #rMaterial.textures
            for i=1,numTextures do
                local rTexture = rMaterial.textures[i]
                self:addTexture(rTexture.path, sID)
            end
        end
        
        DFGraphics.unloadMaterial(rMaterial)
    end
    
    return rAssetRef
end

function Clump:addMaterialModifier( sFilename, sParentReference )

    return self:_addAsset(sFilename, sParentReference, "matmod", "materialModifier", false)
end
function Clump:addParticleSystem( sFilename, sParentReference )

    local rAssetRef = self:_addAsset(sFilename, sParentReference, "particles", "particles", true)
    if rAssetRef ~= nil then
    
        local rParticleData = DFParticles.loadParticleData(sFilename)
        local sID = rAssetRef:getFilename()
        
        -- Add material
        if rParticleData.material ~= nil then
            if type(rParticleData.material) == "string" then
                self:addMaterial(rParticleData.material, sID)
            else
                self:addMaterial(rParticleData.material.path, sID)
            end
        end
        
        -- Add texture
        if rParticleData.texture ~= nil then
            if type(rParticleData.texture) == "string" then
                self:addTexture(rParticleData.texture, sID)
            else
                self:addTexture(rParticleData.texture.path, sID)
            end
        end
        
        DFParticles.unloadParticleData(sFilename)
    end
end

function Clump:addEffect( sFilename, sParentReference )

    return self:_addAsset(sFilename, sParentReference, "effect", "effect", true)
end

function Clump:addRig( sFilename, sParentReference )

    return self:_addAsset(sFilename, sParentReference, "rig", "rig", true)
end

function Clump:addAnimation( sFilename, sParentReference )

    return self:_addAsset(sFilename, sParentReference, "anim", "animation", true)
end

function Clump:addCameraAnimation( sFilename, sParentReference )

    return self:_addAsset(sFilename, sParentReference, "canim", "cameraAnimation", true)
end

function Clump:addStance( sFilename, sParentReference )

    return self:_addAsset(sFilename, sParentReference, "stance", "stance", false)
end

function Clump:addCutscene( sFilename, sParentReference )

    return self:_addAsset(sFilename, sParentReference, "ctsn", "cutscene", true)
end

function Clump:addLuaData( sFilename, sParentReference, sExtension, sDataType )

    local sExt = sExtension or "lua"
    local sDatTyp = sDataType or "lua"
    return self:_addAsset(sFilename, sParentReference, sExt, sDatTyp, false)
end

function Clump:getAssetRef( sFilename, sParentReference )

    for sAssetType, tAssetRefs in pairs(self.tAssets) do
        for _, rAssetRef in pairs(tAssetRefs) do
            if rAssetRef:equals(sFilename, sParentReference) then
                return rAssetRef
            end
        end
    end
    
    return nil
end

function Clump:containsAsset( sFilename, sParentReference )

    local rAssetRef = self:getAssetRef(sFilename, sParentReference)
    if rAssetRef then
        return true
    else
        return false
    end
end

function Clump:write(clumpFile)

    for sAssetType, tAssetRefs in pairs(self.tAssets) do
        for _, rAssetRef in pairs(tAssetRefs) do
            rAssetRef:write(clumpFile)
        end
    end
end

function Clump:print()

    for sAssetType, tAssetRefs in pairs(self.tAssets) do
    
        Trace("Asset type: " .. sAssetType)
        for _, rAssetRef in pairs(tAssetRefs) do
            rAssetRef:print()
        end
    end
end

-- PROTECTED FUNCTIONS --
function Clump:_addAsset( sFilename, sParentReference, sDefaultExtension, sAssetType, bIsPlatformSpecific )

    if sFilename == nil then return nil end
    if #sFilename <= 0 then return nil end
    
    local sNormFilename = self:_getNormalizedPath(sFilename, sDefaultExtension)
    
    if bIsPlatformSpecific then
        sNormFilename = "Munged/" .. sNormFilename
    else
        sNormFilename = "Data/" .. sNormFilename
    end
    
    if self:containsAsset(sNormFilename, sParentReference) then return nil end
    
    local rAssetRef = self:_getAssetRef(sAssetType, sNormFilename)
    rAssetRef:addParentReference(sParentReference)
    
    return rAssetRef
end

function Clump:_getNormalizedPath( sFilename, sDefaultExtension )

    local sExtension = DFFile.getSuffix(sFilename)
    if sExtension == nil or #sExtension <= 0 then
        sFilename = sFilename .. "." .. sDefaultExtension
    end
    
    return sFilename
end

function Clump:_getAssetRef( sAssetType, sFilename )

    if self.tAssets[sAssetType] == nil then
        self.tAssets[sAssetType] = {}
    end
    local tAssetTypes = self.tAssets[sAssetType]
    
    if tAssetTypes[sFilename] == nil then
    
        local rAssetRef = {}
        
        function rAssetRef:_init( sFilename )
            self.sAssetType = sAssetType
            self.sFilename = sFilename
            self.tParentReferences = {}
        end
        
        function rAssetRef:getFilename()
            return self.sFilename
        end
        
        function rAssetRef:addParentReference( sParentReference )
            if self.tParentReferences[sParentReference] == nil then
                self.tParentReferences[sParentReference] = true
            end
        end
        
        function rAssetRef:equals( sFilename, sParentReference )
            if self.sFilename == sFilename then
                if sParentReference then
                    if self.tParentReferences[sParentReference] then
                        return true
                    end
                else
                    return true
                end
            end
            return false
        end
        
        function rAssetRef:write(clumpFile)
            clumpFile:write(self.sAssetType .. ":" .. self.sFilename .. "\n")
            for sRef, _ in pairs(self.tParentReferences) do
                clumpFile:write("-> " .. sRef .. "\n")
            end
        end
        
        function rAssetRef:print()
            Trace(self.sFilename)
            Trace("Referenced by: ")
            for sRef, _ in pairs(self.tParentReferences) do
                Trace("  " .. sRef)
            end
        end
    
        rAssetRef:_init(sFilename)
        
        tAssetTypes[sFilename] = rAssetRef
    end
    
    return tAssetTypes[sFilename]
end

return Clump