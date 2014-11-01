local Delegate = require('DFMoai.Delegate')

local Schema = {}

Schema.BasicType = {}
Schema.ContainerType = {}
Schema.ArrayType = {}
Schema.ObjectType = {}
Schema.EnumType = {}
Schema.Vec2Type = {}
Schema.Vec3Type = {}
Schema.Vec4Type = {}
Schema.RectType = {}
Schema.PathType = {}
Schema.ColorType = {}
Schema.CurveKeyframeType = {}
Schema.CurveType = {}

-- Monkey patch next and pairs to support a __next metamethod used to hide private schema editing variables
local defaultNext = next
local mpNext = function(tTable, key)
    local mt = getmetatable(tTable)
    local nextFunc = mt and mt.__next or defaultNext
    return nextFunc(tTable, key)
end

local mpPairs = function(tTable)
    return next, tTable, nil
end

function Schema.enableMonkeyPatching()
    _G['next'] = mpNext
    _G['pairs'] = mpPairs
end

-- Basic types
function Schema.bool(default, sDescription, sGroup)
    return Schema.BasicType.new('bool', default, sDescription, sGroup)
end
function Schema.number(default, sDescription, sGroup)
    return Schema.BasicType.new('number', default, sDescription, sGroup)
end
function Schema.string(default, sDescription, sGroup)
    return Schema.BasicType.new('string', default, sDescription, sGroup)
end

-- Container types
function Schema.table(rValueSchema, sDescription, sGroup)
    return Schema.ContainerType.new(rValueSchema, sDescription, sGroup)
end
function Schema.array(tContainedType, sDescription, sGroup)
    return Schema.ArrayType.new(tContainedType, sDescription, sGroup)
end
function Schema.object(tFieldSchemas, sDescription, sGroup)
    return Schema.ObjectType.new(tFieldSchemas, sDescription, sGroup)
end
function Schema.derivedObject(rBaseObject, tFieldSchemas, sDescription, sGroup)
    for field, rFieldSchema in pairs(rBaseObject.tFieldSchemas) do
        if not tFieldSchemas[field] then
            tFieldSchemas[field] = rFieldSchema
        end
    end
    return Schema.ObjectType.new(tFieldSchemas, sDescription, sGroup)
end

-- Convenience types
function Schema.enum(default, tCandidates, sDescription, sGroup)
    return Schema.EnumType.new(default, tCandidates, sDescription, sGroup)
end

-- Math types
function Schema.vec2(default, sDescription, sGroup)
    return Schema.Vec2Type.new(default, sDescription, sGroup)
end
function Schema.vec3(default, sDescription, sGroup)
    return Schema.Vec3Type.new(default, sDescription, sGroup)
end
function Schema.vec4(default, sDescription, sGroup)
    return Schema.Vec4Type.new(default, sDescription, sGroup)
end
function Schema.rect(default, sDescription, sGroup)
    return Schema.RectType.new(default, sDescription, sGroup)
end

-- Resource types
function Schema.path(default, sRoot, sExtension, sDescription, sGroup)
    return Schema.PathType.new(default, nil, sRoot, sExtension, sDescription, sGroup)
end
function Schema.relativePath(default, sRoot, sSubdir, sExtension, sDescription, sGroup)
    return Schema.PathType.new(default, sRoot, sSubdir, sExtension, sDescription, sGroup)
end

-- Graphics types
function Schema.color(default, sDescription, sGroup)
    return Schema.ColorType.new(default, sDescription, sGroup)
end

function Schema.curve(default, sDescription, sGroup)
    return Schema.CurveType.new(default, sDescription, sGroup)
end

