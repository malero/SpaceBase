local DFUtil = require('DFCommon.Util')
local DFMath = require('DFCommon.Math')
local MiscUtil = require('MiscUtil')
local LuaGrid = require('LuaGrid')
local DataCache = require("DFCommon.DataCache")
local DFFile = require('DFCommon.File')
local DFGraphics = require('DFCommon.Graphics')
local EnvironmentData = require("Environment.EnvironmentData")

--local tCharacters
--local UPDATES_PER_TICK = 10

local kFARAWAYPLANE = -5500

local Environment = {}

Environment.sPreset = nil
Environment.tSprites = {}

Environment.planetProp = nil
Environment.ambientColor = { 0, 0, 0 }

Environment.tPlanetParams = {}

local elapsed = 0.0

local tPlanetTextures = { "Props/Space/Planet/Textures/planetGen", "Props/Space/Planet/Textures/planetGen02", "Props/Space/Planet/Textures/planetGen04"  }
local PlanetClass = { EARTHLIKE = 1, GASGIANT = 2, LIQUID = 3, OTHER = 4, EARTHLIKE = 1, EARTHLIKE = 1 }


function Environment._generatePlanet()

   --this is where all the generation stuff goes
    local tPlanetParams = {}

    tPlanetParams.class = PlanetClass[ MiscUtil.randomKey( PlanetClass ) ]

    tPlanetParams.axialTilt = -22
    tPlanetParams.scale =  math.random( 3 ) + 6

    if tPlanetParams.class == PlanetClass.EARTHLIKE then
        tPlanetParams.waterColor = { 45.0/255.0, 112.0/255.0, 177.0/255.0 }
        tPlanetParams.dryLandColor = { 160.0/255.0, 150.0/255.0, 124.0/255.0 }
        tPlanetParams.wetLandColor = { 125.0/255.0 + math.random() * 0.2, 188.0/255.0 + math.random() * 0.2, 86.0/255.0 + math.random() * 0.2 }

        tPlanetParams.cloudCoverage = 0.3
        tPlanetParams.cloudColor = { 1.0, 1.0, 1.0, tPlanetParams.cloudCoverage }

        tPlanetParams.waterDepth = math.random() - 0.2
        tPlanetParams.waterFalloff = 0.2 * math.random() + 0.1
        tPlanetParams.drynessSeed = math.random()
        tPlanetParams.cloudHeight = 0.002
        tPlanetParams.rimLightColor =  {0.2, 0.27, 0.7}

        tPlanetParams.baseTexture = MiscUtil.randomValue( tPlanetTextures )

   elseif tPlanetParams.class == PlanetClass.OTHER then
        tPlanetParams.waterColor = { 112.0/255.0 * math.random() * 0.5, 112.0/255.0 * math.random()  * 0.5, 177.0/255.0 * math.random() * 0.5  }
        tPlanetParams.dryLandColor = { 160.0/255.0 * math.random(), 150.0/255.0, 124.0/255.0 * math.random() }
        tPlanetParams.wetLandColor = { 160.0/255.0 * math.random(), 150.0/255.0, 124.0/255.0 * math.random()}
        tPlanetParams.cloudCoverage = 0.0
        tPlanetParams.cloudColor = { 1.0, 1.0, 1.0, tPlanetParams.cloudCoverage }

        tPlanetParams.waterDepth = 0.0
        tPlanetParams.waterFalloff = 0.5
        tPlanetParams.drynessSeed = math.random()
        tPlanetParams.cloudHeight = 0.002
        tPlanetParams.rimLightColor = tPlanetParams.waterColor

        tPlanetParams.axialTilt = math.random() * 40

        tPlanetParams.baseTexture = MiscUtil.randomValue( tPlanetTextures )


    elseif    tPlanetParams.class == PlanetClass.LIQUID then
        tPlanetParams.waterColor = { 45.0/255.0, 112.0/255.0 + math.random() * 0.3, 177.0/255.0 }
        tPlanetParams.dryLandColor = { 160.0/255.0, 150.0/255.0, 124.0/255.0 }
        tPlanetParams.wetLandColor = { 125.0/255.0 + math.random() * 0.2, 188.0/255.0 + math.random() * 0.2, 86.0/255.0 + math.random() * 0.2 }

        tPlanetParams.cloudCoverage = 0.2
        tPlanetParams.cloudColor = { 1.0, 1.0, 1.0, tPlanetParams.cloudCoverage }

        tPlanetParams.waterDepth = 1.0
        tPlanetParams.waterFalloff = 0.2 * math.random() + 0.1
        tPlanetParams.drynessSeed = math.random()
        tPlanetParams.cloudHeight = 0.002
        tPlanetParams.rimLightColor = { tPlanetParams.waterColor[1]*0.4, tPlanetParams.waterColor[2]  * 0.4, tPlanetParams.waterColor[3]  * 0.4 }

        tPlanetParams.axialTilt = math.random() * 40
        tPlanetParams.scale =  math.random( 3 ) + 5

        tPlanetParams.baseTexture = MiscUtil.randomValue( tPlanetTextures )


          elseif  tPlanetParams.class == PlanetClass.GASGIANT then
        tPlanetParams.waterColor = { 0.8+math.random()*0.15, 0.5, 0.5* math.random()*0.5 }
        tPlanetParams.dryLandColor = { math.random(), 0.5, math.random()  }
        tPlanetParams.wetLandColor = { tPlanetParams.dryLandColor[1], tPlanetParams.dryLandColor[2]*0.5, tPlanetParams.dryLandColor[3] }

        tPlanetParams.cloudCoverage = 0.0
        tPlanetParams.cloudColor = { 1.0, 1.0, 1.0, tPlanetParams.cloudCoverage }

        tPlanetParams.waterDepth = 0.0
        tPlanetParams.waterFalloff = 0.2 * math.random() + 0.1
        tPlanetParams.drynessSeed = math.random()
        tPlanetParams.cloudHeight = 0.002
        tPlanetParams.rimLightColor = { tPlanetParams.waterColor[1]* 0.2, tPlanetParams.waterColor[2] * 0.2, tPlanetParams.waterColor[3]* 0.2 }

        tPlanetParams.axialTilt = math.random() * 40
        tPlanetParams.scale =  math.random( 3 ) + 5

        tPlanetParams.baseTexture =  "Props/Space/Planet/Textures/planetGen03"
    end


    return tPlanetParams

