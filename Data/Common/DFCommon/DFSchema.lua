-- Double Fine-specific schema types

local Schema = require('DFMoai.Schema')
local DFSchema = {}
setmetatable(DFSchema, { __index = Schema })

local PrototypeType = {}
local ResourceType = {}
local EntityNameType = {}
local LinecodeType = {}
local MetaDataType = {}
local SequenceCommandMetaDataType = {}
local ComponentTableType = {}

function DFSchema.prototype(default, sDescription)
    return PrototypeType.new(default, sDescription)
end

function DFSchema.dataPath(default, sSubdirectory, sExtension, sDescription)
    return Schema.relativePath(default, 'Data', sSubdirectory, sExtension, sDescription)
end

function DFSchema.resource(default, sRoot, sExtension, sDescription, bIncludeExtension, sAnnotation)
    if bIncludeExtension == nil then
        bIncludeExtension = false
    end
    return ResourceType.new(default, sRoot, sExtension, sDescription, bIncludeExtension, sAnnotation)
end

function DFSchema.linecode(default, sDescription, sAnnotation)
    return LinecodeType.new(default, sDescription, sAnnotation)
end

function DFSchema.entityName(default, sDescription, sAnnotation)
    return EntityNameType.new(default, sDescription, sAnnotation)
end

function DFSchema.metaData(value)
    return MetaDataType.new(value)
end

function DFSchema.sequenceCommandMetaData(value)
    return SequenceCommandMetaDataType.new(value)
end

function DFSchema.componentTable(tComponentSchemas, sDescription)
    return ComponentTableType.new(tComponentSchemas, sDescription)
end

----------------------------------------------------------------------
-- Prototype class
----------------------------------------------------------------------

setmetatable(PrototypeType, { __index = BasicType })

function PrototypeType.new(default, sDescription)
    local self = Schema.BasicType.new('string', default, sDescription)
    table.insert(self.tTypes, 1, 'prototype')
    return self
end

----------------------------------------------------------------------
-- Resource class
----------------------------------------------------------------------

setmetatable(ResourceType, { __index = BasicType })

function ResourceType.new(default, sRoot, sExtension, sDescription, bIncludeExtension, sAnnotation)
    local self = Schema.BasicType.new('string', default, sDescription)
    setmetatable(self, { __index = PathType })
    table.insert(self.tTypes, 1, 'resource')
    self.sRoot = sRoot
    self.sExtension = sExtension
    self.bIncludeExtension = bIncludeExtension
    self.sAnnotation = sAnnotation
    return self
end

----------------------------------------------------------------------
-- Linecode class
----------------------------------------------------------------------

setmetatable(LinecodeType, { __index = BasicType })

function LinecodeType.new(default, sDescription, sAnnotation)
    local self = Schema.BasicType.new('string', default, sDescription)
    table.insert(self.tTypes, 1, 'linecode')
    self.sAnnotation = sAnnotation
    return self
end

----------------------------------------------------------------------
-- EntityName class
----------------------------------------------------------------------

setmetatable(EntityNameType, { __index = BasicType })

function EntityNameType.new(default, sDescription, sAnnotation)
    local self = Schema.BasicType.new('string', default, sDescription)
    table.insert(self.tTypes, 1, 'entityName')
    self.sAnnotation = sAnnotation
    return self
end

----------------------------------------------------------------------
-- MetaDataType class
----------------------------------------------------------------------

setmetatable(MetaDataType, { __index = ObjectType })

function MetaDataType.new(value)
    local tFieldSchemas = {
        [1] = value,
    }
    local self = Schema.ObjectType.new(tFieldSchemas, "Meta data")
    table.insert(self.tTypes, 1, 'metaData')
    return self
end

----------------------------------------------------------------------
-- SequenceCommandMetaData class
----------------------------------------------------------------------

setmetatable(SequenceCommandMetaDataType, { __index = BasicType })

function SequenceCommandMetaDataType.new(value)
    local self = Schema.BasicType.new('string', value, "Sequence command meta data")
    table.insert(self.tTypes, 1, 'sequenceCommandmetadata')
    return self
end

----------------------------------------------------------------------
-- ComponentTableType class
----------------------------------------------------------------------

setmetatable(ComponentTableType, { __index = ObjectType })

function ComponentTableType.new(tComponentSchemas, sDescription)
    local self = Schema.ObjectType.new(tComponentSchemas, sDescription)
    table.insert(self.tTypes, 1, 'componentTable')
    return self
end

return DFSchema
