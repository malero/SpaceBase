local DFFile = require("DFCommon.File")
local DFUtil = require("DFCommon.Util")
local DFMath = require("DFCommon.Math")
local DFDataCache = require('DFCommon.DataCache')
local DFMoaiDebugger = require("DFMoai.Debugger")

-- "m" for "module"
local m = {}

m.defaultMinFilter = MOAITexture.GL_LINEAR
m.defaultMagFilter = MOAITexture.GL_LINEAR
m.defaultWrapMode = false

m.textureLibrary = {}
m.spriteLibrary = {}
m.fontLibrary = {}
m.shaderLibrary = {}
m.materialLibrary = {}

if MOAIEnvironment.osBrand == "iOS" then
	m.textureExtensions = { ".tex", ".pvr.gz", ".pvr", ".png" }
elseif MOAIEnvironment.osBrand == "Windows" or MOAIEnvironment.osBrand == "OSX" or MOAIEnvironment.osBrand == "Linux" then
	m.textureExtensions = { ".tex", ".dds", ".png" }
elseif MOAIEnvironment.osBrand == "Android" then
	m.textureExtensions = { ".tex", ".ktx", ".atc", ".dds", ".pvr.gz", ".pvr", ".png" }
else
	m.textureExtensions = { ".tex", ".png" }
end
m.numTextureExtensions = #m.textureExtensions

-- width and height determine the actual window size on PC,
-- or the orientation (landscape vs portrait) on mobile
function m.createWindow(name, width, height, resizeCallback)    
    if MOAIEnvironment.osBrand ~= "iOS" then
        MOAISim.openWindow( name, width, height )
    end

    -- viewports    
    -- MOAIViewport has no getters, so pack the data in for easier access.
    -- NSM: Maybe we should add those accessors?
    m.gameViewport = MOAIViewport.new()
    m.gameViewport.sizeX, m.gameViewport.sizeY = MOAIGfxDevice.getViewSize()
    m.gameViewport:setSize( m.gameViewport.sizeX, m.gameViewport.sizeY )    
    
    m.uiViewport = MOAIViewport.new()
    m.uiViewport.sizeX, m.uiViewport.sizeY = MOAIGfxDevice.getViewSize()
    m.uiViewport:setSize( m.uiViewport.sizeX, m.uiViewport.sizeY )
    -- UI viewport is pixel scale by default
    m.uiViewport:setScale( m.uiViewport.sizeX, m.uiViewport.sizeY )
    
    MOAIGfxDevice.setListener( MOAIGfxDevice.EVENT_RESIZE, m.onResize )
    
    m.resizeCallback = resizeCallback
      
    return m.gameViewport, m.uiViewport
end

function m.onResize(width, height)
    m.gameViewport:setSize( width, height ) 
    m.gameViewport.sizeX = width
    m.gameViewport.sizeY = height
    m.uiViewport:setSize( width, height ) 	 
    m.uiViewport:setScale( width, height )
    m.uiViewport.sizeX = width
    m.uiViewport.sizeY = height
    
    if m.resizeCallback ~= nil then
        m.resizeCallback(width, height)
    end
end

function m.dumpTextures(sDumpTag)

    local totalEstimatedSize = 0
    
    local fileDump = "PATH,WIDTH,HEIGHT,FORMAT,SIZE(KB)\n"
    
    -- simple iterator generator used to sort the table by its keys (allows us to get easily diffable output
    --  in this dump)
    local function pairsByKeys (t, f)
      local a = {}
      for n in pairs(t) do table.insert(a, n) end
      table.sort(a, f)
      local i = 0      -- iterator variable
      local iter = function ()   -- iterator function
        i = i + 1
        if a[i] == nil then return nil
        else return a[i], t[a[i]]
        end
      end
      return iter
    end
    
    print("\n\n--------------------------------------------------------")
    print("Dump Textures, tag: " .. sDumpTag)
    print("--------------------------------------------------------\n")
    
    for k,texture in pairsByKeys(m.textureLibrary) do
        local width, height = texture:getSize()
        local compression = nil or texture:getCompression()
        local compressionString = "RGBA"
        local compressionEstimate = 4
        if compression == MOAITexture.CTEX_TYPE_DDS then
            compressionString = "DDS"
            compressionEstimate = 2
        elseif compression == MOAITexture.CTEX_TYPE_PVR then
            compressionString = "PVR"
            compressionEstimate = 1
        end
        local estimatedSize = width * height * compressionEstimate / 1024
        totalEstimatedSize = totalEstimatedSize + estimatedSize
        
        fileDump = fileDump .. tostring(k) .. "," .. width .. "," .. height .. "," .. compressionString .. "," .. tostring(estimatedSize) .. "," 
        fileDump = fileDump .. "\n"
        print(tostring(k) .. ": " .. width .. "x" .. height .. " " .. compressionString .. " ~ " .. tostring(estimatedSize) .. "KB" ) 
    end
    
    print("\n--------------------------------------------------------")
    print("Total estimated size (KB): " .. totalEstimatedSize)
    print("--------------------------------------------------------\n")
   
   
    local dumpDir = MOAIEnvironment.documentDirectory .. "/Dumps/"
    MOAIFileSystem.affirmPath(dumpDir)
    local dataBuffer = MOAIDataBuffer.new()
    dataBuffer:setString( fileDump )
    dataBuffer:save( dumpDir .. sDumpTag .. "_" ..os.time() .. ".csv", false )
