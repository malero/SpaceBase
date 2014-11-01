local DFUtil = require "DFCommon.Util"
local url = require "moai.url"

local m = {
    tweaks = nil,           -- The active net tweaks for use by external parties
    
    url = nil,              -- The url from which to fetch the tweaks.
    clientKey,              -- The client key used to fetch the tweaks.
    
    pendingTweaks = nil,    -- The latest data from the network. Call updateTweaks() to push into tweaks()
    httpTask = nil,         -- Non-nil if an HTTP request is currently in flight.
    pollInterval = 600,     -- Seconds between requests for new tweaks from the server. Should on order of minutes.
    initialDelay = 1,       -- Initial delay before the first request. Some plats take time after boot to determine network connectivity.
    doShutdown = true,      -- An shutdown request is pending. Is for internal use only.
}

-- Public functions

-- init
-- Initialzies the lib, begins polling the server for new updates.
-- Tweaks will be cached to disk to ensure they exist even if future
-- play sessions have no network connectivity.alignSprite
--
-- tweakURL: The URL to the Moai Cloud NetTweaks service for this app.
-- clientKey: The Moai Cloud provided public key for this app. May be required by the cloud service. 
-- signature: The Moai Cloud provided private key for this app. May be required by the cloud service.
-- pollInterval: Seconds between requests for new tweaks from the cloud server.
-- initialDelay: Seconds before the first request to the cloud server.
--               Allows for platforms that need time after boot to determine network connectivity.
function m.init(tweakURL, clientKey, pollInterval, initialDelay)    
    m.doShutdown = false
    
    -- copy in external data
    m.url = tweakURL
    m.clientKey = clientKey
    
    -- override optional args
    if pollInterval ~= nil then
        m.pollInterval = pollInterval
    end
       
    if initialDelay then
        m.initialDelay = initialDelay
    end
    
    -- immediately load the last cached tweaks if possible
    local dataBuffer = MOAIDataBuffer.new()
    -- synchronous load for client simplicity
    -- can make async if we see hitches here,
    -- but should be behind a loading screen anyway.
    dataBuffer:load(m.getTweakFile())
    dataBuffer:inflate()
    -- cached tweaks go immediately into the valid tweaks table
    m.tweaks = MOAIJsonParser.decode( dataBuffer:getString() )  
    
    -- spin off a coroutine to talk to the server.
    m.pollThread = MOAICoroutine.new()
	m.pollThread:run(
        function()
            -- some platforms ping a server to establish connectivity
            -- so let's wait for a short amount of time to make sure
            -- Moai's internal network state is accurate. Otherwise,
            -- we'd potentially wait many minutes between polls.
            local initTimer = MOAITimer.new()
            initTimer:setSpan( m.initialDelay )
            initTimer:start()
            MOAICoroutine.blockOnAction(initTimer) 
        
            -- spin looking for new tasks
            while true do
                -- non mobile platforms will return CONNECTION_TYPE_WIFI even if using
                -- an Ethernet connection. Hacky but effective.
                local connectionType = MOAIEnvironment.connectionType	                	
		        if connectionType == MOAIEnvironment.CONNECTION_TYPE_WIFI or connectionType == MOAIEnvironment.CONNECTION_TYPE_WWAN then		        					
                    -- build up the full URL
                    local fullUrl = m.url .. "?"
                    
                    -- append a client key if specified                   
                    if m.clientKey then
                        fullUrl = fullUrl .. "&clientkey=" .. m.clientKey                        
                    end
                    
                    if MOAIEnvironment.appVersion then
                        fullUrl = fullUrl .. "&buildId=" .. MOAIEnvironment.appVersion
                    end
                    
                    -- create and dispatch the actual task
                    m.httpTask = MOAIHttpTask.new()
                    m.httpTask:setCallback( m.httpFinish )  
                    m.httpTask:setTimeout( 5 )               
                    m.httpTask:httpGet( fullUrl )
                end
            
                -- wait for a while or shutdown
                local timer = MOAITimer.new()
                timer:setSpan( m.pollInterval )
                timer:start()
                MOAICoroutine.blockOnAction(timer)                
            end
        end
    )
end

-- updateTweaks
-- Copies the pendingTweaks table into the tweaks table.
-- Should be called by clients at a point in game where
-- it's safe to update the tweaks.
function m.updateTweaks()
    if m.pendingTweaks then
        -- copy the table to keep it independent of the pendingTweaks ref.
        m.tweaks = DFUtil.deepCopy(m.pendingTweaks)
        m.pendingTweaks = nil
    end
end

-- shutdown
-- Terminates the NetTweaks system including any pending HTTP tasks.
function m.shutdown()    
    m.pollThread = nil
    m.httpTask = nil
    m.tweaks = nil
    m.pendingTweaks = nil
    m.doShutdown = true
end

-- Private utility functions

-- getTweakFile
--
-- returns: string path to the full tweak file.
function m.getTweakFile()
    local docDir = MOAIEnvironment.documentDirectory
    return docDir .. "/net.twk"
end

-- httpFinish
-- task: the MoaiHTTPTask that generated this callback
--
-- responseCode: the HTTP response code from the task
function m.httpFinish( task, responseCode )
    if not m.doShutdown and responseCode == 200 then
        -- tweaks come back as JSON data        
        local jsonTweaks = task:getString()
        -- invalid request will have nil string
        if jsonTweaks then
            -- store new tweaks as lua table            
            m.pendingTweaks = MOAIJsonParser.decode( jsonTweaks )
            -- cache jsonData to HD
            local dataBuffer = MOAIDataBuffer.new()
            dataBuffer:setString( jsonTweaks )
            -- zip it for obscurity and smaller size
            dataBuffer:deflate()
            -- save could be async, but sync for now for simplicity.
            dataBuffer:save( m.getTweakFile() )            
        end        
    end
    -- clear out the task pointer
    m.httpTask = nil
end

return m