end

function Environment._createPlanet( tPlanetParams )
        assert(Environment.planetProp == nil)

        --take a set of parameters and create the planet prop and set up shaders and whatnot.
        local rRenderLayer = g_Renderer.getRenderLayer('WorldBackground')

        local rigFile =  'Props/Space/Planet/Rig/Planet.rig' -- 'Props/Asteroid/AsteroidChunk/Rig/AsteroidChunk.rig' --'Characters/Primitives/Rig/Sphere.rig'

        local planetProp = require('MiscUtil').spawnRig( rigFile,'Props/Asteroid/AsteroidChunk/Textures/AsteroidChunk01', 'Background', "planet" )
        planetProp:addLoc( 0,0, kFARAWAYPLANE )
        planetProp:setScl( tPlanetParams.scale, tPlanetParams.scale, tPlanetParams.scale)

        local tTextures = {}
        table.insert( tTextures, { "_Group_planet_Mesh","g_samBase", tPlanetParams.baseTexture } ) --"Props/Space/Planet/Textures/gasgiant_base01" } )
        planetProp.rRig:setTexturePath( tTextures )
        planetProp.rRig:setRigShaderValue( 'g_vAmbLightColor', Environment.ambientColor )

        planetProp.rRig:setRigShaderValue( 'g_vRimLightColor', tPlanetParams.rimLightColor )

        planetProp.rRig:setRigShaderValue( 'g_vWaterColor', tPlanetParams.waterColor )
        planetProp.rRig:setRigShaderValue( 'g_vDryLandColor', tPlanetParams.dryLandColor )
        planetProp.rRig:setRigShaderValue( 'g_vWetLandColor', tPlanetParams.wetLandColor )
        planetProp.rRig:setRigShaderValue( 'g_vCloudColor', tPlanetParams.cloudColor)
        planetProp.rRig:setRigShaderValue( 'g_vLandParams', { tPlanetParams.waterDepth, tPlanetParams.waterFalloff, tPlanetParams.drynessSeed, tPlanetParams.cloudHeight  } )
        --Axial tilt, yo
        planetProp:setRot( 0, math.random() * 360, tPlanetParams.axialTilt )

        Environment.planetProp = planetProp
end

function Environment.onTick( dt )
    elapsed = elapsed + dt
    if Environment.planetProp then
        Environment.planetProp:addRot( 0, dt, 0 )
        Environment.planetProp.rRig:setRigShaderValue( 'g_fTime', elapsed )
    end
end

function Environment._createSprite( tSpriteSpec, tPreset, layerName )
    local tSpriteData = tPreset.nebulaSprites[tSpriteSpec.sKey]

    tSpriteData.layerName = tSpriteData.layerName or 'space'

    if( tSpriteData.layerName == layerName ) then
        local rSpriteSheet = DFGraphics.loadSpriteSheet( tSpriteData.sSpritePath, false, false, true)
        local prop = MOAIProp.new()
        prop:setDeck( rSpriteSheet )

        prop:setScl( tSpriteData.scale[1] * tSpriteSpec.nScl, tSpriteData.scale[2] * tSpriteSpec.nScl )
        prop:setIndex( rSpriteSheet.names[tSpriteData.sSpriteName] )
        prop:setColor( unpack(tSpriteData.color or { 1.0, 1.0, 1.0, 1.0 } ) )
        prop:setRot( 0, 0, tSpriteSpec.nRot )
        prop:setLoc( tSpriteSpec.sx, tSpriteSpec.sy, tSpriteData.offset[3] )
        prop:setMaterial( g_Renderer.getGlobalMaterial("space") )
        if tSpriteData.blendMode then
            prop:setBlendMode( unpack(tSpriteData.blendMode) )
        else
            prop:setBlendMode( MOAIProp.GL_ONE, MOAIProp.GL_ONE )
        end
        g_Renderer.getRenderLayer(g_World.background.layer):insertProp(prop)
    end
