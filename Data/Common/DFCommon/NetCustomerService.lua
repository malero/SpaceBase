local DFUtil = require "DFCommon.Util"
local url = require "moai.url"

local m = 
{
    requests = nil,         -- the requests that the server says we should be granting
    bootMessage = nil,      -- message to show to the user 1 time while booting the app
    url = nil,              -- The url from which to fetch the csr requests and messages.
    clientKey,              -- The client key used to fetch the requests.
    
    pendingRequests = nil,  -- The latest data from the network. Call updateRequests() to push into requests()
    httpTask = nil,         -- Non-nil if an HTTP request is currently in flight.
    pollInterval = 600,     -- Seconds between requests from the server. Should on order of minutes.
    initialDelay = 1,       -- Initial delay before the first request. Some plats take time after boot to determine network connectivity.
    doShutdown = true,      -- An shutdown request is pending. Is for internal use only.
}

function m.init(url, clientKey, pollInterval, initialDelay)
    m.doShutdown = false
    
    -- copy in external data
    m.url = url
    m.clientKey = clientKey
    
    -- override optional args
    if pollInterval then
        m.pollInterval = pollInterval
    end
       
    if initialDelay then
        m.initialDelay = initialDelay
    end
    
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
                    local fullUrl = m.url .. "?player_id=" .. MOAIEnvironment.udid
                    
                    -- append a client key if specified                   
                    if m.clientKey then
                        fullUrl = fullUrl .. "&clientkey=" .. m.clientKey
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

-- see if we have any pending requests and copy them override
function m.checkRequests()
    if m.pendingRequests then
        m.requests = m.pendingRequests
        m.pendingRequests = nil
    end
end

function m.clearRequests()
    m.pendingRequests = nil
    m.requests = nil
end

-- shutdown
-- Terminates the NetCustomerService system including any pending HTTP tasks.
function m.shutdown()    
    m.pollThread = nil
    m.httpTask = nil
    m.requests = nil
    m.pendingRequests = nil
    m.doShutdown = true
end

-- httpFinish
-- task: the MoaiHTTPTask that generated this callback
--
-- responseCode: the HTTP response code from the task
function m.httpFinish( task, responseCode )
    if not m.doShutdown and responseCode == 200 then
        -- tweaks come back as JSON data        
        local jsonResults = task:getString()
        -- invalid request will have nil string
        if jsonResults then
            -- store new tweaks as lua table
            local retRequests = MOAIJsonParser.decode( jsonResults )     
            if retRequests.requests then
                m.pendingRequests = retRequests.requests
            end
        end        
    end
    -- clear out the task pointer
    m.httpTask = nil
end


return m
