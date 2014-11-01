local DFFile = require("DFCommon.File")
local DFUtil = require("DFCommon.Util")
local DFGraphics = require("DFCommon.Graphics")
local DFMoaiDebugger = require("DFMoai.Debugger")
local Schema = require('DFMoai.Schema')
local DFDataCache = require('DFCommon.DataCache')

-- "m" for "module"
local m = {}

m.particleDataLibrary = {}

m.rSchema = Schema.object(    
    {
        -- Lifetime and frequency
        TEST_COLOR = Schema.color({ 1, 1, 1, 1 }, "Color"),
        
        LIFETIME = Schema.curve(1, "Particle lifetime over time.", "Lifetime"),
        RATE = Schema.curve(10, "Particle emission rate over time.", "Lifetime"),
        DURATION = Schema.number(1, "Lifetime of effect (in seconds)", "Lifetime"),
        
        -- Emitter attributes
        EMITTER_DURATION = Schema.enum('kDURATION_Infinite', { 'kDURATION_Limited', 'kDURATION_Infinite', 'kDURATION_Burst' }, "The lifetime behavior of the system.", "Emitter"),
        EMITTER_TYPE = Schema.enum('kEMITTER_Point', { 'kEMITTER_Point', 'kEMITTER_Box', 'kEMITTER_Sphere', 'kEMITTER_Spline', 'kEMITTER_Cylinder', 'kEMITTER_Skydome', 'kEMITTER_Weather' }, "The emission shape/pattern.", "Emitter"),
        EMITTER_SIZE_X = Schema.curve(0, "Emitter X dimensions over time.", "Emitter"),
        EMITTER_SIZE_Y = Schema.curve(0, "Emitter Y dimensions over time.", "Emitter"),
        EMITTER_SIZE_Z = Schema.curve(0, "Emitter Z dimensions over time.", "Emitter"),
        EMITTER_NORMAL_INFLUENCE = Schema.number(1, "How much the emitter normal influences the particles.", "Emitter"),
        MAX_PER_METER = Schema.number(-1, "Maximum density of particles (-1 means no limit).", "Emitter"),
        DIRECTION_CONE = Schema.vec2({ 0, 90 }, "Emission cone angle dimensions.", "Emitter"),
        
        -- Smooth emission
        SMOOTH_EMISSION = Schema.bool(false, "Not sure what this does.", "Emitter"),
        SMOOTH_TENSION_CONTINUITY_BIAS = Schema.vec4({ -1, 0, 0, 0.7 }, "Not sure what this does.", "Emitter"),

        -- Simulation
        SIZE = Schema.curve(1, "Particle size during its lifetime.", "Simulation"),
        Y_SCALE_FACTOR = Schema.curve(1, "Y scale factor over time.", "Simulation"),   
        INITIAL_SPEED = Schema.curve(0, "Initial particle speed over time.", "Simulation"),
        GLOBAL_FORCE_X = Schema.curve(0, "Global force in X over time.", "Simulation"),
        GLOBAL_FORCE_Y = Schema.curve(0, "Global force in Y over time.", "Simulation"),
        GLOBAL_FORCE_Z = Schema.curve(0, "Global force in Z over time.", "Simulation"),
        GLOBAL_DRAG_X = Schema.curve(0, "Global drag in X over time.", "Simulation"),
        GLOBAL_DRAG_Y = Schema.curve(0, "Global drag in Y over time.", "Simulation"),
        GLOBAL_DRAG_Z = Schema.curve(0, "Global drag in Z over time.", "Simulation"),
        WARMUP_TIME = Schema.number(0, "Amount of pre-run to simulate before starting.", "Simulation"),
        INITIAL_ROTATION = Schema.vec2({ 0, 0 }, "Initial rotation range of particles.", "Simulation"),	
        INHERIT_VELOCITY = Schema.vec3({ 0, 0, 0 }, "Initial amount of inherited velocity.", "Simulation"),	
        INHERIT_TRANSFORM = Schema.number(0, "How much of the transform to inherit.", "Simulation"),	
        INHERIT_TRANSFORM_RATE = Schema.number(10, "Rate at which to inherit the transform.", "Simulation"),	
        BOUNDING_BOX_SORT_SCALE = Schema.number(0, "Scale on the system's bounds when used for sorting.", "Simulation"),	
        PROPORTIONAL_VELOCITY = Schema.vec2({ 1, 1 }, "No idea what this does.", "Simulation"),	
        ROTATION_SPEED = Schema.curve(0, "Speed at which the particle rotates about its axis over its lifetime.", "Simulation"),
        ROTATION_3D = Schema.number(90, "Baseline 3D rotation.", "Simulation"),
        ROTATION_3D_FACTOR = Schema.curve(1, "Scales rotation over particle lifetime.", "Simulation"),
        
        INHERIT_SCALE_TYPE = Schema.enum('kINHERITSCALE_Local', { 'kINHERITSCALE_None', 'kINHERITSCALE_Local', 'kINHERITSCALE_World' }, "The scale inheritance mode used.", "Simulation"),
        
        -- Goals
        SEEK_GOAL_POSITION = Schema.curve(0, "Controls seek position behavior.", "Goals"), 
        SEEK_GOAL_ORIENTATION = Schema.curve(0, "Controls seek orientation behavior.", "Goals"),
        GOAL_OFFSET = Schema.vec3({ 0, 0, 0 }, "Offset from goal position.", "Goals"),	
        GOAL_KILL_RADIUS = Schema.number(0, "Distance from goal at which particles die.", "Goals"),
        GOAL_CURVE_T = Schema.curve(0, "No idea what this does.", "Goals"),
        GOAL_CURVE_X = Schema.curve(0, "No idea what this does.", "Goals"), 
        GOAL_CURVE_Y = Schema.curve(0, "No idea what this does.", "Goals"),
        GOAL_CURVE_Z = Schema.curve(0, "No idea what this does.", "Goals"),
        
        -- Curl noise
        NOISE_PARAMS = Schema.vec3({ 1, 0, 0 }, "No idea what this does.", "Goals"),	
        NOISE_RESOLUTION = Schema.vec3({ 1, 1, 1 }, "No idea what this does.", "Goals"),	
        NOISE_GAIN = Schema.vec3({ 1, 1, 1 }, "No idea what this does.", "Goals"),	
        NOISE_FORCE = Schema.number(1, "No idea what this does.", "Goals"),
        NOISE_ACEELERATION = Schema.number(0, "No idea what this does.", "Goals"),
        NOISE_ROTATION = Schema.number(0, "No idea what this does.", "Goals"),
        NOISE_MAGNITUDE = Schema.curve(0, "No idea what this does.", "Goals"),

        -- Appearance            
        COLOR_R = Schema.curve(1, "Particle redness over its lifetime.", "Shading"),
        COLOR_G = Schema.curve(1, "Particle greenness over its lifetime.", "Shading"),
        COLOR_B  = Schema.curve(1, "Particle blueness over its lifetime.", "Shading"),
        ALPHA  = Schema.curve(1, "Particle alpha over its lifetime.", "Shading"),
        INCANDESCENCE = Schema.curve(1, "Particle incandescence over its lifetime.", "Shading"),
        MATERIAL = Schema.string(nil, "The material to use on each particle.", "Shading"),
        
        -- Culling and camera
        FAR_CULL_RANGE = Schema.vec2( { -1, -1 }, "The start and end screen space sizes for far culling.", "Culling" ),	
        NEAR_CULL_RANGE = Schema.vec2( { 0.4, 0.6 }, "The start and end screen space sizes for near culling.", "Culling" ),	
        DISTANCE_CULL_RANGE = Schema.vec2( { 90000, 125000 }, "The start and end distances for distance culling.", "Culling" ),	
        CAMERA_OFFSET = Schema.number(0, "A cheat applied to offset from the camera.", "Culling"),

        -- Geometry orientation
        PIVOT_LOCATION = Schema.vec2({ 0, 0 }, "Allow the pivot to be offset from the center of the particle.", "Orientation"),					
        BILLBOARD_AXIS = Schema.vec3({ 0, 1, 0 }, "The axis to align when billboarded.", "Orientation"),
        BILLBOARD_ORIENTATION = Schema.enum('BILLBOARDORIENTATION_None', { 'BILLBOARDORIENTATION_None', 'BILLBOARDORIENTATION_CameraFacing', 'BILLBOARDORIENTATION_Velocity', 'BILLBOARDORIENTATION_ProportionalVelocity', 'BILLBOARDORIENTATION_FixedAxis', 'BILLBOARDORIENTATION_FixedAxisVelocity', 'BILLBOARDORIENTATION_Radial', 'BILLBOARDORIENTATION_Rotation3D' }, "Determines how particle orientation is computed.", "Orientation"),

        -- Lighting
        LIGHTING_MODEL = Schema.enum('LIGHTINGMODEL_None', { 'LIGHTINGMODEL_None', 'LIGHTINGMODEL_TopDown' }, "Lighting model to use for particles.", "Lighting" ),
        LIGHTING_NORMAL = Schema.enum('LIGHTINGNORMAL_None', {'LIGHTINGNORMAL_None', 'LIGHTINGNORMAL_Facing', 'LIGHTINGNORMAL_CenterToVert', 'LIGHTINGNORMAL_Velocity' }, "Determines how lighting normal is computed.", "Lighting" ),		
        LIGHT_COLOR_TOP = Schema.color({ 1, 1, 1 }, "Light color at the top of the hemisphere.", "Lighting"),					
        LIGHT_COLOR_TOP_INTENSITY = Schema.number(1, "Light intensity at the top of the hemisphere.", "Lighting"),				
        LIGHT_COLOR_BOTTOM = Schema.color({ 1, 1, 1}, "Light color at the bottom of the hemisphere.", "Lighting"),
        LIGHT_COLOR_BOTTOM_INTENSITY = Schema.number(1, "Light intensity at the bottom of the hemisphere.", "Lighting"),					

        ANIMATION_TYPE = Schema.enum('ANIMATION_None', { 'ANIMATION_None', 'ANIMATION_Looping', 'ANIMATION_LoopingNoBlend' }, "Determines the type of flipbook texture animation to perform.", "Flipbook Animation"),		
        ANIMATION_TIME = Schema.curve(0, "The rate at which the flipbook animates.", "Flipbook Animation"),
        ANIMATION_FRAMES_PER_DIMENSION = Schema.number(2, "No idea what this means.", "Flipbook Animation"),				

        UVDISPLACEMENT_TYPE = Schema.enum('UVDISPLACEMENT_None', { 'UVDISPLACEMENT_None', 'UVDISPLACEMENT_ScreenSpaceNormalMap', 'UVDISPLACEMENT_ParticleSpaceNormalMap' }, "Determines how UVs are distorted.", "UV Animation"),
        UVDISPLACEMENT_SCROLL_RATE = Schema.vec2({ 0, 1 }, "The speed at which UVs scroll in U and V", "UV Animation"),
        UVDISPLACEMENT_TILE_RATE = Schema.vec2({ 1, 1 }, "The amount of UV tiling in U and V", "UV Animation"),
        UVDISPLACEMENT_MAGNITUDE = Schema.vec2({ 1, 1 }, "No idea what this does.", "UV Animation"),
        UVDISPLACEMENT_FACTOR = Schema.curve(0, "The scale of the displacement over the particle's lifetime.", "UV Animation"),

        USER_CURVE = Schema.curve(0, "A curve for the user defined parameter that's passed into the shader.", "User"),					               
    },
    'Particle System Data'
)

