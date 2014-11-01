local DFGraphics = require('DFCommon.Graphics')
local DFParticles = require('DFCommon.Particles')
local DFFile = require('DFCommon.File')
local DFUtil = require('DFCommon.Util')
local DFDataCache = require('DFCommon.DataCache')

local AssetSet = {}

-- CONSTRUCTOR --
function AssetSet.new( )
	
	-- PRE-CONSTRUCTOR --
    local self = DFUtil.deepCopy( AssetSet )	
    
	self.tLoadedTextures = {}
	self.tLoadedSpriteSheets = {}
	self.tLoadedParticles = {}
    
    return self
end

-- PUBLIC FUNCTIONS --
function AssetSet:unload()
	
	-- ToDo: Make it possible to unload a asset-set that is being loaded
	assert(self:isLoaded())
		
	for sFilename, _ in pairs(self.tLoadedTextures) do
		DFGraphics.unloadTexture( sFilename )
	end
	self.tLoadedTextures = {}
	
	for sFilename, _ in pairs(self.tLoadedSpriteSheets) do
		DFGraphics.unloadSpriteSheet( sFilename )
	end
	self.tLoadedSpriteSheets = {}
    
	for sFilename, _ in pairs(self.tLoadedParticles) do
		DFParticles.unloadParticleData( sFilename )
	end
	self.tLoadedParticles = {}
end

function AssetSet:loadClump( sFilename )

    if MOAIFileSystem.checkFileExists(sFilename) then
    
        local tData = DFDataCache.getData("clump", sFilename)
        if tData then
            
            if tData.tTextures then
                local numTextures = #tData.tTextures
                for i=1,numTextures do
                    
                    local sAssetFilename = tData.tTextures[i]
                    self:preloadTexture(sAssetFilename)
                end
            end
            
            if tData.tSpriteSheets then
                local numSpriteSheets = #tData.tSpriteSheets
                for i=1,numSpriteSheets do
                    
                    local sAssetFilename = tData.tSpriteSheets[i]
                    self:preloadSpriteSheet(sAssetFilename)
                end
            end
            
            if tData.tParticles then
                local numPartilces = #tData.tParticles
                for i=1,numPartilces do
                    
                    local sAssetFilename = tData.tParticles[i]
                    self:preloadParticles(sAssetFilename)
                end
            end
        end
    end
end

function AssetSet:preloadTexture( sFilename )
	
	if self.tLoadedTextures[sFilename] == nil then
		self.tLoadedTextures[sFilename] = DFGraphics.loadTexture( sFilename, true )
	end
	return self.tLoadedTextures[sFilename]
end

function AssetSet:preloadSpriteSheet( sFilename )

	if self.tLoadedSpriteSheets[sFilename] == nil then
		self.tLoadedSpriteSheets[sFilename] = DFGraphics.loadSpriteSheet( sFilename, true )
	end
	return self.tLoadedSpriteSheets[sFilename]
end

function AssetSet:preloadParticles( sFilename )

	if self.tLoadedParticles[sFilename] == nil then
		self.tLoadedParticles[sFilename] = DFParticles.loadParticleData( sFilename )
	end
	return self.tLoadedParticles[sFilename]
end

function AssetSet:isLoaded()

	for _, rTexture in pairs(self.tLoadedTextures) do
		if not rTexture:isLoaded() then
			return false
		end
	end
	
	for _, rSpriteSheet in pairs(self.tLoadedSpriteSheets) do
		if not rSpriteSheet.texture:isLoaded() then
			return false
		end
	end
	
	return true
end

function AssetSet:getFailedFiles()

	local tFailed = {}
	
	for sFilename, rTexture in pairs(self.tLoadedTextures) do
		if rTexture:isLoaded() and not rTexture:loadSucceeded() then
			table.insert(tFailed, sFilename)
		end
	end
	
	for sFilename, rSpriteSheet in pairs(self.tLoadedSpriteSheets) do
		if rSpriteSheet.texture:isLoaded() and not rSpriteSheet.texture:loadSucceeded() then
			table.insert(tFailed, sFilename)
		end
	end
	
	return tFailed
	
end

function AssetSet:getMissingFiles()

	local sMissing = ""
	
	for sFilename, rTexture in pairs(self.tLoadedTextures) do
		if not rTexture:isLoaded() then
			sMissing = sMissing .. "TEXTURE: " .. sFilename .. "\n"
		end
	end
	
	for sFilename, rSpriteSheet in pairs(self.tLoadedSpriteSheets) do
		if not rSpriteSheet.texture:isLoaded() then
			sMissing = sMissing .. "SPRITESHEET: " .. sFilename .. "\n"
		end
	end
	
	return sMissing
end

return AssetSet