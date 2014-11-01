local Debugger = require('DFMoai.Debugger')
local Pickle = require('DFMoai.Pickle')
local Schema = require('DFMoai.Schema')

local Editor = {}

function Editor.new()
    local self = {}
    setmetatable(self, { __index = Editor })
    self:init()
    return self
end

function Editor:init()
    MOAIInputMgr.device.keyboard:setCallback(function(keyCode, bIsDown) self:onKeyEvent(keyCode, bIsDown) end)
end

function Editor:identifier()
    return __editorIdentifier
end

function Editor:modelFile()
    return __editorModelFile
end

function Editor:setData(tData, rSchema)
    self.tData = tData
    self.rSchema = rSchema
    Schema.prepareForEditing(tData)
end

function Editor:ready(globalName, tData, rSchema)    
    local tRuntimeKeys = {
        rParent = true,
        tChangeDelegates = true,
        tFieldChangeDelegates = true,
        tRecursiveChangeDelegates = true,
        tInsertDelegates = true,
        tRemoveDelegates = true,
    }
    local tLookupTable = {}
    function cloneSchemaData(data)
        if type(data) ~= 'table' then
            return data
        elseif tLookupTable[data] then
            return tLookupTable[data]
        end
        local tData = {}
        tLookupTable[data] = tData
        for key, value in pairs(data) do
            if type(value) ~= 'function' and not tRuntimeKeys[key] then
                tData[cloneSchemaData(key)] = cloneSchemaData(value)
            end
        end
        return tData
    end    
    
    local param = {
        identifier = self:identifier(),
        globalName = globalName,
    }
    if tData then
        param.tData = Pickle.dumps(tData)
    end
    if rSchema then
        param.tSchema = Pickle.dumps(cloneSchemaData(rSchema))
    end
    Debugger:sendMessage('__editorReady', param)
    if tData then
        self:setData(tData, rSchema)
    end
end

function Editor:onKeyEvent(keyCode, bIsDown)
    local rKeyboard = MOAIInputMgr.device.keyboard
    local bShift = rKeyboard:keyIsDown(MOAIKeyboardSensor.SHIFT)
    local bControl = rKeyboard:keyIsDown(MOAIKeyboardSensor.CONTROL)
    local bAlt = rKeyboard:keyIsDown(MOAIKeyboardSensor.ALT)
    local param = {
        keyCode = keyCode,
        bIsDown = bIsDown,
        bShift = bShift,
        bControl = bControl,
        bAlt = bAlt,
    }
    Debugger:sendMessage('keyEvent', param)
end

function Editor:sendMessage(name, param)
    Debugger:sendMessage(name, param)
end

function Editor:sendTransaction(fTransaction)
    Editor:sendMessage('requestTransactionBegin', {})
    fTransaction()
    Editor:sendMessage('requestTransactionEnd', {})
end

-- Requests for 2HB
function Editor:requestModifyField(tTable, field, value)
    local fullPath = tTable:path()
    table.insert(fullPath, field)
    self:sendMessage('requestModifyField', { tPath = Pickle.dumps(fullPath), data = Pickle.dumps(value) })
end

function Editor:requestInsertField(tTable, index, value)
    if value == nil then
        value = index
        index = #tTable + 1
    end
    self:sendMessage('requestInsertField', { tPath = Pickle.dumps(tTable:path()), index = index, data = Pickle.dumps(value) })
end

function Editor:requestAppendField(tTable, value)
    self:requestInsertField(tTable, #tTable + 1, value)
end

function Editor:requestRemoveField(tTable, index)
    self:sendMessage('requestRemoveField', { tPath = Pickle.dumps(tTable:path()), index = index })
end

-- Messages received from 2HB
function Editor:modifyField(tPath, value)
    self.rSchema:modifyField(self.tData, tPath, value)
end

function Editor:insertField(tPath, index, value)
    self.rSchema:insertField(self.tData, tPath, index, value)
end

function Editor:removeField(tPath, index)
    self.rSchema:removeField(self.tData, tPath, index)
end

return Editor