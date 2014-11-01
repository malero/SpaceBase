local Delegate = require('DFMoai.Delegate')
local DFGraphics = require('DFCommon.Graphics')
local DFFile = require('DFCommon.File')
local Post = require('PostFX.Post')
local Camera = require('Camera')

local Renderer = {}

local rViewportWindow = nil
local rGameplayCamera = nil
local rDebugCamera = nil
local rUICamera = nil
local rBackgroundCamera = nil

local tLayers = {
    DebugScreenSpace = {},
    DebugWindow = {},
    Background = {
        RenderToBuffer = true,
    },
    BuildGrid = {
        RenderToBuffer = true,
    },
    WorldOutlines = {
        RenderToBuffer = true,
    },
    -- Where the environment draws, e.g. planets and nebulae
    WorldBackground = {
        RenderToBuffer = true,
    },
    WorldFloor = {
        RenderToBuffer = true,
    },
    Character = {
        RenderToBuffer = true,
    },
    WorldWall = {
        RenderToBuffer = true,
    },
    WorldCeiling = {
        RenderToBuffer = "SceneForeground",
    },
    Cursor = {
        RenderToBuffer = "SceneForeground",
    },
    Light = {
        RenderToBuffer = "SceneForeground",
    },
    WorldAnalysis = {
        RenderToBuffer = "SceneForeground",
    },
    Post = {},
    UIBackground = {
        RenderToBuffer = true,
    },
    UI = {
        RenderToBuffer = "UI",
    },
    UIScrollLayerLeft = {
        RenderToBuffer = "UI",
    },
    UIScrollLayerRight = {
        RenderToBuffer = "UI",
    },
    UIForeground = {
        RenderToBuffer = "UI",
    },
    UIEffectMask = {
        RenderToBuffer = true,    
    },
    UIOverlay = {},
}

local tVertexFormats = {
}

local tGlobalMaterials = {
}

local tGlobalMaterialFilenames = {
}

local tGlobalTextures = {
}

--kVirtualScreenWidth = 1920
--kVirtualScreenHeight = 1080
kVirtualScreenWidth = 2048
kVirtualScreenHeight = 1152

kVirtualScreenWidthHalf = kVirtualScreenWidth / 2
kVirtualScreenHeightHalf = kVirtualScreenHeight / 2

local kVirtualScreenAspectRatio = kVirtualScreenWidth / kVirtualScreenHeight
local kVirtualScreenAspectRatioInv = 1 / kVirtualScreenAspectRatio

local kVirtualScreenGameSafeHeight = 1152
local kVirtualScreenOverscan = kVirtualScreenHeight - kVirtualScreenGameSafeHeight
local kVirtualScreenOverscanHalf = kVirtualScreenOverscan / 2

local tFlags = {
    DebugDrawWorldSpace = true,
    DebugDrawScreenSpace = true,
    DebugDrawWindow = true,
    DebugDrawReferenceFrame = false,
    DebugDrawGameSafeArea = false,
    DebugDrawStats = false,
    DebugDrawProfileReport = false,
    DebugDrawGpuProfileReport = false,
    DebugDrawRigs = false,
    DebugDrawMode = MOAIGfxDevice.DBG_DISABLED,
}
Renderer.tFlags = tFlags

-- resize delegates
Renderer.dResized = Delegate.new()



Renderer.kMaxZoomNearPlane = 0.1
Renderer.kMinZoomNearPlane = 0.01
Renderer.kMaxZoomFarPlane = 100000
Renderer.kMinZoomFarPlane = 15000
Renderer.kDefaultFarPlane = 10000
Renderer.kDefaultNearPlane = 0.01