end

function m.setDefaultTextureFilter(minFilter, magFilter)
    m.defaultMinFilter = minFilter
    m.defaultMagFilter = magFilter
end

function m.reloadTextureData(texturePath, loadAsynchronously)
    local tex = m.textureLibrary[texturePath]
    if tex then
	
		filePath = DFFile.getSpritePath(texturePath)
		
		-- Is this a anonymous file?
		if not MOAIFileSystem.checkFileExists(filePath) then
			
			-- Extension priority list: .pvr.gz | .pvr | .png
			local tempPath
			for i=1,m.numTextureExtensions do
				tempPath = string.format("%s%s", filePath, m.textureExtensions[i])
				if MOAIFileSystem.checkFileExists(tempPath) then
					filePath = tempPath
					break
				end
			end
		end
        
        -- Load the texture parameters
        local paramsFile = filePath .. ".texparams"
		if MOAIFileSystem.checkFileExists(paramsFile) then
            local tTexParams = DFDataCache.getData("texparams", paramsFile)
            if tTexParams ~= nil then
            
                local minFilter = tTexParams.minfilter or m.defaultMinFilter
                local magFilter = tTexParams.magfilter or m.defaultMagFilter
                tex:setFilter( minFilter, magFilter )
                
                local wrapMode = tTexParams.wrapmode or m.defaultWrapMode
                tex:setWrap( wrapMode )
            end
        end
	
		-- All textures use pre-multiplied alpha
		if loadAsynchronously then
			tex:loadAsync( filePath, MOAIImage.TRUECOLOR )
		else
			if string.sub(filePath,-3) == ".gz" then
            	local buffer = MOAIDataBuffer.new()
            	buffer:load( filePath )
            	buffer:inflate(31)
            	tex:load( buffer, MOAIImage.TRUECOLOR )
            else
				tex:load( filePath, MOAIImage.TRUECOLOR )
			end
            
            -- This can cause a race condition where the load code already affirms the texture, which then makes the second call fail
            --[[
			-- On Android affirm() should only be called on the render-thread!
			if MOAIEnvironment.osBrand ~= "Android" and tex.affirm ~= nil then
				tex:affirm()
			end]]
		end
    end
end

function m.loadTexture(texturePath, loadAsynchronously)
    local texAssetPath = m.getNormalizedAssetPath( texturePath )
    local tex = m.textureLibrary[texAssetPath]
    if tex == nil then
        tex = MOAITexture.new()
        tex.path = texAssetPath
        tex:setFilter(m.defaultMinFilter, m.defaultMagFilter)
        tex.refCount = 1
        m.textureLibrary[texAssetPath] = tex
        m.reloadTextureData(texAssetPath, loadAsynchronously)
    else
        tex.refCount = tex.refCount + 1
    end
    return tex
end

function m.unloadTexture(texturePath)
    local texAssetPath = m.getNormalizedAssetPath( texturePath )
    local tex = m.textureLibrary[texAssetPath]
    if tex ~= nil then
        tex.refCount = tex.refCount - 1
        if tex.refCount == 0 then
            tex:release()
            m.textureLibrary[texAssetPath] = nil
        end
    end    
end

function m.blockOnAsyncTextureLoad()    
    while true do
        local allLoaded = true
        for k, v in pairs (m.textureLibrary) do
            if not v:isLoaded() then
                allLoaded = false
                break
            end
        end
        if allLoaded then
            break
        else
            DFUtil.sleep(0.01)
        end
    end
end

function m.dumpTextures(dumpTag)
    local fileDump = "PATH,WIDTH,HEIGHT,FORMAT,SIZE(KB)\n"
    for k,texture in pairs(m.textureLibrary) do
        local width, height = texture:getSize()
        local compression = nil texture:getCompression()
        local compressionString = "RGBA"
        local compressionEstimate = 4
        if compression == MOAITexture.CTEX_TYPE_DDS then
            compressionString = "DDS"
            compressionEstimate = 2
        elseif compression == MOAITexture.CTEX_TYPE_PVR then
            compressionString = "PVR"
            compressionEstimate = 1
        end
        local estimatedSize = width * height * compressionEstimate / 1024
        fileDump = fileDump .. tostring(k) .. "," .. width .. "," .. height .. "," .. compressionString .. "," .. tostring(estimatedSize) .. "," 
        fileDump = fileDump .. "\n"
        print(tostring(k) .. ": " .. width .. "x" .. height .. " " .. compressionString .. " ~ " .. tostring(estimatedSize) .. "KB" ) 
    end
    
    local dumpDir = MOAIEnvironment.documentDirectory .. "/Dumps/"
    MOAIFileSystem.affirmPath(dumpDir)
    local dataBuffer = MOAIDataBuffer.new()
    dataBuffer:setString( fileDump )
    dataBuffer:save( dumpDir .. dumpTag .. "_" ..os.time() .. ".csv", false )
