local Delegate = {}

function Delegate.new()
    local self = {}
    setmetatable(self, { __index = Delegate })
    self._tRecords = {}
    return self
end

function Delegate:dispatch(...)
    local dispatched = nil
    local tUnregisterList = {}    
    for _, tRecord in ipairs(self._tRecords) do
        if not tRecord.firstArg then
            dispatched = tRecord.listener(...)
        else
            dispatched = tRecord.listener(tRecord.firstArg, ...)
        end
        
        if dispatched == nil then
            dispatched = true
        end
    end
    return dispatched
end

function Delegate:register(listener, firstArg)
    -- no duplicate records!
    local bFound = false
    for i, tRecord in ipairs(self._tRecords) do
        if listener == tRecord.listener and firstArg == tRecord.firstArg then
            bFound = true
            break
        end
    end
    
    if not bFound then
        local tRecord = {}
        tRecord.listener = listener
        tRecord.firstArg = firstArg
        table.insert(self._tRecords, tRecord)
        
        -- dispatch to anyone listening that we've registered something
        -- this can be used to trap for a lack of matching register/unregister calls
        -- without having to create a custom interface
        Delegate.dRegistered:dispatch( listener, firstArg )
    else
        Trace( TT_Warning, "Trying to register a record that already exists! "..tostring(listener).." "..tostring(firstArg) )
    end
end

function Delegate:unregister(listener, firstArg)
    for i, tRecord in ipairs(self._tRecords) do
        if listener == tRecord.listener and firstArg == tRecord.firstArg then
            table.remove(self._tRecords, i)
            -- dispatch to anyone listening that we've unregistered something
            -- this can be used to trap for a lack of matching register/unregister calls
            -- without having to create a custom interface
            Delegate.dUnregistered:dispatch( listener, firstArg )
            return
        end
    end
end

Delegate.dRegistered = Delegate.new()
Delegate.dUnregistered = Delegate.new()

return Delegate