function m.getParticleDataPath(particleDataPath)
    -- Sanitize the resource name
    local sExtension = DFFile.getSuffix( particleDataPath )
    if sExtension == nil or sExtension == "" then
        particleDataPath = particleDataPath .. ".particles"
    end    
    return particleDataPath
end

function m.reloadParticleData(particleDataPath, clearCache)
    -- Check if it's in the library
	local particleData = m.particleDataLibrary[particleDataPath]
	if particleData ~= nil then
        
        if clearCache == true then
            DFDataCache.clear( "particles" )
        end
        
		local filePath = DFFile.getAssetPath( particleDataPath )
        local tData = DFDataCache.getData( "particles", filePath )
		if not tData then 
			Print(TT_Error, "Failed to load particle data at ", particleDataPath, filePath )
			return false
		end
        
        -- Unload the material data after loading the new one, so we don't release stuff that then has to be reloaded
        local prevMaterial = particleData.material
        particleData.material = nil
        local prevTexture = particleData.texture
        particleData.texture = nil
        
        -- Change all values to default
        if particleData.loaded == true then
            particleData:resetValues()
        end
        
		-- Set all attribute values
        for valueId, value in pairs(tData) do
			if valueId == DFParticleSystemData.MATERIAL then
				-- ToDo: Implement material preloading
				value = DFGraphics.loadMaterial(value)
                particleData.material = value
			end
			if valueId == DFParticleSystemData.TEXTURE then
				-- ToDo: Implement texture preloading
                particleData.texture = value
				value = DFGraphics.loadTexture(value, true)
			end
			particleData:setValue(valueId, value)
		end
        
        -- Unload the existing material, so that we don't leak resource references
        if prevMaterial ~= nil then
            DFGraphics.unloadMaterial(prevMaterial)
        end
        if prevTexture ~= nil then
            DFGraphics.unloadTexture(prevTexture)
        end
        
        particleData.loaded = true
	end
    return true
