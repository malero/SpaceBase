local DFFile = require('DFCommon.File')
local Delegate = require('DFMoai.Delegate')
local Profile = require('Profile')

local EntityManager = { }

EntityManager.tComponentModules = { }
EntityManager.tEntityModules = { }

EntityManager.tEntities = { }
EntityManager.dEntityCreate = Delegate.new()

EntityManager.tFlags = {
	DebugOverrides = false,
}

----------------------
-- STATIC FUNCTIONS
----------------------
function EntityManager.createComponent(componentType)

    if g_bDisableComponentCreation then
        return nil
    end
    
	-- Is the component type already known?
	if not EntityManager.tComponentModules[componentType] then
	
		local path = "Components." .. componentType
	
		-- Cache the file as creator function
		EntityManager.tComponentModules[componentType] = require(path)

	else
		--Trace("Cache hit: " .. componentType)
	end
	
	-- Instantiate the component
	local component = nil
	
	if EntityManager.tComponentModules[componentType] then
		component = EntityManager.tComponentModules[componentType].new()
	end
	
	return component
end

function EntityManager.registerEntity( rEntity )
    table.insert( EntityManager.tEntities, rEntity )
    EntityManager.dEntityCreate:dispatch(rEntity)
end

function EntityManager.getEntityNamed( sName )
    for _,rEntity in ipairs( EntityManager.tEntities ) do
        if rEntity:getName() == sName then
            return rEntity
        end
    end
    
    return nil
end

function EntityManager.getEntityOfType( sProtoName, bExact )
    for _,rEntity in ipairs( EntityManager.tEntities ) do
        if rEntity:isOfType(sProtoName, bExact) then
            return rEntity
        end
    end
end

function EntityManager.getEntitiesOfType( sProtoName, bExact )
    local tResultEntities = {}
    for _,rEntity in ipairs( EntityManager.tEntities ) do
        if rEntity:isOfType(sProtoName, bExact) then
            table.insert(tResultEntities, rEntity)
        end
    end

    return tResultEntities
end

function EntityManager.getEntityWithComponentsOfType( sComponentType )
    for _,rEntity in ipairs( EntityManager.tEntities ) do
        local tResults = rEntity:getComponentsOfType( sComponentType )
        if #tResults > 0 then
            return rEntity, tResults
        end
    end
    
    return nil
end

function EntityManager.getEntitiesWithComponentsOfType( sComponentType )
    local tResultEntities = {}
    for _,rEntity in ipairs( EntityManager.tEntities ) do
        local tResults = rEntity:getComponentsOfType( sComponentType )
        if #tResults > 0 then
            table.insert(tResultEntities, rEntity)
        end
    end
    return tResultEntities
end

function EntityManager._destroy(rEntity, index, bRemove)

	rEntity:_onDestroy()
	
    if bRemove then
        table.remove(EntityManager.tEntities, index)
    end
end

function EntityManager.destroyAll()

    for i, rEntity in ipairs(EntityManager.tEntities) do
        EntityManager._destroy(rEntity, i, false)
    end
    
    EntityManager.tEntities = {}
end

function EntityManager.onTick(deltaTime)

	Profile.enterScope( "EntityManager.onTick" )
    
    for i, rEntity in ipairs(EntityManager.tEntities) do
	
		-- Update the entity (if necessary)
        if rEntity.onTick then
            rEntity:onTick(deltaTime)
        end
		
		-- Tick the components
		rEntity:_updateComponents(deltaTime)
    end
	
	EntityManager.processDestroyedEntities()
    
	Profile.leaveScope( "EntityManager.onTick" )
end

function EntityManager.processDestroyedEntities()
    -- Destroy any entities that are asking for it
    local index = 1
    local rEntity = EntityManager.tEntities[index]
    while rEntity do
        if rEntity.needsDestroy then
            EntityManager._destroy(rEntity, index, true)
        else
            index = index + 1
        end
        rEntity = EntityManager.tEntities[index]
    end
end

return EntityManager