function Renderer.initializeRenderer(gameViewport, uiViewport)

    Renderer.ScreenBufferWidth = 1280.0
    Renderer.ScreenBufferHeight = 720.0

    -- Allocate some delegates
    Renderer.dDebugRenderWorldSpace = Delegate.new()
    Renderer.dDebugRenderScreenSpace = Delegate.new()
    Renderer.dDebugRenderWindow = Delegate.new()
    
    --
    -- Viewport and camera setup
    --
    MOAIGfxDevice.setListener( MOAIGfxDevice.EVENT_RESIZE, Renderer._onResize )

    -- Setup viewport
    Renderer.rUIViewport = uiViewport
    Renderer.rGameViewport = gameViewport
    rViewportWindow = MOAIViewport.new()
    if Post.kEnabled then
        Renderer.rBufferViewport = MOAIViewport.new()
        
        Renderer.rHalfSizeGameViewport = MOAIViewport.new()
        Renderer.rHalfSizeGameViewport:setSize( Renderer.rGameViewport.sizeX, Renderer.rGameViewport.sizeY )       
        Renderer.rQuarterSizeGameViewport = MOAIViewport.new()
        Renderer.rQuarterSizeGameViewport:setSize( Renderer.rGameViewport.sizeX, Renderer.rGameViewport.sizeY )    
        Renderer.rEighthSizeGameViewport = MOAIViewport.new()
        Renderer.rEighthSizeGameViewport:setSize( Renderer.rGameViewport.sizeX, Renderer.rGameViewport.sizeY )            
    end
    
    -- Setup cameras
    rDebugCamera = MOAICamera2D.new ()
    rDebugCamera:setLoc( kVirtualScreenWidthHalf, kVirtualScreenHeightHalf, 0 )
    rDebugCamera:setScl( 1, -kVirtualScreenAspectRatioInv)

    rUICamera = MOAICamera2D.new()
    rUICamera:setLoc(0,0)
    rUICamera:setScl( 1, 1 )

    rBackgroundCamera = MOAICamera.new()
    rBackgroundCamera:setOrtho(false)
    rBackgroundCamera:setLoc( 0, 0, 500 )
    rBackgroundCamera:setScl( 10, 10 )
    rBackgroundCamera:setNearPlane(Renderer.kDefaultNearPlane)
    rBackgroundCamera:setFarPlane(Renderer.kDefaultFarPlane)

    
    rGameplayCamera = Camera.new()
    rGameplayCamera:setOrtho(true)
    rGameplayCamera:setLoc( 0, 0, rGameplayCamera:getFocalLength( kVirtualScreenWidth ) )
    rGameplayCamera:setScl( 1, 1 )
    rGameplayCamera:setNearPlane(Renderer.kDefaultNearPlane)
    rGameplayCamera:setFarPlane(Renderer.kDefaultFarPlane)

    -- Make sure the VFX system knows where the camera is
    -- ToDo: Remove if-statement
    if DFEffects ~= nil then
        DFEffects.setCamera(rGameplayCamera)
    end
    --
    -- Setup state
    --
    local clearColor = MOAIColor.new ()
    clearColor:setColor ( 0, 0, 0, 1 )
    MOAIGfxDevice.setClearColor ( clearColor )
    MOAIGfxDevice.setClearDepth ( true )

    --
    -- Setup new layers
    --

    for sLayerId, _ in pairs(tLayers) do
        tLayers[sLayerId].Name = sLayerId
    end
    
    -- Screen-space debug overlay
    tLayers.DebugScreenSpace.RenderLayer = MOAILayer2D.new()
    tLayers.DebugScreenSpace.RenderLayer:setDebugName(tLayers.DebugScreenSpace.Name)
    tLayers.DebugScreenSpace.RenderLayer:setViewport (Renderer.rUIViewport)
    tLayers.DebugScreenSpace.RenderLayer:setCamera (rDebugCamera)

    tLayers.DebugScreenSpace.Partition = MOAIPartition.new ()
    tLayers.DebugScreenSpace.RenderLayer:setPartition(tLayers.DebugScreenSpace.Partition)

    -- Window-space debug overlay
    tLayers.DebugWindow.RenderLayer = MOAILayer2D.new()
    tLayers.DebugWindow.RenderLayer:setDebugName(tLayers.DebugWindow.Name)
    tLayers.DebugWindow.RenderLayer:setViewport(rViewportWindow)

    tLayers.DebugWindow.Partition = MOAIPartition.new()
    tLayers.DebugWindow.RenderLayer:setPartition(tLayers.DebugWindow.Partition)

    -- UI (affected by monitor shader)
    tLayers.UI.RenderLayer = MOAILayer2D.new()
    tLayers.UI.RenderLayer:setDebugName(tLayers.UI.Name)
    tLayers.UI.RenderLayer:setViewport(Renderer.rUIViewport)
    tLayers.UI.RenderLayer:setCamera(rUICamera)
    tLayers.UI.Partition = MOAIPartition.new ()
    tLayers.UI.RenderLayer:setPartition(tLayers.UI.Partition)

    -- this layer's kinda weird. But MOAI's scissoring works best when running on a layer instead of on individual props. This draws
    --  in front of the normal UI but will also have the shader running.
    tLayers.UIScrollLayerLeft.RenderLayer = MOAILayer2D.new()
    tLayers.UIScrollLayerLeft.RenderLayer:setDebugName(tLayers.UIScrollLayerLeft.Name)
    tLayers.UIScrollLayerLeft.RenderLayer:setViewport(Renderer.rUIViewport)
    tLayers.UIScrollLayerLeft.RenderLayer:setCamera(rUICamera)
    tLayers.UIScrollLayerLeft.Partition = MOAIPartition.new ()
    tLayers.UIScrollLayerLeft.RenderLayer:setPartition(tLayers.UIScrollLayerLeft.Partition)
    
    tLayers.UIScrollLayerRight.RenderLayer = MOAILayer2D.new()
    tLayers.UIScrollLayerRight.RenderLayer:setDebugName(tLayers.UIScrollLayerRight.Name)
    tLayers.UIScrollLayerRight.RenderLayer:setViewport(Renderer.rUIViewport)
    tLayers.UIScrollLayerRight.RenderLayer:setCamera(rUICamera)
    tLayers.UIScrollLayerRight.Partition = MOAIPartition.new ()
    tLayers.UIScrollLayerRight.RenderLayer:setPartition(tLayers.UIScrollLayerRight.Partition)    

    tLayers.UIForeground.RenderLayer = MOAILayer2D.new()
    tLayers.UIForeground.RenderLayer:setDebugName(tLayers.UIForeground.Name)
    tLayers.UIForeground.RenderLayer:setViewport(Renderer.rUIViewport)
    tLayers.UIForeground.RenderLayer:setCamera(rUICamera)
    tLayers.UIForeground.Partition = MOAIPartition.new ()
    tLayers.UIForeground.RenderLayer:setPartition(tLayers.UIForeground.Partition)

    -- UI Overlay (draws on top of UI)
    tLayers.UIOverlay.RenderLayer = MOAILayer2D.new()
    tLayers.UIOverlay.RenderLayer:setDebugName(tLayers.UIOverlay.Name)
    tLayers.UIOverlay.RenderLayer:setViewport(Renderer.rUIViewport)
    tLayers.UIOverlay.RenderLayer:setCamera(rUICamera)
    tLayers.UIOverlay.Partition = MOAIPartition.new ()
    tLayers.UIOverlay.RenderLayer:setPartition(tLayers.UIOverlay.Partition)
    
    tLayers.UIBackground.RenderLayer = MOAILayer2D.new()
    tLayers.UIBackground.RenderLayer:setDebugName(tLayers.UIBackground.Name)
    tLayers.UIBackground.RenderLayer:setViewport(Renderer.rUIViewport)
    tLayers.UIBackground.RenderLayer:setCamera(rUICamera)
    tLayers.UIBackground.Partition = MOAIPartition.new ()
    tLayers.UIBackground.RenderLayer:setPartition(tLayers.UIBackground.Partition)
    
    tLayers.UIEffectMask.RenderLayer = MOAILayer2D.new()
    tLayers.UIEffectMask.RenderLayer:setDebugName(tLayers.UIEffectMask.Name)
    tLayers.UIEffectMask.RenderLayer:setViewport(Renderer.rUIViewport)
    tLayers.UIEffectMask.RenderLayer:setCamera(rUICamera)
    tLayers.UIEffectMask.Partition = MOAIPartition.new ()
    tLayers.UIEffectMask.RenderLayer:setPartition(tLayers.UIEffectMask.Partition)
    
    -- Background!
    tLayers.Background.RenderLayer = MOAILayer.new()
    tLayers.Background.RenderLayer:setDebugName(tLayers.Background.Name)
    tLayers.Background.RenderLayer:setViewport(Renderer.rGameViewport)
    tLayers.Background.RenderLayer:setCamera(rBackgroundCamera)

    local worldPartition

    worldPartition = MOAIPartition.new()
    tLayers.BuildGrid.RenderLayer = MOAILayer.new()
    tLayers.BuildGrid.RenderLayer:setDebugName(tLayers.BuildGrid.Name)
    tLayers.BuildGrid.RenderLayer:setViewport(Renderer.rGameViewport)
    tLayers.BuildGrid.RenderLayer:setCamera (rGameplayCamera)
    tLayers.BuildGrid.Partition = worldPartition
    tLayers.BuildGrid.RenderLayer:setPartition(worldPartition)
    
    -- World!
    worldPartition = MOAIPartition.new()
    tLayers.WorldOutlines.RenderLayer = MOAILayer.new()
    tLayers.WorldOutlines.RenderLayer:setDebugName(tLayers.WorldOutlines.Name)
    tLayers.WorldOutlines.RenderLayer:setViewport(Renderer.rGameViewport)
    tLayers.WorldOutlines.RenderLayer:setCamera (rGameplayCamera)
    tLayers.WorldOutlines.Partition = worldPartition
    tLayers.WorldOutlines.RenderLayer:setPartition(worldPartition)

    worldPartition = MOAIPartition.new()
    tLayers.WorldBackground.RenderLayer = MOAILayer.new()
    tLayers.WorldBackground.RenderLayer:setDebugName(tLayers.WorldBackground.Name)
    tLayers.WorldBackground.RenderLayer:setViewport(Renderer.rGameViewport)
    tLayers.WorldBackground.RenderLayer:setCamera (rGameplayCamera)
    tLayers.WorldBackground.Partition = worldPartition
    tLayers.WorldBackground.RenderLayer:setPartition(worldPartition)

    worldPartition = MOAIPartition.new()
    tLayers.WorldFloor.RenderLayer = MOAILayer.new()
    tLayers.WorldFloor.RenderLayer:setDebugName(tLayers.WorldFloor.Name)
    tLayers.WorldFloor.RenderLayer:setViewport(Renderer.rGameViewport)
    tLayers.WorldFloor.RenderLayer:setCamera (rGameplayCamera)
    tLayers.WorldFloor.Partition = worldPartition
    tLayers.WorldFloor.RenderLayer:setPartition(worldPartition)
    tLayers.WorldFloor.RenderLayer:setSortMode (MOAILayer.SORT_Z_ASCENDING)

    worldPartition = MOAIPartition.new()
    tLayers.WorldWall.RenderLayer = MOAILayer.new()
    tLayers.WorldWall.RenderLayer:setDebugName(tLayers.WorldWall.Name)
    tLayers.WorldWall.RenderLayer:setViewport(Renderer.rGameViewport)
    tLayers.WorldWall.RenderLayer:setCamera (rGameplayCamera)
    tLayers.WorldWall.Partition = worldPartition
    tLayers.WorldWall.RenderLayer:setPartition(worldPartition)
    tLayers.WorldWall.RenderLayer:setSortMode (MOAILayer.SORT_Z_ASCENDING)

    worldPartition = MOAIPartition.new()
    tLayers.Character.RenderLayer = MOAILayer.new()
    tLayers.Character.RenderLayer:setDebugName(tLayers.Character.Name)
    tLayers.Character.RenderLayer:setViewport(Renderer.rGameViewport)
    tLayers.Character.RenderLayer:setCamera (rGameplayCamera)
    tLayers.Character.Partition = worldPartition
    tLayers.Character.RenderLayer:setPartition(worldPartition)
    tLayers.Character.RenderLayer:setSortMode (MOAILayer.SORT_Z_ASCENDING)

    worldPartition = MOAIPartition.new()
    tLayers.WorldCeiling.RenderLayer = MOAILayer.new()
    tLayers.WorldCeiling.RenderLayer:setDebugName(tLayers.WorldCeiling.Name)
    tLayers.WorldCeiling.RenderLayer:setViewport(Renderer.rGameViewport)
    tLayers.WorldCeiling.RenderLayer:setCamera(rGameplayCamera)
    tLayers.WorldCeiling.Partition = worldPartition
    tLayers.WorldCeiling.RenderLayer:setPartition(worldPartition)
    tLayers.WorldCeiling.RenderLayer:setSortMode (MOAILayer.SORT_Z_ASCENDING)

    -- Cursor!
    tLayers.Cursor.RenderLayer = MOAILayer.new()
    tLayers.Cursor.RenderLayer:setDebugName(tLayers.Cursor.Name)
    tLayers.Cursor.RenderLayer:setViewport(Renderer.rGameViewport)
    tLayers.Cursor.RenderLayer:setCamera (rGameplayCamera)
    tLayers.Cursor.RenderLayer:setSortMode (MOAILayer.SORT_Z_ASCENDING)

    tLayers.Cursor.Partition = MOAIPartition.new ()
    tLayers.Cursor.RenderLayer:setPartition(tLayers.Cursor.Partition)

    tLayers.Light.RenderLayer = MOAILayer2D.new()
    tLayers.Light.RenderLayer:setDebugName(tLayers.Light.Name)
    tLayers.Light.RenderLayer:setViewport( Renderer.rGameViewport )
    tLayers.Light.RenderLayer:setCamera (rGameplayCamera)
    tLayers.Light.Partition = MOAIPartition.new ()
    tLayers.Light.RenderLayer:setPartition(tLayers.Light.Partition)
    tLayers.Light.RenderLayer:setSortMode (MOAILayer.SORT_Z_ASCENDING)

    -- WorldAnalysis
    tLayers.WorldAnalysis.RenderLayer = MOAILayer.new()
    tLayers.WorldAnalysis.RenderLayer:setDebugName(tLayers.WorldAnalysis.Name)
    tLayers.WorldAnalysis.RenderLayer:setViewport(Renderer.rGameViewport)
    tLayers.WorldAnalysis.RenderLayer:setCamera (rGameplayCamera)

    tLayers.WorldAnalysis.Partition = MOAIPartition.new ()
    tLayers.WorldAnalysis.RenderLayer:setPartition(tLayers.WorldAnalysis.Partition)


    --
    -- setup frame buffers
    --

    Renderer.tFrameBuffers = {}
    local tBuff = nil
    
    tBuff = MOAIFrameBuffer.new()
    tBuff:init( gameViewport.sizeX, gameViewport.sizeY )
    tBuff:setClearColor( 0, 0, 0, 0 )
    Renderer.tFrameBuffers["WorldOutlines"] = tBuff

    tBuff = MOAIFrameBuffer.new()
    tBuff:init( gameViewport.sizeX, gameViewport.sizeY )
    tBuff:setClearColor( 0, 0, 0, 0 )
    Renderer.tFrameBuffers["Scene"] = tBuff
    
    tBuff = MOAIFrameBuffer.new()
    tBuff:init( gameViewport.sizeX, gameViewport.sizeY )
    tBuff:setClearColor( 0, 0, 0, 0 )
    Renderer.tFrameBuffers["SceneForeground"] = tBuff
    
    tBuff = MOAIFrameBuffer.new()
    tBuff:init( gameViewport.sizeX, gameViewport.sizeY )
    tBuff:setClearColor( 0, 0, 0, 0 )
    Renderer.tFrameBuffers["UI"] = tBuff
    
    -- if post effects are enabled, make our layers draw to these buffers
    if Post.kEnabled then
        for sLayerId in pairs(tLayers) do
            local tLayer = tLayers[sLayerId]
            if tLayer.RenderToBuffer == true then
                tLayer.FrameBuffer = MOAIFrameBuffer.new()
                tLayer.FrameBuffer:init( gameViewport.sizeX, gameViewport.sizeY )
                tLayer.FrameBuffer:setClearColor( 0, 0, 0, 0 )
                tLayer.RenderLayer:setFrameBuffer(tLayer.FrameBuffer)
            elseif tLayer.RenderToBuffer then
                tLayer.RenderLayer:setFrameBuffer(Renderer.tFrameBuffers[tLayer.RenderToBuffer])
            end
        end

        tLayers.Background.FrameBuffer:setClearColor( 0, 0, 0, 1 )
        Renderer.updateClearColor()


        tLayers.Post.RenderLayer = MOAILayer2D.new()
        tLayers.Post.RenderLayer:setDebugName(tLayers.Post.Name)
        tLayers.Post.RenderLayer:setViewport ( Renderer.rGameViewport )
    end


    --
    -- Vertex formats
    --

    -- Static mesh
    local rVertexFormatDefault = MOAIVertexFormat.new()
    rVertexFormatDefault:declareCoord( 1, MOAIVertexFormat.GL_FLOAT, 3 )
    rVertexFormatDefault:declareUV( 2, MOAIVertexFormat.GL_FLOAT, 2 )

    tVertexFormats["default"] = rVertexFormatDefault

    -- Skinned mesh
    local rVertexFormatDefaultSkinned = MOAIVertexFormat.new()
    rVertexFormatDefaultSkinned:declareCoord( 1, MOAIVertexFormat.GL_FLOAT, 3 )
    rVertexFormatDefaultSkinned:declareUV( 2, MOAIVertexFormat.GL_FLOAT, 2 )
    rVertexFormatDefaultSkinned:declareAttribute ( 3, MOAIVertexFormat.GL_FLOAT, 4 ) -- blendIndices, blendWeights

    tVertexFormats["defaultSkinned"] = rVertexFormatDefaultSkinned

    -- Compound-texture mesh
    local rVertexFormatMeshDeck = MOAIVertexFormat.new()
    rVertexFormatMeshDeck:declareCoord( 1, MOAIVertexFormat.GL_FLOAT, 2 )
    rVertexFormatMeshDeck:declareUV( 2, MOAIVertexFormat.GL_FLOAT, 2 )

    tVertexFormats["meshdeck"] = rVertexFormatMeshDeck

    --
    -- Global materials
    --

    tGlobalMaterialFilenames["meshBase"] = "Materials/MeshBase.material"
    tGlobalMaterialFilenames["meshDefault"] = "Materials/MeshDefault.material"
    tGlobalMaterialFilenames["meshSingleTexture"] = "Materials/MeshSingleTexture.material"
    tGlobalMaterialFilenames["invert"] = "Materials/Invert.material"
    tGlobalMaterialFilenames["worldLight"] = "Materials/WorldLight.material"
    tGlobalMaterialFilenames["wallLight"] = "Materials/WallLight.material"
    tGlobalMaterials["wallLight"] = Renderer.loadMaterialInstance( "wallLight" )
    tGlobalMaterialFilenames["space"] = "Materials/Space.material"
    tGlobalMaterials["space"] = Renderer.loadMaterialInstance( "space" )

    
    tGlobalMaterialFilenames["planet"] = "Materials/Planet.material"
    
    tGlobalMaterialFilenames["blit"] = "Materials/Blit.material"
    
    for key,value in pairs(tGlobalMaterialFilenames) do
        tGlobalMaterials[key] = Renderer.loadMaterialInstance( key )
    end
  