-- Editing helpers
function Schema.prepareForEditing(tObject, tParent, parentKey)

    if type(tObject) ~= 'table' then
        return
    end

    -- Store our parenting information
    tObject.__schemaParent = tParent
    tObject.__schemaParentKey = parentKey
    
    -- Add a method for grabbing the full path to this object
    function tObject:path()
        if not tObject.__schemaParent then
            return {}
        else
            local path = tParent:path()
            table.insert(path, parentKey)
            return path
        end
    end
    
    function tObject:parentContainer()
        return tObject.__schemaParent
    end
    
    function tObject:parentKey()
        return tObject.__schemaParentKey
    end
    
    -- Enable monkey patching so that this works
    Schema.enableMonkeyPatching()

    -- Wire up a custom next function that hides our private variables
    local mt = getmetatable(tObject) or {}
    mt.__next = function(tTable, prevKey)
        local key, value = defaultNext(tTable, prevKey)
        while key == 'parentContainer' or key == 'path' or key == 'parentKey' or key == '__schemaParent' or key == '__schemaParentKey' do
            key, value = defaultNext(tTable, key)
        end
        return key, value
    end
    setmetatable(tObject, mt)
    
    -- Recursively prepare all of our child tables
    for key, value in pairs(tObject) do
        if type(value) == 'table' and value ~= tObject.__schemaParent and value ~= tObject.__schemaParentKey then
            Schema.prepareForEditing(value, tObject, key)
        end
    end
    
end


----------------------------------------------------------------------
-- Schema base class
----------------------------------------------------------------------

function Schema.new(tTypes, default, sDescription, sGroup)
    local self = {}
    setmetatable(self, { __index = Schema })
    self.tTypes = tTypes
    self.default = default
    self.sDescription = sDescription
    self.sGroup = sGroup
    return self
end

function Schema:getFieldSchema(field)
    return nil
end

