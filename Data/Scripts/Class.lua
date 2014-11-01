----------------------------------------------------------------
-- Copyright (c) 2012 Double Fine Productions
-- All Rights Reserved. 
----------------------------------------------------------------

local Class = {}

function Class.create(superclass, baseFactory)

    -- Create a class object and a metatable to provide to instances
    local class = {}
    class.super = superclass
    class.__baseFactory = baseFactory
    local class_metatable = { __index = class }
        
    -- Create a static constructor for instances of this class
    class.new = function(...)
        local instance = {}
        if class.__baseFactory then
            -- MTF TODO: need to ditch a separate instance table, and use baseObject.
            -- baseObject is what MOAI will return to queries, so for now I have this
            -- horrible _Instance hack which needs to go away.
            local baseObject = class.__baseFactory()
            instance._UserData = baseObject
            baseObject._Instance = instance
            instance._Instance = instance
            local mt = { }
            mt.__index = function(t,k)
                if class[k] then return class[k] end
                return baseObject[k]
            end
            setmetatable(instance, mt)
        else
            setmetatable(instance, class_metatable)
        end
        instance:init(...)
        return instance
    end

    -- Set up inheritance if we were provided a superclass
    if superclass then
        setmetatable(class, { __index = superclass })
    end
    
    function class:is(targetClass)
        local testClass = class
        while testClass ~= nil do
            if testClass == targetClass then
                return true
            else
                testClass = testClass.super
            end
        end
    end

    return class
    
end

return Class
