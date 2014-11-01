-- Helpers for loading and re-serializing pure-lua data

local s = require 'DFTools.serpent'

-- Makes a table satisfy unknown lookups by returning a "literal" value
-- Useful for loading lua code that uses values like MOAIShader.UNIFORM_VEC3
-- without having to load up MOAIShader
--
-- I've modified serpent.lua to understand "__literal" and serialize the tables
-- back out literally.
local _literal_lookup_metatable = {}
function _literal_lookup_metatable.__index(t,k)
    local name = rawget(t, '__literal')
    if name then
        name = name .. '.' .. k
    else
        name = k
    end
    local ret = { __literal = name }
    setmetatable(ret, _literal_lookup_metatable)
    t[k] = ret
    return ret
end

-- Return a function that wraps *f*.
-- The wrapper tweaks _G with the literal_lookup_metatable, calls f, then
-- restores _G.
local function _with_literal_globals(f)
    local function finish(...)
        setmetatable(_G, nil)
        return ...
    end
    local function start(...)
        setmetatable(_G, _literal_lookup_metatable)
        return finish(f(...))
    end
    return start
end

-- External API:
--
-- Just like dostring(), with the following differences:
-- * Unrecognized names are returned as "literal" instances.
--   A "literal" is a table { __literal=<name of the literal> }
-- * Should probably only be used for chunks that create and return data
--
-- See serialize_data() for the inverse operation.
--
-- PASS:
--    string    A string that returns a table, eg "return { foo=bar }"
-- RETURN:
--    The table.
--
local function deserialize_data(string)
    local chunk,err = loadstring(string, '<deserialize>')
    if not chunk then
        assert(false, err)
    end
    return chunk()
end
deserialize_data = _with_literal_globals(deserialize_data)

-- External API:
--
-- This is the opposite of deserialize_data().
--
-- PASS:
--    t         A table to serialize
--    compact   (optional) Makes output smaller and less readable
-- RETURN:
--    A string that can be compiled and executed to return the data.
--
local function serialize_data(t, compact)
    assert(type(t)=='table')
    local opts = {sortkeys=true, sparse=true, comment=false, name='_', sparse=true}
    if not compact then opts.indent = '  ' end
    return s.line(t, opts)
end

local function _test()
    local function try(input, expected)
        local actual = serialize_data(deserialize_data(input), true)
        if not expected then expected = input end
        if expected ~= actual then
            print(string.format('expect: <%s>\nactual: <%s>',tostring(expected),tostring(actual)))
            --assert(false)
        end
    end
    try("do local _ = {foo = bar}; return _; end")
    try("do local _ = {[1] = 1, [2] = 2, a = MOAIShader.VEC3}; return _; end")
    print("Tests ran OK")
end
-- _test()

return {
    deserialize_data=deserialize_data,
    serialize_data=serialize_data,
}