--    local rBlobMaterial = DFGraphics.loadMaterial( "Materials/BlobShadow.material" )
--    tGlobalMaterials["blobshadow"] = rBlobMaterial

    --
    -- shader overrides
    --
    
	local rShaderOverride = DFGraphics.loadShader ( "Shaders/builtinFont.shd" )
    MOAIShaderMgr.setShader ( MOAIShaderMgr.FONT_SHADER, rShaderOverride )

    --
    -- Global textures
    --
    local rWhiteTexture = DFGraphics.loadTexture( "white" )
    tGlobalTextures["white"] = rWhiteTexture

    --
    -- Misc
    --

    -- Setup screen-space debug drawing
    local rScreenSpaceScriptDeck = MOAIScriptDeck.new ()
    rScreenSpaceScriptDeck:setRect ( 0, 0, kVirtualScreenWidth, kVirtualScreenHeight )
    rScreenSpaceScriptDeck:setDrawCallback ( Renderer._onDebugDrawScreenSpace )

    local rScreenSpaceScriptDeckProp = MOAIProp2D.new ()
    rScreenSpaceScriptDeckProp:setDeck ( rScreenSpaceScriptDeck )
    rScreenSpaceScriptDeckProp:setBlendMode( MOAIProp.GL_SRC_ALPHA, MOAIProp.GL_ONE_MINUS_SRC_ALPHA )
    tLayers.DebugScreenSpace.RenderLayer:insertProp ( rScreenSpaceScriptDeckProp )

    -- Set up window-space debug drawing
    local rWindowScriptDeck = MOAIScriptDeck.new ()
    rWindowScriptDeck:setRect ( 0, 0, kVirtualScreenWidth, kVirtualScreenHeight )
    rWindowScriptDeck:setDrawCallback ( Renderer._onDebugDrawWindow )

    local rWindowSpaceScriptDeckProp = MOAIProp2D.new ()
    rWindowSpaceScriptDeckProp:setDeck( rWindowScriptDeck )
    tLayers.DebugWindow.RenderLayer:insertProp ( rWindowSpaceScriptDeckProp )

    -- Set up stats window
    local rOnePixelDeck = MOAIGfxQuad2D.new()
    rOnePixelDeck:setTexture(rWhiteTexture)
    rOnePixelDeck:setRect(0, 0, 1, 1)

    Renderer.rDebugStatBackgroundProp = MOAIProp2D.new()
    Renderer.rDebugStatBackgroundProp:setDeck(rOnePixelDeck)
    Renderer.rDebugStatBackgroundProp:setColor(1, 1, 1, 0.75)
    Renderer.rDebugStatBackgroundProp:setLoc(0, 0)
    Renderer.rDebugStatBackgroundProp:setScl(230, 200)
    Renderer.rDebugStatBackgroundProp:setBlendMode( MOAIProp.GL_SRC_ALPHA, MOAIProp.GL_ONE_MINUS_SRC_ALPHA )

    Renderer.rDebugStatTextProp = MOAITextBox.new()
    Renderer.rDebugStatTextProp:setFont(g_Gui.getFont())
    Renderer.rDebugStatTextProp:setTextSize(12)
    Renderer.rDebugStatTextProp:setAlignment(MOAITextBox.LEFT_JUSTIFY)
    Renderer.rDebugStatTextProp:setYFlip(false)
    Renderer.rDebugStatTextProp:setString('Retrieving stats...')
    Renderer.rDebugStatTextProp:setRect(0, 0, 300, 300)
    Renderer.rDebugStatTextProp:setLoc(0, 0)
    Renderer.rDebugStatTextProp:setColor(0, 0, 0)

    Renderer._debugShowStats(tFlags.DebugDrawStats)

    -- Set up profile window
    Renderer.rDebugProfileReportProp = MOAIProfileReportBox.new()
    Renderer.rDebugProfileReportProp:setFont(g_Gui.getFont())
    Renderer.rDebugProfileReportProp:setFontSize(14)
    Renderer.rDebugProfileReportProp:setPriority(10)
    Renderer.rDebugProfileReportProp:setRect(50, 50, gameViewport.sizeX - 50, gameViewport.sizeY - 50)

    Renderer._debugShowProfileReport(tFlags.DebugDrawProfileReport)
    if tFlags.DebugDrawRigs then
        Renderer.toggleDebugDrawRigs()
    end

    -- Set up GPU profile window
    Renderer.rDebugGpuProfileReportProp = MOAIGpuProfileReportBox.new()
    Renderer.rDebugGpuProfileReportProp:setFont(g_Gui.getFont())
    Renderer.rDebugGpuProfileReportProp:setFontSize(14)
    Renderer.rDebugGpuProfileReportProp:setPriority(10)
    Renderer.rDebugGpuProfileReportProp:setRect(50, 50, gameViewport.sizeX - 50, gameViewport.sizeY - 50)

    Renderer._debugShowGpuProfileReport(tFlags.DebugDrawGpuProfileReport)

    Renderer._recreateRenderPasses()

    if Post.kEnabled then
        Post:Init(Renderer)
        --Post:BasicComp()
        Post:ScenePlusUI()
        --Post:ShowRenderLayer("Light")
        --Post:ShowRenderLayer("WorldWall")
        --Post:ShowRenderLayer("WorldCeiling")
        --Post:ShowRenderLayer("Character")
    end

    -- FINAL INIT
    local tRenderLayersForYou = {}
    Renderer.addRenderLayers( tRenderLayersForYou )
    Renderer.addDebugLayers( tRenderLayersForYou )

    Renderer.sizeViewports(gameViewport.sizeX, gameViewport.sizeY)
    MOAIRenderMgr.setRenderTable(tRenderLayersForYou)
    
    local SeqCommand = require("SeqCommand")
    SeqCommand.registerCommands()
