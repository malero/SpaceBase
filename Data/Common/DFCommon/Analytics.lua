local DFUtil = require("DFCommon.Util")
local url = require("moai.url")

-- TODO List
-- * Use HTTP Post instead of HTTP Get to transmit stats
-- * Zip stat transmission payload
-- * Sign stats payload
-- * Timestamp stats
-- * Sleep a bit longer after failures
-- * Save to disk less often, flush on shutdown

local m = {    
    initialized = false,
    suspended = false,
    stats = {},
    pendingTransmissions = {},    
    apsalarBaseURI = "http://e.apsalar.com/api/v1/",
    moaiBaseURI = nil,
    lastSaveTime = nil,    
    lastHttpSendTime = nil,
    lastStatSendTime = nil,    
    transmissionLogUnsaved = false,
    statsUnsaved = false,
    bTrackInternalTelemetry = true,
    nTotalEventCalls = 0,
    nTotalHTTPReqs = 0,
    nTransmissionsSinceIdle = 0,
    fnInternalTelemError = nil,
}



local kPRINT_DEBUG_INFO = false
local kMAX_FAILURES_NORMAL = 5
local kMAX_FAILURES_CRITICAL = 10
local kHTTP_TIMEOUT = 5
local kSAVE_INTERVAL = 30
local kSTAT_SEND_INTERVAL = 300 -- default to 5 minutes, this is tweakable!
local kACTIVE_WAIT_INTERVAL = 0.1
local kIDLE_WAIT_INTERVAL = 10
local kMAX_TRANSMISSIONS_BEFORE_IDLE = 10