function Schema:modifyField(tData, tPath, value)
    local field = table.remove(tPath, #tPath)
    local tContainer, rSchema = self:_getPath(tData, tPath)
    tContainer[field] = value
    Schema.prepareForEditing(value, tContainer, field)
    if rSchema then
        rSchema:_onSetField(tContainer, field, value)
    end
end

function Schema:insertField(tData, tPath, index, value)
    local tContainer, rSchema = self:_getPath(tData, tPath)
    -- Reindex trailing elements
    for i = index, #tContainer do
        tContainer[i].__schemaParentKey = i + 1
    end
    table.insert(tContainer, index, value)
    
    Schema.prepareForEditing(value, tContainer, index)
    if rSchema then
        rSchema:_onInsertField(tContainer, index, value)
    end
end

function Schema:removeField(tData, tPath, index)
    local tContainer, rSchema = self:_getPath(tData, tPath)
    -- Reindex trailing elements
    for i = index + 1, #tContainer do
        tContainer[i].__schemaParentKey = i - 1
    end
    local value = table.remove(tContainer, index)
    Schema.prepareForEditing(value, nil, nil)
    if rSchema then
        rSchema:_onRemoveField(tContainer, index, value)
    end
end

function Schema:_getPath(tData, tPath, pathIndex)
    if not pathIndex then
        pathIndex = 1
    end
    
    if pathIndex > #tPath then
        return tData, self
    end
    
    local field = tPath[pathIndex]
    local tChild = tData[field]
    local rFieldSchema = self:getFieldSchema(field)
    
    if pathIndex == #tPath then
        return tChild, rFieldSchema
    end
        
    -- If we have a schema for this field, use it to finish the path search
    if rFieldSchema then
        return rFieldSchema:_getPath(tChild, tPath, pathIndex + 1)
        
    -- Otherwise, just run along the remainder of the path in the data
    else
        for i = pathIndex + 1, #tPath do
            field = tPath[i]
            tChild = tChild[field]
        end
        return tChild
    end
end


----------------------------------------------------------------------
-- Basic type class
----------------------------------------------------------------------

setmetatable(Schema.BasicType, { __index = Schema })

function Schema.BasicType.new(sTypeName, default, sDescription, sGroup)
    local self = Schema.new({ sTypeName }, default, sDescription, sGroup)
    setmetatable(self, { __index = Schema.BasicType })
    return self
end


----------------------------------------------------------------------
-- Container base class
----------------------------------------------------------------------

setmetatable(Schema.ContainerType, { __index = Schema })

function Schema.ContainerType.new(rValueSchema, sDescription, sGroup)
    local self = Schema.new({ 'table' }, nil, sDescription, sGroup)
    setmetatable(self, { __index = Schema.ContainerType })
    self.rValueSchema = rValueSchema
    self.sDescription = sDescription
    self.sGroup = sGroup
    self.tChangeDelegates = {}
    self.tRecursiveChangeDelegates = {}
    self.tFieldChangeDelegates = {}
    if rValueSchema then
        rValueSchema.rParent = self
    end
    return self
end

function Schema.ContainerType:registerChangeHandler(tData, handler, firstArg, bRecursive)
    local tDelegates = self.tChangeDelegates
    if bRecursive then
        tDelegates = self.tRecursiveChangeDelegates
    end
    local delegate = tDelegates[tData]
    if not delegate then
        delegate = Delegate.new()
        tDelegates[tData] = delegate
    end
    delegate:register(handler, firstArg)
end

function Schema.ContainerType:unregisterChangeHandler(tData, handler, firstArg)
    if self.tChangeDelegates[tData] then
        self.tChangeDelegates[tData]:unregister(handler, firstArg)
        self.tChangeDelegates[tData] = nil
    end
    if self.tRecursiveChangeDelegates[tData] then
        self.tRecursiveChangeDelegates[tData]:unregister(handler, firstArg)
        self.tRecursiveChangeDelegates[tData] = nil
    end
end

function Schema.ContainerType:registerFieldChangeHandler(tData, field, handler, firstArg)
    local tFieldDelegates = self.tFieldChangeDelegates[field]
    if not tFieldDelegates then
        tFieldDelegates = {}
        self.tFieldChangeDelegates[field] = tFieldDelegates
    end
    local delegate = tFieldDelegates[tData]
    if not delegate then
        delegate = Delegate.new()
        tFieldDelegates[tData] = delegate
    end
    delegate:register(handler, firstArg)
end

function Schema.ContainerType:unregisterFieldChangeHandler(tData, field, handler, firstArg)
    local tFieldDelegates = self.tFieldChangeDelegates[field]
    local delegate = tFieldDelegates[tData]
    if delegate ~= nil then
        delegate:unregister(handler, firstArg)
        tFieldDelegates[tData] = nil
    end
end

function Schema.ContainerType:getFieldSchema(field)
    return self.rValueSchema
end

function Schema.ContainerType:_onSetField(tData, field, value)
    local tFieldDelegates = self.tFieldChangeDelegates[field]
    if tFieldDelegates then
        local fieldDelegate = tFieldDelegates[tData]
        if fieldDelegate then
            fieldDelegate:dispatch(tData, field, value)
        end
    end
    local delegate = self.tChangeDelegates[tData]
    if delegate then
        delegate:dispatch(tData, field, value)
    end
    self:_notifyAncestors(tData, field, value)
end
    
function Schema.ContainerType:_notifyAncestors(tData, field, value)
    local rAncestor = self
    local ancestorValue = value
    local ancestorKey = field
    while rAncestor ~= nil do
        local recursiveDelegate = rAncestor.tRecursiveChangeDelegates[tData]
        if recursiveDelegate then
            recursiveDelegate:dispatch(tData, ancestorKey, ancestorValue)
        end
        rAncestor = rAncestor.rParent
        ancestorValue = tData
        ancestorKey = tData:parentKey()
        tData = tData:parentContainer()
    end
end


----------------------------------------------------------------------
-- Array class
----------------------------------------------------------------------

setmetatable(Schema.ArrayType, { __index = Schema.ContainerType })

function Schema.ArrayType.new(rValueSchema, sDescription, sGroup)
    local self = Schema.ContainerType.new(rValueSchema, sDescription, sGroup)
    setmetatable(self, { __index = Schema.ArrayType })
    table.insert(self.tTypes, 1, 'array')
    self.tInsertDelegates = {}
    self.tRemoveDelegates = {}
    return self
end

function Schema.ArrayType:registerFieldInsertHandler(tData, handler, firstArg)
    local delegate = self.tInsertDelegates[tData]
    if not delegate then
        delegate = Delegate.new()
        self.tInsertDelegates[tData] = delegate
    end
    delegate:register(handler, firstArg)
end

function Schema.ArrayType:unregisterFieldInsertHandler(tData, handler, firstArg)
    local delegate = self.tInsertDelegates[tData]
    delegate:unregister(handler, firstArg)
    self.tInsertDelegates[tData] = nil
end

function Schema.ArrayType:registerFieldRemoveHandler(tData, handler, firstArg)
    local delegate = self.tRemoveDelegates[tData]
    if not delegate then
        delegate = Delegate.new()
        self.tRemoveDelegates[tData] = delegate
    end
    delegate:register(handler, firstArg)
end

function Schema.ArrayType:unregisterFieldRemoveHandler(tData, handler, firstArg)
    local delegate = self.tRemoveDelegates[tData]
    delegate:unregister(handler, firstArg)
    self.tRemoveDelegates[tData] = nil
end

function Schema.ArrayType:_onInsertField(tData, index, value)
    local delegate = self.tInsertDelegates[tData]
    if delegate then
        delegate:dispatch(tData, index, value)
    end
    if self.rParent then
        self.rParent:_notifyAncestors(tData:parentContainer(), tData:parentKey(), tData)
    end
end

function Schema.ArrayType:_onRemoveField(tData, index, value)
    local delegate = self.tRemoveDelegates[tData]
    if delegate then
        delegate:dispatch(tData, index, value)
    end
    if self.rParent then
        self.rParent:_notifyAncestors(tData:parentContainer(), tData:parentKey(), tData)
    end
end


----------------------------------------------------------------------
-- Object class
----------------------------------------------------------------------

setmetatable(Schema.ObjectType, { __index = Schema.ContainerType })

function Schema.ObjectType.new(tFieldSchemas, sDescription, sGroup)
    local self = Schema.ContainerType.new(nil, sDescription, sGroup)
    setmetatable(self, { __index = Schema.ObjectType })
    table.insert(self.tTypes, 1, 'object')
    self.tFieldSchemas = tFieldSchemas
    for _, rFieldSchema in pairs(tFieldSchemas) do
        rFieldSchema.rParent = self
    end
    return self
end

function Schema.ObjectType:getFieldSchema(field)
    return self.tFieldSchemas[field]
end


----------------------------------------------------------------------
-- Enum class
----------------------------------------------------------------------

setmetatable(Schema.EnumType, { __index = Schema.BasicType })

function Schema.EnumType.new(default, tCandidates, sDescription, sGroup)
    local self = Schema.BasicType.new('enum', default, sDescription, sGroup)
    setmetatable(self, { __index = Schema.EnumType })
    table.insert(self.tTypes, 1, 'enum')
    self.tCandidates = tCandidates
    return self
end

----------------------------------------------------------------------
-- Vec2 class
----------------------------------------------------------------------

setmetatable(Schema.Vec2Type, { __index = Schema.ObjectType })

function Schema.Vec2Type.new(default, sDescription, sGroup)
    if not default then
        default = {}
    end
    local tFieldSchemas = {
        [1] = Schema.number(default[1], 'X component'),
        [2] = Schema.number(default[2], 'Y component'),
    }
    local self = Schema.ObjectType.new(tFieldSchemas, sDescription, sGroup)
    setmetatable(self, { __index = Schema.Vec2Type })
    table.insert(self.tTypes, 1, 'vec2')
    self.tDefaultVec = default
    return self
end


----------------------------------------------------------------------
-- Vec3 class
----------------------------------------------------------------------

setmetatable(Schema.Vec3Type, { __index = Schema.ObjectType })

function Schema.Vec3Type.new(default, sDescription, sGroup)
    if not default then
        default = {}
    end
    local tFieldSchemas = {
        [1] = Schema.number(default[1], 'X component'),
        [2] = Schema.number(default[2], 'Y component'),
        [3] = Schema.number(default[3], 'Z component'),
    }
    local self = Schema.ObjectType.new(tFieldSchemas, sDescription, sGroup)
    setmetatable(self, { __index = Schema.Vec3Type })
    table.insert(self.tTypes, 1, 'vec3')
    self.tDefaultVec = default
    return self
end

----------------------------------------------------------------------
-- Vec4 class
----------------------------------------------------------------------

setmetatable(Schema.Vec4Type, { __index = Schema.ObjectType })

function Schema.Vec4Type.new(default, sDescription, sGroup)
    if not default then
        default = {}
    end
    local tFieldSchemas = {
        [1] = Schema.number(default[1], 'X component'),
        [2] = Schema.number(default[2], 'Y component'),
        [3] = Schema.number(default[3], 'Z component'),
        [4] = Schema.number(default[4], 'W component'),
    }
    local self = Schema.ObjectType.new(tFieldSchemas, sDescription, sGroup)
    setmetatable(self, { __index = Schema.Vec4Type })
    table.insert(self.tTypes, 1, 'vec4')
    self.tDefaultVec = default
    return self
end

----------------------------------------------------------------------
-- Rect class
----------------------------------------------------------------------

setmetatable(Schema.RectType, { __index = Schema.ObjectType })

function Schema.RectType.new(default, sDescription, sGroup)
    if not default then
        default = {}
    end
    local tFieldSchemas = {
        [1] = Schema.number(default[1], 'X minimum'),
        [2] = Schema.number(default[2], 'Y minimum'),
        [3] = Schema.number(default[3], 'X maximum'),
        [4] = Schema.number(default[4], 'Y maximum'),
    }
    local self = Schema.ObjectType.new(tFieldSchemas, sDescription, sGroup)
    setmetatable(self, { __index = Schema.RectType })
    table.insert(self.tTypes, 1, 'rect')
    return self
end


----------------------------------------------------------------------
-- Path class
----------------------------------------------------------------------

setmetatable(Schema.PathType, { __index = Schema.BasicType })

function Schema.PathType.new(default, sRoot, sSubdirectory, sExtension, sDescription, sGroup)
    local self = Schema.BasicType.new('string', default, sDescription, sGroup)
    setmetatable(self, { __index = Schema.PathType })
    table.insert(self.tTypes, 1, 'path')
    self.sRoot = sRoot
    self.sExtension = sExtension
    self.sSubdirectory = sSubdirectory
    return self
end


----------------------------------------------------------------------
-- Color class
----------------------------------------------------------------------

setmetatable(Schema.ColorType, { __index = Schema.ObjectType })

function Schema.ColorType.new(default, sDescription, sGroup)
    if not default then
        default = {}
    end
    local tFieldSchemas = {
        [1] = Schema.number(default[1], 'R component'),
        [2] = Schema.number(default[2], 'G component'),
        [3] = Schema.number(default[3], 'B component'),
        [4] = Schema.number(default[4], 'A component'),
    }
    local self = Schema.ObjectType.new(tFieldSchemas, sDescription, sGroup)
    setmetatable(self, { __index = Schema.ColorType })
    table.insert(self.tTypes, 1, 'color')
    return self
end

----------------------------------------------------------------------
-- Curve class
----------------------------------------------------------------------

setmetatable(Schema.CurveKeyframeType, { __index = Schema.ObjectType })

function Schema.CurveKeyframeType.new(default, sDescription, sGroup)
    if not default then
        default = {}
    end
    local tFieldSchemas = {
        [1] = Schema.number(default[1], 'Time offset'),
        [2] = Schema.number(default[2], 'Value'),
        [3] = Schema.number(default[3], 'Tangent'),
        [4] = Schema.number(default[4], 'Variance'),
    }
    local self = Schema.ObjectType.new(tFieldSchemas, sDescription, sGroup)
    setmetatable(self, { __index = Schema.CurveKeyframeType })
    table.insert(self.tTypes, 1, 'curve_keyframe')
    return self
end

setmetatable(Schema.CurveType, { __index = Schema.ArrayType })

function Schema.CurveType.new(defaultValue, sDescription, sGroup)
    if not default then
        default = {}
    end
    local rKeyframeType = Schema.CurveKeyframeType.new({ 0, defaultValue, 0, 0 })
    local self = Schema.ArrayType.new(rKeyframeType, sDescription, sGroup)
    setmetatable(self, { __index = Schema.CurveType })
    table.insert(self.tTypes, 1, 'curve')
    self.defaultValue = defaultValue
    return self
end


return Schema