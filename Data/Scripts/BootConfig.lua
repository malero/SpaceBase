local DFFile = require('DFCommon.File')
local DFUtil = require('DFCommon.Util')
local DFSaveLoad = require('DFCommon.SaveLoad')

local m = {}

local kCONFIG_FILENAME = "bootconfig.cfg"
local kDEFAULT_CONFIG = 
{
    window_resolution_w = 1280,
    window_resolution_h = 720,
    sfx_volume = 1.0,
    music_volume = 1.0,
    voice_volume = 1.0,
    show_blood = true,
    crash_reporting = true,
    autosave = true,
    use_compressed_textures = false,
    launch_fullscreen = true,
    use_os_mouse = true,
    posteffects = true,
    colorblind = false,
	normal_speed_on_alerts = true,
    pop_cap = 50, -- game will attempt to enforce this popcap of citizens (converted raiders can still exceed it)
    dev_mode = false, -- get some debug commands, without having a debug build.
    auto_start = false, -- start game without initial menu, if you already have a base.
    low_ui = false, -- don't show hint and alert panes.
}

-- these are old values that should be removed from the settings
local kDEPRECATED_VALUES =
{
    enable_post_effects = true,
}

function m.init()
    local obj = {}
    
    if DFSpace.isDev() or MOAIEnvironment.osBrand == "Linux" then
        kDEFAULT_CONFIG.launch_fullscreen = false
    end
    
    -- due to high possibility of lower memory graphics cards on these operating systems, we are using compressed textures by default
    if MOAIEnvironment.osBrand == "OSX" then -- or MOAIEnvironment.osBrand == "Linux" then
        kDEFAULT_CONFIG.use_compressed_textures = true
    end
    
    function obj:load()   
        local tData = self:_loadConfig()
        
        if not tData then 
            tData = kDEFAULT_CONFIG 
        end
        
        -- save it out again in case we have added new values to the kDEFAULT_CONFIG
        self:_saveConfig(tData)
        
        m.tData = tData
    end

    function obj:_loadConfig()
        local sPath = DFSaveLoad._getSaveDir() .. kCONFIG_FILENAME
        
        --[[
        -- skip dofile and just load our config into a string
        local buf = MOAIDataBuffer.new()
        local success = buf:load(filePath)
        local luaStr = buf:getString()
        local luaF = loadstring(luaStr)
        local data = luaF()
        -- do not tell my parents I did this
        ]]--
        
	print("loading config from file: " .. sPath)

        local dataBuffer = MOAIDataBuffer.new()
        dataBuffer:load( sPath )
        --dataBuffer:inflate()
        local jsonTable = dataBuffer:getString()
        local tData = MOAIJsonParser.decode( jsonTable )
        
        -- now loop through default config and make sure to add any new values
        if tData then
            for k,v in pairs(kDEFAULT_CONFIG) do
                if nil == tData[k] then
                    tData[k] = v
                end
            end
            
            -- remove any deprecated values
            for k,v in pairs(kDEPRECATED_VALUES) do
                if tData[k] then
                    tData[k] = nil
                end
            end
        end
        
        return tData
    end

    function obj:_saveConfig(tData)
        local sPath = DFSaveLoad._getSaveDir() .. kCONFIG_FILENAME
        
        local jsonTable = MOAIJsonParser.encode( tData )
        local dataBuffer = MOAIDataBuffer.new()
        
        -- add \n for every comma, {, and } (this file needs to be human editable)
        jsonTable = jsonTable:gsub(',', ',\n')
        jsonTable = jsonTable:gsub('{', '{\n ')
        jsonTable = jsonTable:gsub('}', '\n}')
        
        dataBuffer:setString( jsonTable )   
        --dataBuffer:deflate()             
        dataBuffer:save( sPath, false )
    end

    function obj:getConfigValue(sKey)
        return m.tData[sKey]
    end
    
    function obj:setConfigValue(sKey, newValue)
        m.tData[sKey] = newValue
        self:_saveConfig(m.tData)
    end
    
    obj:load()
    return obj
end


return m