end

function m.loadParticleData(particleDataPath)
    local assetPath = m.getParticleDataPath(particleDataPath)
	local particleData = m.particleDataLibrary[assetPath]
	if particleData == nil then
		particleData = DFParticleSystemData.new()
        particleData:setDebugName(particleDataPath)
		particleData.refCount = 1
		m.particleDataLibrary[assetPath] = particleData
		-- Load the actual particle data
		if not m.reloadParticleData(assetPath) then
            m.particleDataLibrary[assetPath] = nil
            particleData = nil
        end
	else
		particleData.refCount = particleData.refCount + 1
	end
	return particleData
end

function m.unloadParticleData(particleDataPath)
    local assetPath = m.getParticleDataPath(particleDataPath)
	local particleData = m.particleDataLibrary[assetPath]
	if particleData ~= nil then
		particleData.refCount = particleData.refCount - 1
		if particleData.refCount == 0 then
            if particleData.material ~= nil then
                DFGraphics.unloadMaterial(particleData.material)
                particleData.material = nil
            end
            if particleData.texture ~= nil then
                DFGraphics.unloadTexture(particleData.texture)
                particleData.texture = nil
            end
			m.particleDataLibrary[assetPath] = nil
		end
	end
end

local assetRoot = DFFile.getAssetPath('')
function m.onFileChange(path)
    -- Treat cache paths a munged paths
    path = path:gsub('/_Cache/', '/Munged/')
    if string.find(path, assetRoot) == 1 then
        local assetPath = string.sub(path, #assetRoot + 1)
        assetPath = m.getParticleDataPath(assetPath)
        m.reloadParticleData(assetPath, true)
    end
end

-- Monitor file changes so that we can hot reload particle data
DFMoaiDebugger.dFileChanged:register(m.onFileChange)

return m
