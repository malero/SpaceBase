local DFFile = require('DFCommon.File')
local DFUtil = require('DFCommon.Util')

local m = {
}

function m.getSaveFilename( baseName )
    return m._getSaveDir() .. baseName .. ".sav"
end

-- saveTable
-- Serialzies the specified table to disk.
-- May include compression and encryption of data.
-- 
-- saveTable: The table to save to disk.
-- fileName: The name of the file to save (w/ out extension)
-- useSaveHeader: (Optional) - add information to this save file such as how many times it has been saved
--                              and when.
function m.saveTable(saveTable, fileName, useSaveHeader)
    if not saveTable then
        saveTable = {}
    end

    if useSaveHeader then
        if not saveTable.__nNumSaves then
            saveTable.__nNumSaves = 0
        end
        
        -- increment the number of times this table has been saved
        saveTable.__nNumSaves = saveTable.__nNumSaves + 1
        
        saveTable.__nSaveTime = os.time()
    end
    
    local jsonTable = MOAIJsonParser.encode( saveTable )
    local dataBuffer = MOAIDataBuffer.new()
    dataBuffer:setString( jsonTable )   
    dataBuffer:save( m.getSaveFilename( fileName..'DBG' ), false )
    dataBuffer:deflate()             
    dataBuffer:save( m.getSaveFilename( fileName ), false )
end

-- loadTable
-- Deserializes a saved file.
-- May decompress or decrypt saved data.
--
-- fileName: Name of the file to load (w/ out extensions)
-- returns: Deserialzied data as a table.
function m.loadTable(fileName)
    local dataBuffer = MOAIDataBuffer.new()
    dataBuffer:load( m.getSaveFilename( fileName ) )
    dataBuffer:inflate()
    local jsonTable = dataBuffer:getString()
    return MOAIJsonParser.decode( jsonTable )
end

function m.saveString(saveStr, fileName, bPreservePath, bNoDeflate)
    local path = fileName
    if not bPreservePath then
        path = m.getSaveFilename( path )
    end
    local dataBuffer = MOAIDataBuffer.new()
    dataBuffer:setString( saveStr )   
    if not bNoDeflate then
        dataBuffer:deflate()
    end
    dataBuffer:save( path, false )

    --[[
    local file = io.open ( path, 'w' )
    file:write(saveStr)
    file:close()
    ]]--
end

function m.loadString(fileName, bPreservePath, bSilenceErrors)
    -- works fine; just commented out for now so I can have human-readable saves.
    local path = fileName
    if not bPreservePath then
        path = m.getSaveFilename(path)
    end
    local dataBuffer = MOAIDataBuffer.new()
    dataBuffer:load( path )
    if dataBuffer:testHeader('--MOAI') then
        -- nothing
    else
        dataBuffer:inflate()
    end
    local str = dataBuffer:getString()
    if str then
        local f,err = loadstring(str)
        if f then return f()
        elseif not bSilenceErrors then
            Print(TT_Error, "Failed to load file",fileName,"error:",err)
        end
    end
end

-- Private Functions

-- _getSaveDir
-- Returns the sub-folder for saving.
function m._getSaveDir()
    local saveDir = MOAIEnvironment.documentDirectory .. "/Saves/"
     MOAIFileSystem.affirmPath(saveDir)
    return saveDir
end


--------------------------------------------------------------------
-- Cloud Saves
--

local CloudSaves = {}

local kTIME_BETWEEN_CLOUD_AUTO_POLLS = 5

local kENABLE_TEST_CLOUDSAVE = false
local kDELAY_BEFORE_LOAD_TEST = 40

CloudSaves.tAutoLoadList = {}
CloudSaves.sTestData = nil
CloudSaves.nTotalElapsed = 0
CloudSaves.nTimeUntilNextCloudLoad = kTIME_BETWEEN_CLOUD_AUTO_POLLS
CloudSaves.nTimeOfLastLoad = -1
CloudSaves.rListener = nil
CloudSaves.nTimeOfLastSave = -1
CloudSaves.bCloudSaveQueued = false

function CloudSaves.isEnabled()
    -- currently only supports iOS (using iCloud), and then only if they have enabled iCloud. Complicated!
    --  eventually this should support cross-platform saves on our own server.

    return (MOAIiCloud and MOAIiCloud.isEnabled()) or (kENABLE_TEST_CLOUDSAVE)
end

-- a listener must have a "onCloudSaveLoaded" function; listeners are optional, only required if you
--  want to use auto-loading (which is recommended but not required).
function CloudSaves.init(listener)
    local success = false
	
	CloudSaves.rListener = listener

	if CloudSaves.isEnabled() then
        if kENABLE_TEST_CLOUDSAVE then
            print("using cloudsave test data from: " .. m._getSaveDir())
			success = true
        else
            print("attempting to initialize iCloud")
            success = MOAIiCloud.init()
            CloudSaves.nTimeUntilNextCloudLoad = 2 -- try again in a couple seconds
        end
    else
		print("iCloud not enabled.")    
    end
	
	return success
