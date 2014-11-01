local Delegate = require('DFMoai.Delegate')

local Debugger = {}

-- Store the module into a global so that it's accessible by the remote debugger
__debuggerHandler = Debugger

function Debugger:initialize()
    self.dFileChanged = Delegate.new()
end

function Debugger:sendMessage(messageName, messageParam)
    local message = { source = 'dfmoai.debugger', name = messageName, param = messageParam }
    if DF2hb then
        DF2hb.sendMessage(message)
    elseif MOAIHarness then
        MOAIHarness.sendMessage(message)
    end
end

function Debugger:_updateTable(tTarget, tInput, tVisited)
    if not tVisited then
        tVisited = {}
    end
    if tVisited[tTarget] then
        return
    end
    tVisited[tTarget] = true
    
    if type(tTarget) == 'table' and type(tInput) == 'table' then
        
        -- Assign all functions in tInput to tTarget
        for key, value in pairs(tInput) do
            tTarget[key] = value
        end
        
        -- Recurse to child tables
        for key, value in pairs(tTarget) do
            if type(value) == 'table' then
                tInputValue = tInput[key]
                if tInputValue then
                    self:_updateTable(value, tInputValue, tVisited)
                end
            end
        end
        
    end
end

function Debugger:_onLuaFileChange(path)
    -- Grab the registry and configuration's path markers
    local loaded = debug.getregistry()._LOADED
    local dirsep, pathsep, pathMark = package.config:sub(1, 1), package.config:sub(3, 3), package.config:sub(5, 5)
    
    -- Convert the canonical path to platform form
    path = path:gsub('/', dirsep)
    for name, module in pairs(loaded) do
        local relPath = name:gsub('%.', dirsep)
        
        -- Place the relative path in each of the path templates
        local prevIndex = 0
        while prevIndex <= package.path:len() do
            local sepIndex = package.path:find(pathsep, prevIndex + 1)
            if not sepIndex then
                sepIndex = package.path:len() + 1
            end
        
            local template = package.path:sub(prevIndex + 1, sepIndex - 1)            
            local fullPath = template:gsub(pathMark, relPath)
            fullPath = fullPath:gsub('/', dirsep)
           
            -- If the full path is a match, force reload that module
            if fullPath == path then
                local thunk, err = loadfile(fullPath)
                if thunk then
                    -- probably better to call this directly rather than pcall, so
                    -- we get a stack trace
                    input = thunk()
                    self:_updateTable(module, input)
                else
                    print(string.format("%s, %s: did not compile: %s", fullPath, name, err))
                end
                return
            end
            
            prevIndex = sepIndex
        end
    end
end

function Debugger:_onFileChange(path)
    local status,err
    print('onfilechange start',path)
    if path.match(path, "%.lua$") then
        status, err = pcall(Debugger._onLuaFileChange,Debugger,path)
        if not status then
            print('Error in Debugger handling file change: ',path,err)
        end
    end
    status, err = pcall(self.dFileChanged.dispatch,self.dFileChanged,path)
    if not status then
        print('Error in delegate handling file change: ',path,err)
    end
    print('onfilechange end',path)
end

-- Initialize the debugger
__debuggerHandler:initialize()

return Debugger
