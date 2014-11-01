-- Based on the Lua pickling implementation by the estimable Paul Du Bois

local Pickle = {}

function pickleValue(value, tOutput)
    local t = type(value)
    if t == 'nil' then
        table.insert(tOutput, 'N')
    elseif t == 'number' then
        local asInt = math.floor(value)
        if asInt == value then
            table.insert(tOutput, string.format('I%d\n', value))
        else
            table.insert(tOutput, string.format('F%f\n', value))
        end
    elseif t == 'boolean' then
        if value then
            table.insert(tOutput, 'I01\n')
        else
            table.insert(tOutput, 'I00\n')
        end
    elseif t == 'string' then
        local quoted = string.format('%q', value)
        quoted = string.gsub(quoted, '\n', 'n')
        table.insert(tOutput, string.format('S%s\n', quoted))
    elseif t == 'table' then
        pickleTable(value, tOutput)
    
    -- Userdata or function or something we can't pickle fully
    else
        pickleValue(tostring(value), tOutput)
    end
end

function pickleTable(tValue, tOutput)
    -- If we've already processed this table, just get its memoized representation
    if tOutput[tValue] then
        table.insert(tOutput, string.format("g%d\n", tOutput[tValue]))
    else
        tOutput[tValue] = tOutput.memoIndex
        tOutput.memoIndex = tOutput.memoIndex + 1
        table.insert(tOutput, string.format("(dp%d\n", tOutput[tValue]))
        for key, value in pairs(tValue) do
            pickleValue(key, tOutput)
            pickleValue(value, tOutput)
            table.insert(tOutput, 's')
        end
    end
end

function Pickle.dumps(value)
    local tOutput = {}
    tOutput.memoIndex = 1
    pickleValue(value, tOutput)
    table.insert(tOutput, '.')
    return table.concat(tOutput)
end

return Pickle