end

function m.spritesheetExists(spritePath)
    spritePath = DFFile.stripSuffix(spritePath)
    local sFilePath = DFFile.getSpritePath(spritePath .. ".lua")
    return MOAIFileSystem.checkFileExists(sFilePath)
end

-- skipRects: a hack to allow sprite sheets to work with grids; prevents sprite rect from being modified. Changelist 588705.
function m.loadSpriteSheet(spritePath, loadAsynchronously, loadClipGeo, skipRects)
    if spritePath == nil then
        return nil
    end
    
    spritePath = DFFile.stripSuffix(spritePath)
    
    local spriteSheet = m.spriteLibrary[spritePath]
    if spriteSheet ~= nil then
        -- Todo: assert that loadClipGeo corresponds to the sprite sheet type
        spriteSheet.refCount = spriteSheet.refCount + 1
        return spriteSheet
    end
    
    local data = dofile( DFFile.getSpritePath(spritePath .. ".lua") )
    if not data then 
        Print(TT_Error, "Failed to load sprite sheet at",spritePath,DFFile.getSpritePath(spritePath .. ".lua") )
        return 
    end
    
    local clipGeo = nil
    if loadClipGeo then
        local DFGeo = require "DFCommon.Geo"
        local clipPath = DFFile.getDataPath(spritePath .. ".geo")
        clipGeo = DFGeo.load( clipPath )
        if not clipGeo then
            Print(TT_Error, "Failed to load clip geometry for sprite sheet at ", clipPath)
            return
        end
    end

    local texPath = (string.find(spritePath, "/") and string.gsub(spritePath, "%/[_%w]+$", "/")..data.texture) or data.texture
    local tex = m.loadTexture(texPath, loadAsynchronously)

    if tex then
        local frames = data.frames
        -- Construct the deck
        if not clipGeo then
            spriteSheet = MOAIGfxQuadDeck2D.new()
        else
            spriteSheet = MOAIMeshDeck.new()
            spriteSheet.clipGeo = clipGeo
            spriteSheet.geoVertices, spriteSheet.geoIndices = clipGeo:createBuffers()
            spriteSheet:setPrimType(MOAIMesh.GL_TRIANGLES)
            spriteSheet:setVertexBuffer(spriteSheet.geoVertices)
            spriteSheet:setIndexBuffer(spriteSheet.geoIndices)
        end
        spriteSheet.skipRects = skipRects
        spriteSheet.path = spritePath
        spriteSheet.texture = tex
        spriteSheet:setTexture( tex )
        spriteSheet:reserve( #frames )
        spriteSheet.names = {}
        spriteSheet.rects = {}  
        spriteSheet.refCount = 1
    
        -- Annotate the frame array with uv quads and geometry rects
        for i, frame in ipairs( frames ) do
            -- convert frame.uvRect to frame.uvQuad to handle rotation
            local uv = frame.uvRect
            
            -- convert frame.spriteColorRect and frame.spriteSourceSize
            -- to frame.geomRect.  Origin is at x0,y0 of original sprite
            local r = {}
            if frame.spriteTrimmed then
                local cr = frame.spriteColorRect
                r.x0 = cr.x
                r.y0 = frame.spriteSourceSize.height - cr.y - cr.height
                r.x1 = cr.x + cr.width
                r.y1 = r.y0 + cr.height
                r.width = cr.width
                r.height = cr.height
                r.origWidth = frame.spriteSourceSize.width
                r.origHeight = frame.spriteSourceSize.height
            else
                r.x0 = 0
                r.y0 = 0
                r.x1 = frame.spriteSourceSize.width
                r.y1 = frame.spriteSourceSize.height
                r.width = frame.spriteSourceSize.width
                r.height = frame.spriteSourceSize.height
                r.origWidth = frame.spriteSourceSize.width
                r.origHeight = frame.spriteSourceSize.height
            end

            if not clipGeo then
                local q = {}
                if not frame.textureRotated then
                    -- From Moai docs: "Vertex order is clockwise from upper left (xMin, yMax)"
                    q.x0, q.y0 = uv.u0, uv.v0
                    q.x1, q.y1 = uv.u1, uv.v0
                    q.x2, q.y2 = uv.u1, uv.v1
                    q.x3, q.y3 = uv.u0, uv.v1
                else
                    -- Sprite data is rotated 90 degrees CW on the texture
                    -- u0v0 is still the upper-left
                    q.x3, q.y3 = uv.u0, uv.v0
                    q.x0, q.y0 = uv.u1, uv.v0
                    q.x1, q.y1 = uv.u1, uv.v1
                    q.x2, q.y2 = uv.u0, uv.v1
                end
                spriteSheet:setUVQuad( i, q.x0,q.y0, q.x1,q.y1, q.x2,q.y2, q.x3,q.y3 )
                if not skipRects then
                    spriteSheet:setRect( i, r.x0,r.y0, r.x1,r.y1 )
                end
            else                
                -- Set the index range for this sprite
                local firstIndex, lastIndex = clipGeo:getIndexRange( i )
                spriteSheet:setIndexRange( i, firstIndex, lastIndex )
                
                local newUV = {}
                if frame.spriteTrimmed then
                    -- Remap: we pass the full world rect to the GeoEdit tool (as 'tRect'), to allow for full sprite relative alignment.
                    -- Which causes it to generate UVs relative to that full rect, and not the trimmed rect.
                    -- Translate (negative) and scale up the target UV range, so that the larger but smaller-ranged coords
                    -- from the subrect will correctly map to the same UV range.
                    local sclX, sclY = r.origWidth/r.width, r.origHeight/r.height
                    local uvW, uvH = uv.u1-uv.u0, uv.v1-uv.v0
                    local pixToUVX,pixToUVY = uvW/r.width, uvH/r.height

                    newUV.u0 = uv.u0 - r.x0*pixToUVX
                    newUV.u1 = newUV.u0+(uv.u1-uv.u0)*sclX
                    -- use origHeight-y1 (as opposed to using y0) because texture packer's
                    -- coords are top-relative.
                    newUV.v0 = uv.v0 - (r.origHeight-r.y1)*pixToUVY
                    newUV.v1 = newUV.v0+(uv.v1-uv.v0)*sclY
                else
                    newUV.u0 = uv.u0
                    newUV.u1 = uv.u1
                    newUV.v0 = uv.v0
                    newUV.v1 = uv.v1
                end
                -- Create a UV transform to scale the geo uvs correctly
                local uvTransform = MOAITransform.new()
                if not frame.textureRotated then
                    uvTransform:setLoc( newUV.u0, newUV.v0 )
                    uvTransform:setScl( newUV.u1 - newUV.u0, newUV.v1 - newUV.v0 )
                else
                    uvTransform:setLoc( newUV.u1, newUV.v0 )
                    uvTransform:setScl( newUV.v1 - newUV.v0, newUV.u1 - newUV.u0 )
                    uvTransform:setRot( 0, 0, 90 )
                end
                spriteSheet:setUVTransform( i, uvTransform )
            end
            spriteSheet.names[ DFFile.stripSuffix( frame.name ) ] = i
            spriteSheet.rects[i] = r
        end
        
         m.spriteLibrary[spritePath] = spriteSheet
        return spriteSheet
    else
        Print(TT_Error, "Failed to load texture at",texPath)
    end    
end

function m.unloadSpriteSheet(spritePath)
    local spriteSheet = m.spriteLibrary[spritePath]
    if spriteSheet ~= nil then
        spriteSheet.refCount = spriteSheet.refCount - 1
        if spriteSheet.refCount == 0 then
            m.unloadTexture(spriteSheet.texture.path)
            m.spriteLibrary[spritePath] = nil
        end
    end 
end

function m.newSprite3D(spritePath, layerRef, deckRef, x, y, z)
    deckRef = deckRef or layerRef.deck
    if type(deckRef) == "string" then 
        deckRef = m.loadSpriteSheet(deckRef)
        assert(deckRef)
    end
    local idx = deckRef.names[spritePath]

    local sprite = MOAIProp.new()    
    sprite.spritePath = spritePath
    sprite:setDeck(deckRef)
    sprite:setIndex(idx)
    if type(layerRef) == "table" then
        layerRef.layer:insertProp(sprite)
    else
        layerRef:insertProp(sprite)
    end

    if x and y and z then sprite:setLoc(x,y,z) end

    return sprite,deckRef
end

function m.newSprite(spritePath, layerRef, deckRef, x, y)
    deckRef = deckRef or layerRef.deck
    if type(deckRef) == "string" then 
        deckRef = m.loadSpriteSheet(deckRef)
        assert(deckRef)
    end
    local idx = deckRef.names[spritePath]

    local sprite = MOAIProp2D.new()    
    sprite.spritePath = spritePath
    sprite:setDeck(deckRef)
    sprite:setIndex(idx)
    if type(layerRef) == "table" then
        layerRef.layer:insertProp(sprite)
    else
        layerRef:insertProp(sprite)
    end

    if x and y then sprite:setLoc(x,y) end

    return sprite,deckRef
end

function m.getFullSpriteDims(deck,name)
    local r = deck.rects[ deck.names[name] ]
    return r.origWidth, r.origHeight
end

function m.alignSprite(deck, name, xAlign, yAlign, nScaleX, nScaleY)
    if type(deck) == 'string' then deck = m.spriteLibrary[deck] end
    local index = deck.names[name]
    if index ~= nil then
    
       if xAlign == deck.rects[index].xAlign and
          yAlign == deck.rects[index].yAlign then
          return
        end
    
        local r = {}
        for k, v in pairs(deck.rects[index]) do
            r[k] = v
        end
                               
        if xAlign == "right" then
            r.x0 = math.floor(r.x0 - r.origWidth)
            r.x1 = math.floor(r.x1 - r.origWidth)
        elseif xAlign == "center" then
            r.x0 = math.floor(r.x0 - r.origWidth * 0.5)
            r.x1 = math.floor(r.x1 - r.origWidth * 0.5)
        elseif xAlign == "left" then
            -- no change
        else
            assert(false)
        end
        
        if yAlign == "top" then
            r.y0 = math.floor(r.y0 - r.origHeight)
            r.y1 = math.floor(r.y1 - r.origHeight)
        elseif yAlign == "center" then
            r.y0 = math.floor(r.y0 - r.origHeight * 0.5)
            r.y1 = math.floor(r.y1 - r.origHeight * 0.5)
        elseif yAlign == "bottom" then
            -- no change
        else
            assert(false)
        end

        nScaleX = nScaleX or 1
        nScaleY = nScaleY or 1

        if not deck.clipGeo then
            if not deck.skipRects then
                deck:setRect( index, r.x0 * nScaleX, r.y0 * nScaleY, r.x1 * nScaleX, r.y1 * nScaleY )
            end
        else
            -- Todo: realign the mesh transform as well
            assert(false)
        end
        deck.rects[index].xAlign = xAlign
        deck.rects[index].yAlign = yAlign
    end
end

function m.loadFont(sFontName)
    local font = m.fontLibrary[sFontName]
    if font == nil then
        font = MOAIFont.new()
        if string.find( sFontName, "font" ) then
        
            local sFontFilename = DFFile.getAssetPath(sFontName)
            local tFontData = DFDataCache.getData("font", sFontFilename)
            if tFontData then
                -- Preload the textures...
                font.tTextures = {}
                for _,sFontTextureFilename in ipairs(tFontData.tFontTextures) do
                    local sFontTextureFile = m.getAssetRelativeFilename(sFontName, sFontTextureFilename)
                    local rFontTexture = m.loadTexture( sFontTextureFile, true )
                    table.insert(font.tTextures, rFontTexture)
                end
                -- ...before constructing the font
                local sFntFilename = m.getAssetRelativeFilename(sFontName, tFontData.sFontFile)
                sFntFilename = DFFile.getAssetPath(sFntFilename)
                font:loadFromBMFont( sFntFilename, font.tTextures )
            
            else
                Trace( TT_Error, "Couldn't load font: " .. sFontName )
            end
            
        elseif string.find( sFontName, "fnt" ) then
            font:loadFromBMFont( DFFile.getFontPath(sFontName) )
        else
            font:load( DFFile.getFontPath(sFontName) )                
        end        
        font.refCount = 1
        m.fontLibrary[sFontName] = font
    else        
        font.refCount = font.refCount + 1
    end
    return font
end

function m.unloadFont(sFontName)
    local font = m.fontLibrary[sFontName]
    if font ~= nil then
        font.refCount = font.refCount - 1
        if font.refCount == 0 then
            if font.tTextures ~= nil then
                -- Unload the preloaded textures
                for _,rFontTexture in ipairs(font.tTextures) do
                    m.unloadTexture(rFontTexture.path)
                end
                -- Release the internals
                m.fontLibrary[sFontName] = nil
            else
                -- NSM: Curenntly no way to unload a font, so hack the refcount to 1
                font.refCount = 1
                -- font::release()
                -- m.fontLibrary[fontName] = nil
            end
        end
    end    
end

function m.reloadShaderData(shaderPath, clearCache)
    local shader = m.shaderLibrary[shaderPath]
    if shader ~= nil then
    
        local sBinaryFilenpath = DFFile.getAssetPath( shaderPath .. ".bshd" )
        if MOAIFileSystem.checkFileExists( sBinaryFilenpath ) then
        
            -- Load a binary shader
            shader:resetShader()
            shader:setShaderBinary(sBinaryFilenpath)
            
        else
            -- Load a Lua-based shader
            if clearCache == true then
                DFDataCache.clear( "shader" )
            end
        
            -- Load the actual shader data
            local rootPath = DFFile.stripFileName( shaderPath )
            local filePath = DFFile.getAssetPath( shaderPath )
            local shaderData = DFDataCache.getData( "shader", filePath .. ".shd" )
            if not shaderData then 
                Print(TT_Error, "Failed to load shader at ", shaderPath, filePath )
                return 
            end
            
            -- Step 1: Load shader source and permutations (if defined)
            shader:resetShader()
            shader:setRootFolder(DFFile.getAssetPath(rootPath))
            if shaderData.tShaderFiles then
                -- Load the different shader permutations
                local numShaders = #shaderData.tShaderFiles
                local numPrograms = #shaderData.tShaderPermutations.tPerms
                shader:initPermutations(numShaders, numPrograms)
                for i=1,numShaders do
                    shader:setPermutationShaderSource(i, shaderData.tShaderFiles[i], true)
                end
                -- Add the permutation features
                local tFeatures = shaderData.tShaderPermutations.tFeatures
                local numPermFeatures = #tFeatures
                for i=1,numPermFeatures do
                    shader:addPermutationFeature(tFeatures[i])
                end
                -- Bind the permutated shaders to all permutation states
                shader:bindPermutationShaders(shaderData.tShaderPermutations.tPerms)
            else
                -- Load regular shader
                shader:load(shaderData.sVertexShader, shaderData.sFragmentShader, true)
            end
            
            -- Step 2: Specify the names of the attributes
            local tVertexAttrs = shaderData.tVertexAttributes
            local numVertexAttributes = #tVertexAttrs
            for i=1,numVertexAttributes do
                shader:setVertexAttribute( i, tVertexAttrs[i] )
            end
            
            -- Step 3: Load the uniforms
            local tUniforms = shaderData.tUniforms
            local numUniforms = #tUniforms
            shader:reserveUniforms( numUniforms )  
            if numUniforms > 0 then                  
                for i=1,numUniforms do            
                    local tUniform = tUniforms[i]                
                    -- Register the uniform and set its default value
                    shader:declareUniform( i, tUniform.sName, tUniform.type )                
                    if tUniform.value ~= nil then
                        if tUniform.type == MOAIShader.UNIFORM_FLOAT then
                            shader:setUniformValue( i, tUniform.value )
                        else
                            shader:setUniformValue( i, unpack(tUniform.value) )
                        end
                    end
                end
            end
        end
    end
end

function m.loadShader(shaderPath)
    local shaderAssetPath = m.getNormalizedAssetPath( shaderPath )
    local shader = m.shaderLibrary[shaderAssetPath]
    if shader == nil then
        shader = MOAIShader.new()
        shader:setDebugName(shaderPath)
        shader.path = shaderAssetPath
        shader.refCount = 1
        m.shaderLibrary[shaderAssetPath] = shader
        -- Load the actual shader data
        m.reloadShaderData(shaderAssetPath)
    else
        shader.refCount = shader.refCount + 1
    end
    return shader
end

function m.unloadShader(shaderPath)
    local shaderAssetPath = m.getNormalizedAssetPath( shaderPath )
    local shader = m.shaderLibrary[shaderAssetPath]
    if shader ~= nil then
        shader.refCount = shader.refCount - 1
        if shader.refCount == 0 then
            m.shaderLibrary[shaderAssetPath] = nil
        end
    end
end

function m.reloadAllShaders()
    Trace("Reloading all shaders!")
    DFDataCache.clear( "shader" )
    for shaderPath, shader in pairs(m.shaderLibrary) do
        m.reloadShaderData(shaderPath)
    end
end

function m.printShaderUsageStats()
    Trace("Shader usage:")
    Trace("=============")
    
    local numSingles = 0
    local singlePercentage = 0
    local numMultis = 0
    local multiPercentage = 0
    
    for shaderPath, shader in pairs(m.shaderLibrary) do
        local hasPermutations, numPrograms, numProgramsUsed = shader:getUsageStats()
        local relativeProgramsUsed = numProgramsUsed * 100 / numPrograms
        Trace("* " .. shader.path)
        Trace("   " .. tostring(numProgramsUsed) .. "/" .. tostring(numPrograms) .. " (" .. tostring(math.floor(relativeProgramsUsed)) .. "%%)")
        if hasPermutations then
            numMultis = numMultis + 1
            multiPercentage = multiPercentage + relativeProgramsUsed
        else
            numSingles = numSingles + 1
            singlePercentage = singlePercentage + relativeProgramsUsed
        end
    end
    
    Trace("-------------")
    
    if numSingles > 0 then numSingles = 1 / numSingles else numSingles = 0 end
    local avgSinglePercentage = singlePercentage * numSingles
    Trace("Singles: " .. tostring(math.floor(avgSinglePercentage)) .. "%%")
    
    if numMultis > 0 then numMultis = 1 / numMultis else numMultis = 0 end
    local avgMultiPercentage = multiPercentage * numMultis
    Trace("Multis:  " .. tostring(math.floor(avgMultiPercentage)) .. "%%")
    
    Trace("=============")
end

function m.reloadMaterial(material, clearCache)

    -- (Recursively) read the material
    local tMaterialData = m.loadMaterialData(material.path, clearCache)
    
    -- Unload the existing shader if the material now uses a different one
    if material.shader ~= nil and material.shader.path ~= tMaterialData.sShader then
    
        m.unloadShader(material.shader.path)
        material.shader = nil
    end
    
    -- (Re)Load the shader
    if material.shader == nil then
    
        local shader = m.loadShader(tMaterialData.sShader)
        if shader == nil then
			Print(TT_Error, "Material needs a shader! ", material.path)
        end
        
        material.shader = shader
        material:setShader(shader)
    end
    
    -- Load new textures before unloading previous ones, so that we don't reload the data
    local tPrevTextures = DFUtil.deepCopy(material.textures)
    material.textures = {}
    
    -- (Re)Load the texture    
    if tMaterialData.sTexture ~= nil then
    
        local texture = m.loadTexture(tMaterialData.sTexture, true)
        material.texture = texture
        material:setTexture(texture)
        
        table.insert(material.textures, texture)
    end
    
    -- Load the color
    if tMaterialData.tColor ~= nil then
        material:setColor(unpack(tMaterialData.tColor))
    else
        material:setColor()
    end
    
    -- Load the render state
    if tMaterialData.cullMode ~= nil then
        material:setCullMode(tMaterialData.cullMode)
    else
        material:setCullMode()
    end
    if tMaterialData.depthTest ~= nil then
        material:setDepthTest(tMaterialData.depthTest)
    else
        material:setDepthTest()
    end
    if tMaterialData.depthWrite ~= nil then
        material:setDepthWrite(tMaterialData.depthWrite)
    else
        material:setDepthWrite()
    end
    if tMaterialData.blendMode ~= nil then
        material:setBlendMode(unpack(tMaterialData.blendMode))
    else
        material:setBlendMode()
    end
    
    -- Load the shader values
    material:clearShaderValues()
    if tMaterialData.tShaderValues ~= nil then
        local numShaderValues = #tMaterialData.tShaderValues
        for i=1,numShaderValues do
        
            local tShaderValue = tMaterialData.tShaderValues[i]
            local value = tShaderValue.value
            
            if tShaderValue.type == MOAIMaterial.VALUETYPE_TEXTURE then
                value = m.loadTexture(tShaderValue.value, true)
                table.insert(material.textures, value)
            end
            
            material:setShaderValue(tShaderValue.sName, tShaderValue.type, value)
        end
    end
    
    -- Load the dynamic shader values
    material:clearDynamicShaderValues()
    if tMaterialData.tDynamicShaderValues ~= nil then
        local numShaderValues = #tMaterialData.tDynamicShaderValues
        for i=1,numShaderValues do
            local tShaderValue = tMaterialData.tDynamicShaderValues[i]
            material:setDynamicShaderValue(tShaderValue.type, tShaderValue.sName)
        end
    end
    
    -- Load the shader permutation
    material:resetPermutationState()
    if tMaterialData.tShaderPermutation ~= nil then
        -- Set flags
        if tMaterialData.tShaderPermutation.tFlags ~= nil then
            local numFlags = #tMaterialData.tShaderPermutation.tFlags
            for i=1,numFlags do
                local sFlagName = tMaterialData.tShaderPermutation.tFlags[i]
                material:setPermutationFlag(sFlagName)
            end
        end
        -- Set switches
        if tMaterialData.tShaderPermutation.tSwitches ~= nil then
            local numSwitches = #tMaterialData.tShaderPermutation.tSwitches
            for i=1,numSwitches do
                local sSwitchName = tMaterialData.tShaderPermutation.tSwitches[i][1]
                local sOptionName = tMaterialData.tShaderPermutation.tSwitches[i][2]
                material:setPermutationSwitch(sSwitchName, sOptionName)
            end
        end
    end
    
    -- Unload previously used textures
    if tPrevTextures ~= nil then
        local numTextures = #tPrevTextures
        for i=1,numTextures do
            local texture = tPrevTextures[i]
            m.unloadTexture(texture.path)
        end
        tPrevTextures = {}
    end
end

function m.loadMaterial(materialPath)

    local matAssetPath = m.getNormalizedAssetPath( materialPath )

    local material = MOAIMaterial.new()
    material.path = matAssetPath
    
    -- Store a reference to the material, so we can hot-reload it
    if m.materialLibrary[matAssetPath] == nil then
        m.materialLibrary[matAssetPath] = {}
    end
    m.materialLibrary[matAssetPath][material] = 1
    
    -- Load the material data
    m.reloadMaterial(material)
    
    return material
end

function m.unloadMaterial(material)

    -- Remove the material from the library
    m.materialLibrary[material.path][material] = nil

    -- Unload shader
    if material.shader ~= nil then
        m.unloadShader(material.shader.path)
    end
    -- Unload textures
    local numTextures = #material.textures
    for i=1,numTextures do
        local texture = material.textures[i]
        m.unloadTexture(texture.path)
    end
end

function m.loadMaterialData(materialPath, clearCache)

    local tMaterialData = {}
    
    if clearCache == true then
        DFDataCache.clear( "material" )
    end

    -- Load the data of the given material
    local filePath = DFFile.getDataPath( materialPath )
    local materialData = DFDataCache.getData( "material", filePath .. ".material" )
    if not materialData then 
        Print(TT_Error, "Failed to load material at ", materialPath, filePath )
        return 
    end
    -- Load the parent material if it's defined
    if materialData.sParentMaterial ~= nil then
        local parentMatAssetPath = m.getNormalizedAssetPath( materialData.sParentMaterial )
        local tParentMaterialData = m.loadMaterialData(parentMatAssetPath)
        -- Don't mutate the parent data
        tMaterialData = DFUtil.deepCopy(tParentMaterialData)
    end
    -- Merge the values of this material (which will overwrite values defined in the parent)
    for key,value in pairs(materialData) do
        if key ~= "sParentMaterial" then
            if type(value) == "table" and tMaterialData[key] ~= nil then
                -- Complex type
                if key == "blendMode" or key == "tColor" then
                    tMaterialData[key] = DFUtil.deepCopy(value)
                elseif key == "tShaderValues" then
                    local valueMap = {}
                    local numValues = #tMaterialData[key]
                    for i=1,numValues do
                        local valName = tMaterialData[key][i].sName
                        valueMap[valName] = i
                    end
                    numValues = #value
                    for i=1,numValues do
                        local valName = value[i].sName
                        if valueMap[valName] ~= nil then
                            -- Overwrite exiting value
                            local valIndex = valueMap[valName]
                            tMaterialData[key][valIndex] = value[i]
                        else
                            -- Add new value
                            table.insert(tMaterialData[key], value[i])
                        end
                    end
                elseif key == "tShaderPermutation" then
                    if value.tFlags ~= nil then
                        if tMaterialData[key].tFlags ~= nil then
                            -- Add new flags
                            local numFlags = #value.tFlags
                            for i=1,numFlags do
                                local sFlag = value.tFlags[i]
                                if tMaterialData[key].tFlags[sFlag] == nil then
                                    table.insert(tMaterialData[key].tFlags, sFlag)
                                end
                            end
                        else
                            -- Set flags
                            tMaterialData[key].tFlags = value.tFlags
                        end
                    end
                    if value.tSwitches ~= nil then
                        if tMaterialData[key].tSwitches ~= nil then
                            local switchMap = {}
                            local numSwitches = #tMaterialData[key].tSwitches
                            for i=1,numSwitches do
                                local switchName = tMaterialData[key].tSwitches[i][1]
                                switchMap[switchName] = i
                            end
                            local numSwitches = #value.tSwitches
                            for i=1,numSwitches do
                                local switchName = value.tSwitches[i][1]
                                if switchMap[switchName] ~= nil then
                                    -- Overwrite switch option
                                    local switchIndex = witchMap[switchName]
                                    tMaterialData[key].tSwitches[switchIndex][2] = value.tSwitches[i][2]
                                else
                                    -- Insert new switch
                                    table.insert(tMaterialData[key].tSwitches, value.tSwitches[i])
                                end
                            end
                        else
                            -- Set switches
                            tMaterialData[key].tSwitches = value.tSwitches
                        end
                    end
                end
            else
                -- Simple value
                tMaterialData[key] = value
            end
        end
    end
    
    return tMaterialData
end

-- Does not work for rotated sprites.  May have problems with things attached to things.
function m.overlaps(sprite1, sprite2)
    if not (sprite1 and sprite2) then
        return false
    end
    
    local xMin1, yMin1, zMin1, xMax1, yMax1, zMax1 = sprite1:getBounds()
    local xMin2, yMin2, zMin2, xMax2, yMax2, zMax2 = sprite2:getBounds()
    
    return DFMath.overlaps(xMin1, yMin1, xMax1, yMax1, xMin2, yMin2, xMax2, yMax2)
end

function m.aggregateWorldBounds(propList)
    if #propList == 0 then
        return 0, 0, 0, 0, 0, 0
    end
    local x0, y0, z0, x1, y1, z1
    local bFirst = true
    for _, prop in pairs(propList) do
        if bFirst then
            x0, y0, z0, x1, y1, z1 = prop:getWorldBounds()
            bFirst = x0 == nil
        else
            local px0, py0, pz0, px1, py1, pz1 = prop:getWorldBounds()
            if px0 ~= nil then
                x0, y0, z0 = math.min(x0, px0), math.min(y0, py0), math.min(z0, pz0)
                x1, y1, z1 = math.max(x1, px1), math.max(y1, py1), math.max(z1, pz1)            
            end
        end
    end
    return x0, y0, z0, x1, y1, z1
end

function m.getNormalizedAssetPath( assetPath )

    local normPath = nil

    local idxExtention = string.find ( assetPath, "%." )
    if idxExtention ~= nil and idxExtention > 1 then
        normPath = string.sub ( assetPath, 1, idxExtention - 1 )
    else
        normPath = assetPath
    end

    return normPath
end


function m.getAssetRelativeFilename(sAssetFile, sSubAssetFile)

    local sAbsSubAssetFile = DFFile.getAssetPath(sSubAssetFile)
    if MOAIFileSystem.checkFileExists(sAbsSubAssetFile) then
        return sSubAssetFile
    else
        return DFFile.stripFileName(sAssetFile) .. sSubAssetFile
    end
end

local assetRoot = DFFile.getAssetPath('')
local dataRoot = DFFile.getDataPath('')
function m.onFileChange(path)
    -- Treat cache paths a munged paths
    path = path:gsub('/_Cache/', '/Munged/')
    if string.find(path, assetRoot) == 1 then
        local assetPath = m.getNormalizedAssetPath( string.sub(path, #assetRoot + 1) )
        -- Reload textures
        m.reloadTextureData(assetPath)
        -- Reload shaders
        m.reloadShaderData(assetPath, true)
    elseif string.find(path, 'Data') == 1 then
        local extension = DFFile.getSuffix(path)
        if extension == "matmod" then
            DFDataCache.clear("matmod")
        else
            local dataPath = m.getNormalizedAssetPath( string.sub(path, #dataRoot + 1) )
            -- Reload materials
            if m.materialLibrary[dataPath] ~= nil then
                for material, _ in pairs(m.materialLibrary[dataPath]) do
                    m.reloadMaterial(material, true)
                end
            end
        end
    end
end

-- Monitor file changes so that we can hot reload textures and other assets under the asset root path
DFMoaiDebugger.dFileChanged:register(m.onFileChange)

return m