end

-- periodically poll for new data and also allow for weird testing
function CloudSaves.update(nElapsed)
    if CloudSaves.isEnabled() then
    
    
        CloudSaves.nTotalElapsed = CloudSaves.nTotalElapsed + nElapsed
        
        CloudSaves.nTimeUntilNextCloudLoad = CloudSaves.nTimeUntilNextCloudLoad - nElapsed

        if kENABLE_TEST_CLOUDSAVE then
            if CloudSaves.nTimeUntilNextCloudLoad < 0 then
                print("test cloud load would occur now.")
                CloudSaves.nTimeUntilNextCloudLoad = CloudSaves.nTimeUntilNextCloudLoad + kTIME_BETWEEN_CLOUD_AUTO_POLLS
            elseif CloudSaves.nTimeOfLastLoad < 0 and CloudSaves.nTotalElapsed > kDELAY_BEFORE_LOAD_TEST then
                for key,value in pairs(CloudSaves.tAutoLoadList) do
                    CloudSaves.nTimeOfLastLoad = CloudSaves.nTotalElapsed
                    
                    local sTestData = ""
                    
                    -- load the test file!
                    local testFilePath = m._getSaveDir() .. key .. ".txt"
                    local testFile = io.open(testFilePath, 'r')
                    
                    if testFile then
                        sTestData = testFile:read ( '*all' )
                        testFile:close()
                    end
                    
                    CloudSaves.sTestData = sTestData
                    
                    -- fire off the listener
                    CloudSaves.loadData(key)
                end
            end
        else
            if CloudSaves.nTimeUntilNextCloudLoad < 0 then
                for key,value in pairs(CloudSaves.tAutoLoadList) do
                	if CloudSaves.isNewDataAvailable(key) then
                		print("new cloud save data available, loading key: " .. key)
	                    CloudSaves.loadData(key)
	            	end
                end
                
                CloudSaves.nTimeOfLastLoad = CloudSaves.nTotalElapsed
                CloudSaves.nTimeUntilNextCloudLoad = CloudSaves.nTimeUntilNextCloudLoad + kTIME_BETWEEN_CLOUD_AUTO_POLLS
            end
        end
    end
end

function CloudSaves.shutdown()
    if CloudSaves.isEnabled() then
        if not kENABLE_TEST_CLOUDSAVE then
            MOAIiCloud.shutdown()
        end
    end
end

function CloudSaves.saveData(sDataKey, tData, rListener)
    if CloudSaves.isEnabled() then
        CloudSaves.nTimeOfLastSave = CloudSaves.nTotalElapsed

        local jsonTable = MOAIJsonParser.encode( tData )    
        
        if not jsonTable then
        	jsonTable = ""
        end
        
        if kENABLE_TEST_CLOUDSAVE then
            print("test cloudsave with key: '" .. sDataKey .. "' and data:\n" .. jsonTable .. "\n\n");
        else
        	print("saving to cloud for key: " .. sDataKey .. ", time of save: " .. CloudSaves.nTimeOfLastSave)
            MOAIiCloud.saveData(sDataKey, jsonTable)
        end
    end
end

function CloudSaves.loadData(sDataKey, bAutoloadThisLater)
    if bAutoloadThisLater then
        CloudSaves.tAutoLoadList[sDataKey] = true
    end
    
    local tData = nil
    
    if CloudSaves.isEnabled() and CloudSaves.isDataAvailable(sDataKey) then
    
        local jsonTable = nil
    
        if kENABLE_TEST_CLOUDSAVE then
            jsonTable = CloudSaves.sTestData
        else
            jsonTable = MOAIiCloud.loadData(sDataKey)
        end
        
        print("cloud save loaded table:\n\n" .. jsonTable .. "\n\n")
        
        tData = MOAIJsonParser.decode(jsonTable)
        
        CloudSaves.nTimeOfLastLoad = os.time()
    end
    
    if CloudSaves.rListener and tData then
    	print("cloud saves firing onLoad event!")
        CloudSaves.rListener:onCloudSaveLoaded(sDataKey, tData)
    else
    	print("no onLoad listener for cloud save load? or tData is nil: " .. tostring(tData))
    end
    
    return tData
end

function CloudSaves.isDataAvailable(sDataKey)
    local isAvailable = false

    if kENABLE_TEST_CLOUDSAVE then
        isAvailable = (CloudSaves.sTestData ~= nil)
    else
        isAvailable = (CloudSaves.isEnabled() and MOAIiCloud.isDataAvailable(sDataKey))
    end
    
    return isAvailable
end

function CloudSaves.isNewDataAvailable(sDataKey)
    local isAvailable = false

    if kENABLE_TEST_CLOUDSAVE then
        isAvailable = (CloudSaves.sTestData ~= nil)
    else
        isAvailable = (CloudSaves.isEnabled() and MOAIiCloud.isNewDataAvailable(sDataKey))
    end
    
    return isAvailable
end

m.CloudSaves = CloudSaves

return m