-- init
-- Initializes the analytics system. This also begins a polling process 
-- that will periodically push analytics data from the local store
-- to the network (if available).
--
-- apsalarApiKey: The public key for the service
-- apsalarApiSecret: The private key for the service
-- moaiClientKey: The client key setup for this app in the Moai Cloud dashboard.
function m.init(apsalarBaseURI, apsalarApiKey, apsalarApiSecret, moaiBaseURI, moaiClientKey)

    -- break out if we've already done this
    if m.initialized then
        return
    end

    m.initialized = true
    m.lastStatSendTime = os.time()
    m.apsalarBaseURI = apsalarBaseURI
    m.apsalarApiKey = apsalarApiKey
	m.apsalarApiSecret = apsalarApiSecret
    m.moaiBaseURI = moaiBaseURI
    m.moaiClientKey = moaiClientKey
    local now = os.time()
	m.sessionStartTime = now
    m.lastHttpSendTime = now
	m.sessionId = MOAIEnvironment.generateGUID()
    m.osBrand = MOAIEnvironment.osBrand
    if m.osBrand == "Linux" or m.osBrand == "OSX" or m.osBrand == "Windows" then
	    -- Appsalar not officially supported on some platforms, lie about m.osBrand
        -- osVersion will still reflect "real" version.
		m.osBrand = "iOS"
    end    
           
    m.loadData()
    
    m.pushThread = MOAICoroutine.new()
	m.pushThread:run(
        function()
            while true do     
                local now = os.time()
 
                if now - m.lastSaveTime > kSAVE_INTERVAL then
                    m.saveData(true)                    
                end
                
                if now - m.lastStatSendTime > kSTAT_SEND_INTERVAL then
                    m.telemSendFullStats()                      
                end
            
                local hasNetwork = MOAIEnvironment.connectionType == MOAIEnvironment.CONNECTION_TYPE_WIFI or MOAIEnvironment.connectionType == MOAIEnvironment.CONNECTION_TYPE_WWAN                                              
                if hasNetwork and # m.pendingTransmissions > 0 and m.httpTask == nil and m.nTransmissionsSinceIdle < kMAX_TRANSMISSIONS_BEFORE_IDLE then                    
                    local transmission = m.pendingTransmissions[1]
                    local url = ""
                    if (transmission.type == "internal" and m.bTrackInternalTelemetry) or transmission.type == "stats" then
                        url = transmission.url   
                        url = url .. "&session_id=" .. transmission.sessionId
                        url = url .. "&player_id=" .. MOAIEnvironment.udid
                        url = url .. "&time=" .. transmission.time
                    elseif transmission.type == "apsalar_start" or transmission.type == "apsalar_event" then
                        url = transmission.url
                        
                        local connectionType = MOAIEnvironment.connectionType == MOAIEnvironment.CONNECTION_TYPE_WIFI and "wifi" or "wwan"                            		
                        url = url .. "&c=" .. connectionType
                                
                        if m.pendingTransmissions[1] == "apsalar_event" then
                            url = url .. "&lag=" .. os.time () - transmission.time
                        end
                    else
                        -- we got a transmission type that we don't want to handle, so drop it
                        table.remove( m.pendingTransmissions, 1 )      
                        m.transmissionLogUnsaved = true    
                    end
                    
                    if url ~= "" then   
                        m.lastHttpSendTime = now
                        m.nTransmissionsSinceIdle = m.nTransmissionsSinceIdle + 1
                    
                        -- event handler for httpTask completion
                        local sendCallback = function( httpTask ) 
                            local success = false
                            local result = MOAIJsonParser.decode( httpTask:getString() )
                            
                            if httpTask.transmission.type == "internal" or httpTask.transmission.type == "stats" then 
                                local responseCode = httpTask:getResponseCode()
                                
                                if result and result.error then
                                    if result.error == "stop" then
                                        m.bTrackInternalTelemetry = false
                                    elseif result.error == "resume" then
                                        m.bTrackInternalTelemetry = true
                                    end
                                    
                                    if m.fnInternalTelemError then
                                        m.fnInternalTelemError(result)
                                    end
                                end
                                
                                success = responseCode == 200                                
                            else
                                if result and result.status == "ok" then
                                    success = true
                                end
                            end
                            
                            if success then
                                table.remove( m.pendingTransmissions, 1 )                                

                                if kPRINT_DEBUG_INFO then
                                    print("finished running analytics request: " .. url)
                                    print(# m.pendingTransmissions .. " analytics requests remaining.")
                                end
                                
                                m.transmissionLogUnsaved = true
                            else                                
                                m.pendingTransmissions[1].failures = m.pendingTransmissions[1].failures + 1
                                
                                -- backwards compat
                                if m.pendingTransmissions[1].maxFailures ==  nil then
                                    m.pendingTransmissions[1].maxFailures = 5
                                end
                                
                                if m.pendingTransmissions[1].failures > m.pendingTransmissions[1].maxFailures then
                                    table.remove( m.pendingTransmissions, 1 )      
                                    m.transmissionLogUnsaved = true                              
                                end
                            end  
                            
                            m.httpTask = nil
                        end
                        
                        -- dispatch a task
                        m.httpTask = MOAIHttpTask.new()
                        m.httpTask.transmission = transmission
                        m.httpTask:setCallback( sendCallback )
                        m.httpTask:setTimeout( kHTTP_TIMEOUT )      
                        
                        m.nTotalHTTPReqs = m.nTotalHTTPReqs + 1
                        
                        if kPRINT_DEBUG_INFO then
                            print("nTransmissionsSinceIdle: " .. m.nTransmissionsSinceIdle)
                            print("sending analytics URL call: " .. url)
                        end
                        
                        m.logTelemStats()
      
                        m.httpTask:httpGet( url )                        
                    else
                        table.remove( m.pendingTransmissions, 1 )                        
                    end
                else
                    if not hasNetwork or # m.pendingTransmissions == 0 or m.nTransmissionsSinceIdle >= kMAX_TRANSMISSIONS_BEFORE_IDLE then
                        -- if we have nothing to do, we'll wait for a bit
                        m.nTransmissionsSinceIdle = 0
                        DFUtil.sleep(kIDLE_WAIT_INTERVAL)
                    else
                        -- but if we have events to process, we'll process ASAP
                        DFUtil.sleep(kACTIVE_WAIT_INTERVAL)
                    end
                end                
            end
        end
    )
end

-- call this when you're done customizing stuff after init
function m.start()
    m.telemSendFullStats()
               
    m.apsalarStart()
    m.sessionStart()
end

-- logEvent
-- Records an analytics event.
--
-- eventName: The string id of the event
-- eventData: The data describing the event.
function m.logEvent(eventName, eventData)
    if not m.initialized then
        return
    end
    
    m.nTotalEventCalls = m.nTotalEventCalls + 1
    m.logTelemStats()
    
    if kPRINT_DEBUG_INFO then
        print("analytics logEvent: " .. eventName)
    end
    
    m.telemEvent(eventName, eventData)
    m.apsalarEvent(eventName, eventData)    
end

function m.logTelemStats()
    local totalElapsed = MOAISim.getElapsedTime()
    
    local totalMinutes = totalElapsed / 60.0
    local eventsPerMinute = m.nTotalEventCalls / totalMinutes
    local httpReqsPerMinute = m.nTotalHTTPReqs / totalMinutes

    m.logStat("http_rpm", httpReqsPerMinute)
    m.logStat("evts_pm", eventsPerMinute)
    
    if kPRINT_DEBUG_INFO then
        print("\n\n----------------------------\nTelem Stats:\n")    
        print(" * total Minutes: " .. totalMinutes)
        print(" * total HTTP Requests: " .. m.nTotalHTTPReqs)
        print(" * total events: " .. m.nTotalEventCalls)
        print(" * events per minute: " .. eventsPerMinute)
        print(" * http reqs per minute: " .. httpReqsPerMinute)
    
        print("\n\n\n")
    end
end

-- setStatSendInterval
-- How often should we send those stats, guy?
function m.setStatSendInterval(nTimeInSeconds)
    kSTAT_SEND_INTERVAL = nTimeInSeconds
end

function m.setActiveWaitInterval(nTimeInSeconds)
    kACTIVE_WAIT_INTERVAL = nTimeInSeconds
end

function m.setIdleWaitInterval(nTimeInSeconds)
    kIDLE_WAIT_INTERVAL = nTimeInSeconds
end

function m.setMaxTransmissionsBeforeIdle(nNumTransmissions)
    kMAX_TRANSMISSIONS_BEFORE_IDLE = nNumTransmissions
end

-- logStat
-- Records an analytics stat.
--
-- key: The name of the stat.
-- value: The data for the stat.
function m.logStat(key, value)
    if not m.initialized then
        return
    end
    m.stats[key] = DFUtil.deepCopy(value)
    m.statsUnsaved = true
      
    -- build up the full URL
    local fullURL = m.moaiBaseURI .. "?"   
    -- append a client key if specified
    if m.moaiClientKey then
        fullURL = fullURL .. "clientkey=" .. m.moaiClientKey .. "&"
    end
    
    local stat = {}
    stat[key] = value
    fullURL = fullURL .. url.encode({ onestat = MOAIJsonParser.encode( stat ) } )
    
    -- NSM: This is too much data to transmit currently.
    -- We can get much of what we need from events anyway.
    --m.transmitData(fullURL, "internal", kMAX_FAILURES_NORMAL)
end

-- incrStat
-- Increases analytics stat. Will create stat if none exists
--
-- key: The name of the stat.
-- value: The amount by which to increment the stat.
function m.incrStat(key, value)
    if not m.initialized then
        return
    end
    
    if m.stats[key] == nil then
        m.stats[key] = 0
    end
    
    if value == nil then
        value = 0
    end
    m.logStat( key, m.stats[key] + value )
end

function m.suspend()
    if m.initialized then
        m.shutdown()
        m.suspended = true
    end
end

function m.resume()
    if m.suspended then
        m.init(m.apsalarBaseURI, m.apsalarApiKey, m.apsalarApiSecret, m.moaiBaseURI, m.moaiClientKey)
        m.suspended = false
    end
end

-- shutdown
-- Terminates the analytics service.
function m.shutdown()
    if m.initialized then        
        m.apsalarEnd()
        m.sessionEnd()
        m.saveData(false)        
        m.pushThread = nil
        m.httpTask = nil
        m.initialized = false
    end
end

-- Private utility functions

function m.apsalarAddSecurityHash( queryString )
	local hash = crypto.evp.digest ( "sha1", m.apsalarApiSecret .. "?" .. queryString )
	queryString = queryString .. "&h=" .. hash
	return queryString
end

function m.apsalarStart()
	
	if m.apsalarApiKey == nil or m.apsalarApiSecret == nil then
		return false
	end
	       
    local params = {
    	a 	= m.apsalarApiKey,
		av 	= MOAIEnvironment.appVersion,
		i 	= MOAIEnvironment.appID,
		n	= MOAIEnvironment.appDisplayName,		
		p 	= m.osBrand,
		rt 	= "json",
		s 	= m.sessionId,
		u 	= MOAIEnvironment.udid,
		v 	= MOAIEnvironment.osVersion,
    }
    			
	if m.osBrand == "Android" then
		params.ab = MOAIEnvironment.cpuabi
        params.br = MOAIEnvironment.devBrand
        params.de = MOAIEnvironment.devName
        params.ma = MOAIEnvironment.devManufacturer
        params.mo = MOAIEnvironment.devModel
        params.pr = MOAIEnvironment.devProduct
    end
			
	local queryString = url.encode( params )    
	local fullURL = m.apsalarBaseURI .. "start?" .. m.apsalarAddSecurityHash( queryString )    
    m.transmitData( fullURL, "apsalar_start", kMAX_FAILURES_CRITICAL )    
    return true
end

function m.apsalarEvent( name, data )	
	if m.apsalarApiKey == nil or m.apsalarApiSecret == nil then
		return false
	end
    
    local params = {
		a 	= m.apsalarApiKey,
		e   = MOAIJsonParser.encode( data ),
		i 	= MOAIEnvironment.appID,
		n 	= name,
		p 	= m.osBrand,
		rt 	= "json",
		s 	= m.sessionId,
		t 	= os.time() - m.sessionStartTime,
		u 	= MOAIEnvironment.udid,
	}
			
	local queryString = url.encode( params )    	
	local fullURL = m.apsalarBaseURI .. "event?" .. m.apsalarAddSecurityHash( queryString )	
    m.transmitData( fullURL, "apsalar_event", name == 'end_session' and kMAX_FAILURES_CRITICAL or kMAX_FAILURES_NORMAL )    
    return true
end

function m.apsalarEnd()	
	m.apsalarEvent('end_session')
end

function m.sessionStart()
    m.telemEvent('start_session', { osbrand = m.osBrand, osver = MOAIEnvironment.osVersion, appver = MOAIEnvironment.appVersion, appbld = MOAIEnvironment.appBuild, appid = MOAIEnvironment.appID } )
end

function m.sessionEnd()	
	m.telemEvent('end_session')
end

function m.telemSendFullStats()
    if m.stats ~= nil and next(m.stats) ~= nil then        
        local fullURL = m.moaiBaseURI .. "?"
        -- append a client key if specified                   
        if m.moaiClientKey then
            fullURL = fullURL .. "clientkey=" .. m.moaiClientKey .. "&"
        end
        fullURL = fullURL .. url.encode({ player_id = MOAIEnvironment.udid, allstats = MOAIJsonParser.encode(m.stats) })        
        m.transmitData(fullURL, "stats", kMAX_FAILURES_CRITICAL)            
    end
    m.lastStatSendTime = os.time()
end

function m.setInternalTelemetryEnabled(bEnabled)
    m.bTrackInternalTelemetry = bEnabled
end

function m.setInternalTelemetryErrorCallback(fnCallback)
    m.fnInternalTelemError = fnCallback
end

function m.telemEvent( name, data )
    if m.bTrackInternalTelemetry then
        local fullURL = m.moaiBaseURI .. "?"
        -- append a client key if specified                   
        if m.moaiClientKey then
            fullURL = fullURL .. "clientkey=" .. m.moaiClientKey .. "&"
        end    
        
        fullURL = fullURL .. url.encode({ player_id = MOAIEnvironment.udid, event = name, data = MOAIJsonParser.encode(data) })        
        m.transmitData(fullURL, "internal", kMAX_FAILURES_NORMAL)
    end
end

function m.transmitData( url, type, maxFailures )    
    local record = { url = url, time = os.time(), sessionId = m.sessionId, type = type, failures = 0, maxFailures = maxFailures }    
    table.insert( m.pendingTransmissions, record )    
    m.transmissionLogUnsaved = true
end

function m.saveData(saveAsync)
    m.savePendingTransmissions(saveAsync)
    m.saveStats(saveAsync)
    m.lastSaveTime = os.time()
end

function m.loadData()
    m.loadPendingTransmissions()
    m.loadStats()
    m.lastSaveTime = os.time()
end

-- getStatsFile
--
-- returns: string path to the full tweak file.
function m.getStatsFile()
    local docDir = MOAIEnvironment.documentDirectory
    return docDir .. "/Stats/game.sta"
end

function m.getTransmissionsFile()
    local docDir = MOAIEnvironment.documentDirectory
    return docDir .. "/Stats/transmission.que"
end

function m.savePendingTransmissions(saveAsync)
    if m.transmissionLogUnsaved then
        local dataBuffer = MOAIDataBuffer.new()
        dataBuffer:setString( MOAIJsonParser.encode( m.pendingTransmissions ) )
        dataBuffer:deflate()
        if saveAsync then 
            dataBuffer:saveAsync( m.getTransmissionsFile() )
        else
            dataBuffer:save( m.getTransmissionsFile() )
        end    
        m.transmissionLogUnsaved = false
    end
end

function m.saveStats(saveAsync)    
    if m.statsUnsaved then
        local dataBuffer = MOAIDataBuffer.new()
        dataBuffer:setString( MOAIJsonParser.encode( m.stats ) )    
        dataBuffer:deflate()   
        if saveAsync then 
            dataBuffer:saveAsync( m.getStatsFile() )
        else
            dataBuffer:save( m.getStatsFile() )
        end
        m.statsUnsaved = false
    end
end

function m.loadPendingTransmissions()    
    local dataBuffer = MOAIDataBuffer.new()    
    if dataBuffer:load(m.getTransmissionsFile()) then
        dataBuffer:inflate()
        m.pendingTransmissions = MOAIJsonParser.decode( dataBuffer:getString() )
        if m.pendingTransmissions == nil then
            m.pendingTransmissions = {}
        end
    end
    m.transmissionLogUnsaved = false
end

function m.loadStats()        
    local dataBuffer = MOAIDataBuffer.new()    
    if dataBuffer:load(m.getStatsFile()) then
        dataBuffer:inflate()
        m.stats = MOAIJsonParser.decode( dataBuffer:getString() )    
        if m.stats == nil then
            m.stats = {}
        end
    end
    m.statsUnsaved = false
end

return m