end

function Environment.fromSaveTable(tEnv)
    if tEnv then
        Environment.tEnv = tEnv
        Environment.loadEnvironment(Environment.tEnv)
    else
        Environment.randomSetup()
    end
end

function Environment.randomSetup()
    Environment.tEnv = Environment.generateEnvironment()
	Environment.tEnv.tPlanetData = Environment._generatePlanet()
    Environment.loadEnvironment(Environment.tEnv)
end

function Environment.testEnvironment( sPreset )
    Environment.tEnv = Environment.generateEnvironment(sPreset)
    Environment.loadEnvironment(Environment.tEnv)
end

function Environment.getSaveTable()
	-- cover case of existing (pre alpha 4) save data with no planet data
	Environment.tEnv.tPlanetData = Environment.tEnv.tPlanetData or Environment.tPlanetParams
    return Environment.tEnv
end

function Environment.generateEnvironment( sPreset )
    local tEnv={}
    tEnv.sBGSprite = DFUtil.arrayRandom(g_World.background.spriteNames)
    if sPreset ~= nil then
        tEnv.sPreset = EnvironmentData.tPresets[sPreset]
    else
        tEnv.sPreset = MiscUtil.randomKey(EnvironmentData.tPresets)
    end
    tEnv.tSprites={}

    local tData = EnvironmentData.tPresets[ tEnv.sPreset ]
    for k,tSpriteInfo in pairs(tData.nebulaSprites) do
        local count = tSpriteInfo.count or 1
        for i=1, count do
            local tSprite={}
            tSprite.sKey=k
            local scaleRange = tSpriteInfo.scaleRange or 0
            tSprite.nScl = 1.0 - math.random(-scaleRange,scaleRange)
            local nRotRange = tSpriteInfo.rotation or 0
            tSprite.nRot = math.random(-nRotRange,nRotRange)
            tSprite.sx,tSprite.sy = tSpriteInfo.offset[1],tSpriteInfo.offset[2]
            if count > 1 and tSpriteInfo.distribution then
                tSprite.sx = math.random(-tSpriteInfo.distribution[1],tSpriteInfo.distribution[1])+tSprite.sx
                tSprite.sy = math.random(-tSpriteInfo.distribution[2],tSpriteInfo.distribution[2])+tSprite.sy
            end
            table.insert(tEnv.tSprites,tSprite)
        end
    end

    return tEnv
end

function Environment.loadEnvironment(tEnv)
    g_World.background.spriteSheet = DFGraphics.loadSpriteSheet(g_World.background.spritePath, false, false, true)
    g_World.background.grid = LuaGrid.new()
    local spaceTiles = 4
    local spaceTileSize = 8192
    g_World.background.grid:initRectGrid(spaceTiles, spaceTiles, spaceTileSize, spaceTileSize)
    g_World.background.prop = MOAIProp.new()
    g_World.background.prop:setDeck( g_World.background.spriteSheet )
    g_World.background.prop:setGrid( g_World.background.grid:getMOAIGrid() )
    g_World.background.prop:setLoc(spaceTiles * spaceTileSize * -0.5, spaceTiles * spaceTileSize * -0.5, kFARAWAYPLANE )
    --g_World.background.prop:setScl(4,4)
    g_Renderer.getRenderLayer(g_World.background.layer):insertProp(g_World.background.prop)

    local tData = EnvironmentData.tPresets[tEnv.sPreset]

    g_World.background.grid:fill(g_World.background.spriteSheet.names[tEnv.sBGSprite])

    for _,tSprite in ipairs(tEnv.tSprites) do
        Environment._createSprite( tSprite, tData, 'space' )
    end

    Environment.ambientColor = tData.ambientColor
	-- cover case of existing (pre alpha 4) save data with no planet data
	Environment.tPlanetParams = tEnv.tPlanetData or Environment._generatePlanet()
    Environment._createPlanet( Environment.tPlanetParams )

    for _,tSprite in ipairs(tEnv.tSprites) do
        Environment._createSprite( tSprite, tData, 'foreground' )
    end

    local Post = require('PostFX.Post')
    if Post.kEnabled then
        Post.SetPostColorLUT( tData.sPostColorLUT )
        Post.SetSpaceGradient( tData.gradColorLeft, tData.gradColorRight, tData.gradColorTop, tData.gradColorBottom )
    end
end

function Environment.shutdown()
    if g_World.background.prop then
        g_Renderer.getRenderLayer(g_World.background.layer):removeProp(g_World.background.prop)
        g_World.background.prop = nil
        g_World.background.grid = nil
        DFGraphics.unloadSpriteSheet(g_World.background.spriteSheet)
    end

    if Environment.planetProp and Environment.planetProp.rRig then
        Environment.planetProp.rRig:unload()
        Environment.planetProp.rRig = nil
        Environment.planetProp = nil
    end
end

return Environment