end

function Renderer.resetCamera()
    rGameplayCamera:setLoc( 0, 0, rGameplayCamera:getFocalLength( kVirtualScreenWidth ) )
end

function Renderer.toggleUI()
    if nil == Renderer.bHideUI then Renderer.bHideUI = false end
    
    Renderer.bHideUI = not Renderer.bHideUI
end

function Renderer.setShowUI(bState)
    Renderer.bHideUI = (not bState)
end

function Renderer.updateClearColor()
    for sLayerId in pairs(tLayers) do
        local tLayer = tLayers[sLayerId]
        if tLayer.FrameBuffer then
            if sLayerId == "Background" then
                tLayer.FrameBuffer:setClearColor( 0, 0, 0, 1 )
            else
                tLayer.FrameBuffer:setClearColor( 0, 0, 0, 0 )
            end
        end
    end
    for sBufferId in pairs(Renderer.tFrameBuffers) do
        Renderer.tFrameBuffers[sBufferId]:setClearColor(0,0,0,0)
    end
end

function Renderer._onResize(width, height)
    Renderer.sizeViewports(width, height)
    Renderer.dResized:dispatch()
end

function Renderer.sizeViewports(width, height)
    Renderer.nAspectRatio = width / height
    Renderer.nDisplayScaleX = 1.0
    Renderer.nDisplayScaleY = 1.0

    local nScaledScreenWidth,nScaledScreenHeight = kVirtualScreenWidth,kVirtualScreenHeight
    if Renderer.nAspectRatio < kVirtualScreenAspectRatio then
        -- if we're taller, we can scale based on the device's width and everything will still fit
        nScaledScreenWidth = kVirtualScreenWidth
        nScaledScreenHeight = kVirtualScreenWidth / Renderer.nAspectRatio
    elseif Renderer.nAspectRatio > kVirtualScreenAspectRatio then
        -- if we're wider, we need to scale based on height
        nScaledScreenWidth = kVirtualScreenHeight * Renderer.nAspectRatio
        nScaledScreenHeight = kVirtualScreenHeight
    end

    Renderer.rUIViewport:setSize ( width, height )
    Renderer.rUIViewport:setScale ( nScaledScreenWidth, nScaledScreenHeight )
    Renderer.rUIViewport:setOffset ( -1, 1 )
    Renderer.rUIViewport.sizeX = nScaledScreenWidth
    Renderer.rUIViewport.sizeY = nScaledScreenHeight

    Renderer.rGameViewport:setSize ( width, height )
    Renderer.rGameViewport:setScale ( width, height )
    Renderer.rGameViewport.sizeX = width
    Renderer.rGameViewport.sizeY = height

    if Post.kEnabled then
        Renderer.rBufferViewport:setSize( width, height )
        Renderer.rBufferViewport:setScale(width,height)
        Renderer.rBufferViewport:setOffset(-1 + (1/1),-1 + (1/1)) -- I know this line does nothing, it's a pattern used once we support half/quarter buffers

        -- if you clamped screen buffer size, you would have to calculate a scale for the buffer size here
        --local bufScaleX = width / Constants.ScreenBufferWidth
        --local bufScaleY = height / Constants.ScreenBufferHeight

        local bufScaleX = 1.0
        local bufScaleY = 1.0
        local bufScreenW = width * bufScaleX
        local bufScreenH = height * bufScaleY
        
        -- a little explanation of this, at least for half buffers.
        -- the point -1,0 will move the 0,0 of these shrunken viewports to the left side of the screenX
        -- the point -1 + (1/bufScaleX),0 will move it to the right side of the screen (that being our parent's transform)
        -- so the resulting transform will be an average of those two points. Continue down the scaled stack!
        -- leaving them in as the full math formula so they make sense to human eyes
        -- NOTE: this would be so much easier if we just used matrices instead of viewports, but that's not really an option
        --        unless we just don't use MOAI rendering at all.
        Renderer.rHalfSizeGameViewport:setSize( width, height )
        Renderer.rHalfSizeGameViewport:setScale( bufScreenW * 2, bufScreenH * 2)
        Renderer.rHalfSizeGameViewport:setOffset((-1 -1 + (1/bufScaleX))/2,(-1 -1 + (1/bufScaleY))/2)    
        
        Renderer.rQuarterSizeGameViewport:setSize( width, height )
        Renderer.rQuarterSizeGameViewport:setScale( bufScreenW * 4, bufScreenH * 4)
        Renderer.rQuarterSizeGameViewport:setOffset((-1 + (-1 -1 + (1/bufScaleX))/2)/2,(-1 + (-1 -1 + (1/bufScaleY))/2)/2)
        
        Renderer.rEighthSizeGameViewport:setSize( width, height )
        Renderer.rEighthSizeGameViewport:setScale( bufScreenW * 8, bufScreenH * 8)
        Renderer.rEighthSizeGameViewport:setOffset((-1 + (-1 + (-1 -1 + (1/bufScaleX))/2)/2)/2,(-1 + (-1 + (-1 -1 + (1/bufScaleY))/2)/2)/2)   
        
        for sLayerId in pairs(tLayers) do
            local tLayer = tLayers[sLayerId]
            if tLayer.FrameBuffer then
                -- the layers that share depth do stuff a little differently below
                if sLayerId ~= "WorldWall" and sLayerId ~= "Character" then
                    tLayer.FrameBuffer:init( width, height )
                end
            end
        end

        local worldBuffer = Renderer.getLayerFrameBuffer("WorldWall")
        worldBuffer:init(width, height, -1, MOAITexture.GL_DEPTH_COMPONENT16)
        worldBuffer:setClearDepth(true)
        
        for sFrameBufferId in pairs(Renderer.tFrameBuffers) do
            local buffer = Renderer.getFrameBuffer(sFrameBufferId)
            
            if sFrameBufferId == "Scene" then
                buffer:init(width, height, -1, MOAITexture.GL_DEPTH_COMPONENT16)
                buffer:setClearDepth(true)
            else
                buffer:init(width, height)
            end
        end

        Post:OnScreenResize(width, height)
    end

    rViewportWindow:setSize ( width, height )
    rViewportWindow:setScale ( width, -height )
    rViewportWindow:setOffset ( -1, 1 )
    rViewportWindow.sizeX = width
    rViewportWindow.sizeY = height

    -- Update the render-targets too
    Renderer._recreateRenderPasses()

    -- Update debug widgets
    if Renderer.rDebugProfileReportProp ~= nil then
        Renderer.rDebugProfileReportProp:setRect(50, 50, width - 50, height - 50)
    end
end

function Renderer.useCompressedTextures()
    return g_Config:getConfigValue("use_compressed_textures")
end

-- matching the stupid capitalization of DFGraphics version... this allows us to remap stuff a little bit if we need to.
function Renderer.loadSpriteSheet(spritePath, loadAsynchronously, loadClipGeo, skipRects)
    -- check to see if this sprite has a compressed version
    if Renderer.useCompressedTextures() then
        local compressedPath = spritePath .. "_Compressed"

        local bExists = DFGraphics.spritesheetExists(compressedPath)
        
        -- check if file exists, if it does, use it
        if bExists then
            spritePath = compressedPath
        end
    end
    
    return DFGraphics.loadSpriteSheet(spritePath, loadAsynchronously, loadClipGeo, skipRects)
end

function Renderer._recreateRenderPasses()

    -- Disable the text-box while the layers get removed and re-added
    local debugDrawStats = tFlags.DebugDrawStats
    if debugDrawStats == true then
        Renderer._debugShowStats(false)
    end

    local debugDrawProfileReport = tFlags.DebugDrawProfileReport
    if debugDrawProfileReport == true then
        Renderer._debugShowProfileReport(false)
    end

    local debugDrawGpuProfileReport = tFlags.DebugDrawGpuProfileReport
    if debugDrawGpuProfileReport == true then
        Renderer._debugShowGpuProfileReport(false)
    end

    -- Reset the debug draw mode
    tFlags.DebugDrawMode = MOAIGfxDevice.DBG_DISABLED

    -- Restore debug draw
    if debugDrawStats then
        Renderer._debugShowStats(true)
    end
    if debugDrawProfileReport then
        Renderer._debugShowProfileReport(true)
    end
    if debugDrawGpuProfileReport then
        Renderer._debugShowGpuProfileReport(true)
    end
end

function Renderer.clearRenderLayers(tRenderLayers)
    tLayers.Background.RenderLayer:clear()
    tLayers.WorldBackground.RenderLayer:clear()
    tLayers.WorldOutlines.RenderLayer:clear()
    tLayers.WorldFloor.RenderLayer:clear()
    tLayers.BuildGrid.RenderLayer:clear()
    tLayers.Character.RenderLayer:clear()
    tLayers.WorldWall.RenderLayer:clear()
    tLayers.WorldCeiling.RenderLayer:clear()
    tLayers.Cursor.RenderLayer:clear()
    tLayers.Light.RenderLayer:clear()
    tLayers.WorldAnalysis.RenderLayer:clear()
    tLayers.UIBackground.RenderLayer:clear()
    tLayers.UI.RenderLayer:clear()
    tLayers.UIScrollLayerLeft.RenderLayer:clear()
    tLayers.UIScrollLayerRight.RenderLayer:clear()
    tLayers.UIForeground.RenderLayer:clear()
    tLayers.UIEffectMask.RenderLayer:clear()
    tLayers.UIOverlay.RenderLayer:clear()
end

function Renderer.addRenderLayers(tRenderLayers)
    table.insert(tRenderLayers, tLayers.Background.RenderLayer)
    table.insert(tRenderLayers, tLayers.WorldOutlines.RenderLayer)
    table.insert(tRenderLayers, tLayers.WorldBackground.RenderLayer)
    table.insert(tRenderLayers, tLayers.WorldFloor.RenderLayer)
    table.insert(tRenderLayers, tLayers.BuildGrid.RenderLayer)
    table.insert(tRenderLayers, tLayers.Character.RenderLayer)
    table.insert(tRenderLayers, tLayers.WorldWall.RenderLayer)
    table.insert(tRenderLayers, tLayers.WorldCeiling.RenderLayer)
    table.insert(tRenderLayers, tLayers.Cursor.RenderLayer)
    table.insert(tRenderLayers, tLayers.Light.RenderLayer)
    table.insert(tRenderLayers, tLayers.WorldAnalysis.RenderLayer)
    table.insert(tRenderLayers, tLayers.UIBackground.RenderLayer)
    table.insert(tRenderLayers, tLayers.UI.RenderLayer)
    table.insert(tRenderLayers, tLayers.UIScrollLayerLeft.RenderLayer)
    table.insert(tRenderLayers, tLayers.UIScrollLayerRight.RenderLayer)
    table.insert(tRenderLayers, tLayers.UIForeground.RenderLayer)
    if Post.kEnabled then
        table.insert(tRenderLayers, tLayers.UIEffectMask.RenderLayer)
        Post:AddLayers(tRenderLayers)
    end
    table.insert(tRenderLayers, tLayers.UIOverlay.RenderLayer)
end

function Renderer.addDebugLayers(tRenderLayers)
    table.insert(tRenderLayers, tLayers.DebugScreenSpace.RenderLayer)
    table.insert(tRenderLayers, tLayers.DebugWindow.RenderLayer)
end

function Renderer.getLayer(sLayerName)

    if not sLayerName then
        return nil
    end

    -- Check renderer layers first
    if tLayers[sLayerName] then
        return tLayers[sLayerName]
    end

    return nil
end

function Renderer.getRenderLayer(sLayerName)
    local rLayer = Renderer.getLayer(sLayerName)
    if rLayer then
        return rLayer.RenderLayer
    end

    return nil
end

function Renderer.getFrameBuffer(sBufferName)
    return Renderer.tFrameBuffers[sBufferName]
end

function Renderer.getLayerFrameBuffer(sLayerName)
    local rLayer = Renderer.getLayer(sLayerName)
    if rLayer then
        return rLayer.FrameBuffer
    end

    return nil
end

function Renderer.getPartition(sLayerName)
    local rLayer = Renderer.getLayer(sLayerName)
    if rLayer then
        return rLayer.Partition
    end

    return nil
end

function Renderer.getUIViewportRect()
    return 0, 0, Renderer.rUIViewport.sizeX, -Renderer.rUIViewport.sizeY
end

function Renderer.getGameViewportRect()
    return 0, 0, Renderer.rGameViewport.sizeX, Renderer.rGameViewport.sizeY
end

function Renderer.getHalfScreenSize()
    return Renderer.rGameViewport.sizeX / 2, Renderer.rGameViewport.sizeY / 2
end

function Renderer.getScreenSize()
    return Renderer.rGameViewport.sizeX, Renderer.rGameViewport.sizeY
end

function Renderer.getGameViewport()
    return Renderer.rGameViewport
end

function Renderer.getViewport()
    return Renderer.rUIViewport
end

function Renderer.getViewportWindow()
    return rViewportWindow
end

function Renderer.getGameplayCamera()
    return rGameplayCamera
end

function Renderer.getBackgroundCamera()
    return rBackgroundCamera
end

function Renderer.getUICamera()
    return rUICamera
end

function Renderer.getDebugCamera()
    return rDebugCamera
end

function Renderer.getGlobalTexture(sName)
    return tGlobalTextures[sName]
end

function Renderer.getWorldFromCursor(cursorX, cursorY)
    local worldLayer = Renderer.getRenderLayer('WorldFloor')
    return worldLayer:wndToWorld(cursorX, cursorY)
end

function Renderer._onDebugDrawWorldSpace( index, xOff, yOff, xScale, yScale )
    if tFlags.DebugDrawWorldSpace then
        Renderer.dDebugRenderWorldSpace:dispatch()
    end
end

function Renderer._onDebugDrawScreenSpace( index, xOff, yOff, xScale, yScale )

    if not tFlags.DebugDrawScreenSpace then
        return
    end

    if tFlags.DebugDrawReferenceFrame then

        local offsetX = 100
        local offsetY = 100

        local p00 = { x = offsetX, y = kVirtualScreenOverscanHalf + offsetY }
        local p10 = { x = kVirtualScreenWidth - offsetX, y = kVirtualScreenOverscanHalf + offsetY }
        local p11 = { x = kVirtualScreenWidth - offsetX, y = kVirtualScreenHeight - kVirtualScreenOverscanHalf - offsetY }
        local p01 = { x = offsetX, y = kVirtualScreenHeight - kVirtualScreenOverscanHalf - offsetY }

        MOAIGfxDevice.setPenColor ( 1, 1, 1, 1 )
        MOAIDraw.drawRect ( p00.x, p00.y, p11.x, p11.y )

        local rectSize = 10

        MOAIGfxDevice.setPenColor ( 1, 0, 0, 1 )
        MOAIDraw.drawRect ( p00.x - rectSize, p00.y - rectSize, p00.x + rectSize, p00.y + rectSize )

        MOAIGfxDevice.setPenColor ( 0, 1, 0, 1 )
        MOAIDraw.drawRect ( p10.x - rectSize, p10.y - rectSize, p10.x + rectSize, p10.y + rectSize )

        MOAIGfxDevice.setPenColor ( 0, 0, 1, 1 )
        MOAIDraw.drawRect ( p11.x - rectSize, p11.y - rectSize, p11.x + rectSize, p11.y + rectSize )

        MOAIGfxDevice.setPenColor ( 1, 1, 0, 1 )
        MOAIDraw.drawRect ( p01.x - rectSize, p01.y - rectSize, p01.x + rectSize, p01.y + rectSize )
    end

    if tFlags.DebugDrawGameSafeArea then

        local p00 = { x = 0, y = kVirtualScreenOverscanHalf }
        local p10 = { x = kVirtualScreenWidth, y = kVirtualScreenOverscanHalf }
        local p11 = { x = kVirtualScreenWidth, y = kVirtualScreenHeight - kVirtualScreenOverscanHalf }
        local p01 = { x = 0, y = kVirtualScreenHeight - kVirtualScreenOverscanHalf }

        local offset = 1

        MOAIGfxDevice.setPenColor ( 1, 1, 1, 1 )
        MOAIDraw.drawRect ( p00.x + offset, p00.y + offset, p11.x - offset, p11.y - offset )

        local rectSize = 20

        MOAIGfxDevice.setPenColor ( 1, 0, 0, 1 )
        MOAIDraw.fillRect ( p00.x, p00.y, p00.x + rectSize, p00.y + rectSize )

        MOAIGfxDevice.setPenColor ( 0, 1, 0, 1 )
        MOAIDraw.fillRect ( p10.x - rectSize, p10.y, p10.x, p10.y + rectSize )

        MOAIGfxDevice.setPenColor ( 0, 0, 1, 1 )
        MOAIDraw.fillRect ( p11.x - rectSize, p11.y - rectSize, p11.x, p11.y )

        MOAIGfxDevice.setPenColor ( 1, 1, 0, 1 )
        MOAIDraw.fillRect ( p01.x, p01.y - rectSize, p01.x + rectSize, p01.y )

    end

    Renderer.dDebugRenderScreenSpace:dispatch()
end

function Renderer._onDebugDrawWindow ( index, xOff, yOff, xScale, yScale )

    if tFlags.DebugDrawWindow then
        Renderer.dDebugRenderWindow:dispatch()
    end
end

-- DEBUG TOGGLES
Renderer.tDebugDrawModes = {
    [MOAIGfxDevice.DBG_NO_TRANSPARENCY] = "No Transparency",
    [MOAIGfxDevice.DBG_SHOW_OVERDRAW] = "Overdraw",
    [MOAIGfxDevice.DBG_DISABLED] = "Disabled",
}
function Renderer.debugDrawModeOptions()
    return Renderer.tDebugDrawModes
end

function Renderer.debugDrawModeGet()
    return Renderer.tDebugDrawModes[tFlags.DebugDrawMode]
end

function Renderer.debugDrawModeSet(debugDrawMode)
    for modeId, modeName in pairs(Renderer.tDebugDrawModes) do
        if modeName == debugDrawMode then
            tFlags.DebugDrawMode = modeId
        end
    end
end

function Renderer.cycleDebugDrawRooms()
    local Room=require('Room')
    Room.cycleDebugDraw()
    if Room.debugDrawMode == Room.DEBUG_DRAW_NONE then
        Renderer.dDebugRenderWindow:unregister(Room.debugDrawRooms)
    else
        Renderer.dDebugRenderWindow:register(Room.debugDrawRooms)
    end
end

function Renderer.toggleDebugDrawPathing()
	local CharacterManager = require('CharacterManager')
	if Renderer.bDrawingPathing then
        Renderer.bDrawingPathing = false
        Renderer.dDebugRenderWindow:unregister(CharacterManager.debugDrawPathing)
	else
		Renderer.bDrawingPathing = true
        Renderer.dDebugRenderWindow:register(CharacterManager.debugDrawPathing)
	end
end

function Renderer.toggleDebugDrawRigs()
    local CharacterManager=require('CharacterManager')
    if Renderer.bDrawingRigs then
        Renderer.bDrawingRigs = false
        Renderer.dDebugRenderWindow:unregister(CharacterManager.debugDrawRigs)
    else
        Renderer.bDrawingRigs = true
        Renderer.dDebugRenderWindow:register(CharacterManager.debugDrawRigs)
    end
end

function Renderer.toggleDebugDrawStats()
    Renderer._debugShowStats(not tFlags.DebugDrawStats)
end

function Renderer._debugShowStats(show)

    if show then
        tLayers.DebugWindow.RenderLayer:insertProp ( Renderer.rDebugStatBackgroundProp )
        tLayers.DebugWindow.RenderLayer:insertProp ( Renderer.rDebugStatTextProp )
    else
        tLayers.DebugWindow.RenderLayer:removeProp ( Renderer.rDebugStatBackgroundProp )
        tLayers.DebugWindow.RenderLayer:removeProp ( Renderer.rDebugStatTextProp )
    end

    tFlags.DebugDrawStats = show
end

function Renderer.toggleDebugDrawProfileReport()
    Renderer._debugShowProfileReport(not tFlags.DebugDrawProfileReport)
end

function Renderer._debugShowProfileReport(show)
    if not tLayers.DebugWindow.RenderLayer or not Renderer.rDebugProfileReportProp then return end

    if show then
        Renderer.rDebugProfileReportProp:enableProfiling()
        tLayers.DebugWindow.RenderLayer:insertProp ( Renderer.rDebugProfileReportProp )
    else
        tLayers.DebugWindow.RenderLayer:removeProp ( Renderer.rDebugProfileReportProp )
        Renderer.rDebugProfileReportProp:disableProfiling()
    end

    tFlags.DebugDrawProfileReport = show
end
function Renderer.toggleDebugDrawGpuProfileReport()
    Renderer._debugShowGpuProfileReport(not tFlags.DebugDrawGpuProfileReport)
end

function Renderer._debugShowGpuProfileReport(show)

    if show then
        Renderer.rDebugGpuProfileReportProp:enableProfiling()
        tLayers.DebugWindow.RenderLayer:insertProp ( Renderer.rDebugGpuProfileReportProp )
    else
        tLayers.DebugWindow.RenderLayer:removeProp ( Renderer.rDebugGpuProfileReportProp )
        Renderer.rDebugGpuProfileReportProp:disableProfiling()
    end

    tFlags.DebugDrawGpuProfileReport = show
end


function Renderer.getVertexFormat(sName)
    return tVertexFormats[sName]
end

function Renderer.loadMaterialInstance(sName)
    return DFGraphics.loadMaterial(tGlobalMaterialFilenames[sName])
end

function Renderer.getGlobalMaterial(sName)
    return tGlobalMaterials[sName]
end

function Renderer.getGlobalTexture(sName)
    return tGlobalTextures[sName]
end

-- DEBUG RENDERING
local prevUpdateDuration = 1.0 / 60.0
local prevRenderDuration = 1.0 / 60.0

function _getPaddedString(value, totalCharacters)
    local str = tostring(value)
    local strLen = #str
    for i=strLen,totalCharacters do
        str = str.." "
    end
    return str
end

function Renderer._debugUpdateStats()

    local nFPS, simDuration, renderDuration = MOAISim.getPerformance()
    local renderDuration = MOAIRenderMgr.getPerformance()

    -- Print frame rate
    nFPS = math.floor(nFPS)
    local sStats = "FPS: "..nFPS.."\n\n"

    -- Calculate 'update rate'
    local keep = 0.99999

    local alpha = math.min(math.max((nFPS - 30) / 30, 0), 1)
    keep = 0.5 * (1 - alpha) + keep * alpha

    local update = 1 - keep

    -- Print simulation and render timing
    prevUpdateDuration = prevUpdateDuration * keep + simDuration * update
    local simFPS = math.floor(1 / simDuration)
    simDuration = math.floor(simDuration * 10000) / 10
    sStats = sStats .. "Update: ".._getPaddedString(simDuration, 4).."ms (" .. _getPaddedString(simFPS, 5) .. "fps)\n"

    prevRenderDuration = prevRenderDuration * keep + renderDuration * update
    local renderFPS = math.floor(1 / renderDuration)
    renderDuration = math.floor(renderDuration * 10000) / 10
    sStats = sStats .. "Render: ".._getPaddedString(renderDuration, 4).."ms (" .. _getPaddedString(renderFPS, 5) .. "fps)\n\n"

    -- Print render into
    local drawCount = MOAIRenderMgr.getPerformanceDrawCount()
    local triangleCount = MOAIRenderMgr.getPerformanceTriangleCount()
    sStats = sStats .. "Draw calls:" .. tostring(drawCount) .. "\n"
    sStats = sStats .. "Triangles:" .. tostring(triangleCount) .. "\n\n"

    -- Print memory and collection timings
    local tMemUsage = MOAISim.getMemoryUsage()
    for key, value in pairs(tMemUsage) do
        sStats = sStats..key..": "..value.."\n"
    end

    Renderer.rDebugStatTextProp:setString(sStats)
end

function Renderer.onTick(deltaTime)
    Post:Update(deltaTime)
    
    -- Update debug stats
    if tFlags.DebugDrawStats then
        Renderer._debugUpdateStats()
    end
end

return Renderer
