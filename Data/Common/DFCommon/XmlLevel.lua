DFGraphics = require 'DFCommon.Graphics'
DFFile = require 'DFCommon.File'
DFUtil = require 'DFCommon.Util'


local DFXmlLevel = {

    --AUTHORED_PIXEL_DENSITY = 400,
    AUTHORED_WIDTH = 1536,
    AUTHORED_HEIGHT = 2048,
    -- Default to iPad 3 resolution AfterFX files
    pixelDensity = 400,
    xmlLibrary = {},
}

--[[

    Module Layout
    =============

    levelModule = {
        source = ""             -- Path of xml file
        collision = {}          -- Collision data (not filled out at the moment)
        entities = {}           -- List of entites in just this xml, not children
        subModules = {}         -- Child modules of this module
        allEntities = {}        -- Entities from this and all child modules
        offsetX = 0             -- X shift of all entities and submodules
        offsetY = 0             -- Y shift of all entities and submodules
        offsetZ = 0             -- Z shift of all entities and submodules
        transform = {}          -- Data on the positioning of the module (same as entity transform, but only position obeyed)
    }
    
    
    Entity Layout
    =============
    
    entity = {  
        bitmapName = ""         -- Name of sprite within spriteSheet
        sourceWidth =           -- Sprite origWidth
        sourceHeight =          -- Sprite origHeight
        transform =             -- Positioning and properties
    }


    Transform Layout
    ================
    
    transform = {
        position = {0,0,0}      -- In world coordinates ( xml pixel coords / DFXmlLevel.pixelDensity )
        rotation = {0,0,0}      -- Rotation in degrees, but Z is negative relative to Moai
        scale = {1,1,1}         -- Scale relative to pixel perfect size
        anchor = {0,0,0}        -- Anchor point (not supported.  Half the size means normal / center )
        opacity = 1             -- Alpha value
    }

]]--

function DFXmlLevel._getSpriteSheet(spriteSheets, bitmapName, allowFailure)
    for name,deck in pairs(spriteSheets) do
        if deck.names[bitmapName] then return deck end
    end
    Trace((allowFailure and TT_Warning) or TT_Error,"Failed to find "..bitmapName.." in sprite sheets.")
    if not allowFailure then assert(false) end
end

function DFXmlLevel.getSpriteName(name,path)
    -- PSD functionality: to allow user to use layers from psds in AfterEffects, rather than having to replace all with .png files in the AE file.
    -- Requires exporting all layers to .png files with the convention PSDName_Layer-name.
    if string.find(name, "%.psd$") then
        local psdName = DFFile.stripSuffix(DFFile.getFileName(name))
        local layerName = string.sub(DFFile.stripFileName(name),1,-2)
        local fullName = string.gsub(psdName.."_"..layerName, " ", "-")
        return fullName
    else
        return string.gsub(DFFile.stripSuffix( DFFile.getFileName(path) ), " ", "-")
    end
end

-- level loading. Yikes!
function DFXmlLevel.loadAfterFX(filePath, spriteSheets, world, layer, offsetX, offsetY, offsetZ, levelModule, bDown, fgLayer)
    levelModule.source = filePath
    levelModule.collision = {}
    levelModule.entities = {}
    levelModule.subModules = {}
    levelModule.allEntities = {} -- Includes entities from child modules
    levelModule.offsetX = offsetX
    levelModule.offsetY = offsetY
    levelModule.offsetZ = offsetZ
    if not levelModule.transform then levelModule.transform = {scale={1,1,1}} end
    if not fgLayer then fgLayer = layer end

    local parsedFile = DFXmlLevel.xmlLibrary[filePath]
    if not parsedFile then
        local buffer = MOAIDataBuffer.new()
        local fixedPath = DFFile.getLevelPath(filePath..'.xml')
        buffer:load( fixedPath )
        parsedFile = MOAIXmlParser.parseString( buffer:getString() )
        DFXmlLevel.xmlLibrary[filePath] = parsedFile
    end
    
    assert(parsedFile.children, "Failed to find or read XML file: "..filePath)
    
    local function extractTransform(properties, compWidth, compHeight, levelModule, dbgName)
        local transform = {}
        transform.position = {0,0,0}
        transform.rotation = {0,0,0}
        transform.scale = {1,1,1}
        transform.anchor = {0,0,0}
        transform.opacity = 1
        
        for propertyIndex, property in pairs(properties) do
            if property.attributes.type == "Position" then
                local value = DFUtil.split( property.children.key[1].attributes.value, ',' )
                transform.position = {}
                transform.position[1] = tonumber(value[1])/DFXmlLevel.pixelDensity
                transform.position[2] = (compHeight-tonumber(value[2]))/DFXmlLevel.pixelDensity
                transform.position[3] = tonumber(value[3])/DFXmlLevel.pixelDensity
            elseif property.attributes.type == "Rotation" then
                transform.rotation = { tonumber( property.children.key[1].attributes.value ), 0, 0 }
            elseif property.attributes.type == "X_Rotation" then
                transform.rotation[1] = transform.rotation[1] + tonumber( property.children.key[1].attributes.value )
            elseif property.attributes.type == "Y_Rotation" then
                transform.rotation[2] = transform.rotation[2] + tonumber( property.children.key[1].attributes.value )
            elseif property.attributes.type == "Z_Rotation" then
                transform.rotation[3] = transform.rotation[3] + tonumber( property.children.key[1].attributes.value )
            elseif property.attributes.type == "Scale" then
                local value = DFUtil.split( property.children.key[1].attributes.value, ',' )
                transform.scale = { tonumber(value[1])*levelModule.transform.scale[1] * 0.01, 
                                    tonumber(value[2])*levelModule.transform.scale[2] * 0.01, 
                                    tonumber(value[3])*levelModule.transform.scale[3] * 0.01 }
            elseif property.attributes.type == "Orientation" then
                local value = DFUtil.split( property.children.key[1].attributes.value, ',' )
                transform.rotation[1] = transform.rotation[1] + tonumber(value[1])
                transform.rotation[2] = transform.rotation[2] + tonumber(value[2])
                transform.rotation[3] = transform.rotation[3] + tonumber(value[3])
            elseif property.attributes.type == "Anchor_Point" then
                local value = DFUtil.split( property.children.key[1].attributes.value, ',' )
                transform.anchor = { tonumber(value[1]) / DFXmlLevel.pixelDensity, tonumber(value[2]) / DFXmlLevel.pixelDensity, tonumber(value[3]) / DFXmlLevel.pixelDensity }
            elseif property.attributes.type == "Opacity" then
                transform.opacity = tonumber( property.children.key[1].attributes.value ) / 100
            end
        end

        -- If the parent module has a scale, we need to scale this transform by that scale, after
        -- first transforming to be relative to the module's anchor point.
        if levelModule.transform.anchor and levelModule.transform.scale and transform.position then
            transform.position[1] = transform.position[1]-levelModule.transform.anchor[1]
            transform.position[2] = transform.position[2]-levelModule.transform.anchor[2]
            transform.position[3] = transform.position[3]-levelModule.transform.anchor[3]

            transform.position[1] = transform.position[1]*levelModule.transform.scale[1]
            transform.position[2] = transform.position[2]*levelModule.transform.scale[2]
            transform.position[3] = transform.position[3]*levelModule.transform.scale[3]

            transform.position[1] = transform.position[1]+levelModule.transform.anchor[1]
            transform.position[2] = transform.position[2]+levelModule.transform.anchor[2]
            transform.position[3] = transform.position[3]+levelModule.transform.anchor[3]
        end

        return transform
    end
    

    local fxComps = parsedFile.children.composition
    for fxCompIndex, fxComp in pairs(fxComps) do
        local fxLayers = fxComp.children.layer
        local compWidth = fxComp.attributes.width
        local compHeight = overrideHeight or fxComp.attributes.height

        if levelModule.width then
            Print(TT_Warning, "Multiple compositions in level",filePath)
        else
            levelModule.width = compWidth/DFXmlLevel.pixelDensity
            levelModule.height = compHeight/DFXmlLevel.pixelDensity
            
            --[[
            if bDown then
                levelModule.offsetY = levelModule.offsetY - levelModule.height
                offsetY = levelModule.offsetY 
            end
            ]]--
            
        end

        local afterEffectsSortNudge = 0
        for fxLayerIndex, fxLayer in pairs(fxLayers) do
            if fxLayer.attributes.type == "Shape" then               
                for groupIndex, group in pairs(fxLayer.children.group) do
                    if group.attributes.name == "Contents" then                                      
                        local shape = nil
                        for propertyIndex, property in pairs(group.children.property) do
                            if property.attributes.type == "Shape_1" and property.children then
                                shape = property
                                break
                            end
                        end
                        
                        if shape then
                            local contents = nil
                            for propertyIndex, property in pairs(shape.children.property) do
                                if property.attributes.type == "Contents" and property.children then                                    
                                    contents = property
                                    break
                                end
                            end

                            if contents then
                                for propertyIndex, property in pairs(contents.children.property) do
                                    if property.attributes.type == "Path_1" and property.children then
                                        levelModule.collision.keys = property.children.property[1].children.key[1].children.vertice
                                        break 
                                    end
                                end                                
                            end
                        end
                    elseif group.attributes.name == "Transform" then  
                        levelModule.collision.transform = extractTransform(group.children.property, compWidth, compHeight, levelModule,fxLayer.attributes.name)
                    end
                end
            elseif fxLayer.attributes.type == "Footage" then
                local id = tonumber(fxLayer.attributes.index)
                levelModule.entities[id] = {}
                levelModule.entities[id].sortNudge = afterEffectsSortNudge
                levelModule.entities[id].sourceWidth = fxLayer.attributes.width
                levelModule.entities[id].sourceHeight = fxLayer.attributes.height 
                levelModule.entities[id].transform = {}
                for groupIndex, group in pairs(fxLayer.children.group) do
                    if group.attributes.name == "Transform" then  
                        levelModule.entities[id].transform = extractTransform(group.children.property, compWidth, compHeight,levelModule,fxLayer.attributes.name)
                    end
                end
                for groupIndex, group in pairs(fxLayer.children.source) do
                    if group.attributes.path then
                        levelModule.entities[id].bitmapName = DFXmlLevel.getSpriteName(fxLayer.attributes.name, group.attributes.path)
                    end
                end
            elseif fxLayer.attributes.type == "Composition" then
                local subModule = {
                    source = fxLayer.attributes.source,
                }
                
                for groupIndex, group in pairs(fxLayer.children.group) do
                    if group.attributes.name == "Transform" then  
                        subModule.transform = extractTransform(group.children.property, 
                            compWidth,compHeight,
                            levelModule, fxLayer.attributes.name)

                        subModule.transform.position[1] = subModule.transform.position[1] + offsetX
                        subModule.transform.position[2] = subModule.transform.position[2] + offsetY
                        subModule.transform.position[3] = subModule.transform.position[3] + offsetZ
                        
                        subModule.offsetX = subModule.transform.position[1] - subModule.transform.anchor[1]
                        subModule.offsetY = (subModule.transform.position[2] - subModule.transform.anchor[2])
                     end
                end
                
                subModule.sortNudge = afterEffectsSortNudge
                table.insert(levelModule.subModules, subModule)
            end
            afterEffectsSortNudge = afterEffectsSortNudge + 5
        end
    end   
    
    -- Create Ground Collision
    --[[
    local groundVerts = {}
    for keyIndex, key in pairs(module.collision.keys) do
        local parts = DFUtil.split(key.attributes.pos, ',')
        groundVerts[keyIndex*2-1] = ((tonumber(parts[1]) / DFXmlLevel.pixelDensity) + module.collision.transform.position[1] - compWidth * 0.5) + offsetX
        groundVerts[keyIndex*2] = (compHeight * 0.5 - ((tonumber(parts[2]) / DFXmlLevel.pixelDensity) + module.collision.transform.position[2])) + offsetY
    end
    module.first = { groundVerts[1], groundVerts[2] }
    local nverts = table.getn(groundVerts)
    module.last = { groundVerts[nverts - 1], groundVerts[nverts] }
    module.ground = world:addBody( MOAIBox2DBody.STATIC )
    local groundFixture = module.ground:addChain( groundVerts, false )
    groundFixture:setFilter( 0x02 )
    
    table.sort(module.entities, function(n1, n2)
        return module.entities[n1].transform.position[3] > module.entities[n2].transform.position[3]
    end)
    
    local maxDistance = 0
    for id, entity in pairs(module.entities) do
        if entity.transform.position[3] > maxDistance then
            maxDistance = entity.transform.position[3]
        end
    end
    ]]--

    
    local bSuccess = true


    for id, entity in pairs(levelModule.entities) do
        local prop = MOAIProp.new()
        local deck = DFXmlLevel._getSpriteSheet(spriteSheets, entity.bitmapName, true)

        if deck then

        prop:setDeck( deck )
        local spriteIndex = deck.names[entity.bitmapName]


        local spriteRect = deck.rects[spriteIndex]
        prop:setIndex( spriteIndex )

        --DFGraphics.alignSprite(deck, entity.bitmapName, "center", "center")
        -- Switched from alignSprite to setPiv because alignSprite doesn't work with a MeshDeck.
        prop:setPiv((spriteRect.x1-spriteRect.x0)*.5,(spriteRect.y1-spriteRect.y0)*.5)

        -- Position offset based on anchor.  Usually 0.
        -- TODO: XXXX MISSING FEATURE - NON CENTERED ANCHORS
        --local ax = (entity.sourceWidth / (2 * DFXmlLevel.pixelDensity))  - entity.transform.anchor[1]
        --local ay = (entity.sourceHeight / (2 * DFXmlLevel.pixelDensity)) - entity.transform.anchor[2]
        
        local ex = entity.transform.position[1] + offsetX -- + ax
        local ey = entity.transform.position[2] + offsetY -- + ay
        local ez = entity.transform.position[3] + offsetZ -- + ay
    

        prop:setLoc( ex, ey, ez )
        -- Remember raw data in the prop so a 3d camera can tweak it later
        prop.origPos = {ex, ey, ez}
        prop.curPos = {ex, ey, ez} -- Modify this to move entity in 3d view

        --if g_pixel_density then
            --local ratio = DFXmlLevel.AUTHORED_PIXEL_DENSITY / g_pixel_density
            local ratio = DFXmlLevel.pixelDensity
            if math.abs(ratio-entity.sourceWidth / spriteRect.origWidth) > 0.1 or
                math.abs(ratio-entity.sourceHeight/spriteRect.origHeight) > 0.1 then
                Print(TT_Warning,"Mismatch between AfterEffects declared image size and actual image size. This may cause display errors. Verify that AfterEffects has reloaded the latest version of the asset.", entity.bitmapName, "AE wh:",entity.sourceWidth,entity.sourceHeight,"Sprite wh:",spriteRect.origWidth,spriteRect.origHeight)
            end
        --end

        prop.origScale = { (entity.transform.scale[1] / DFXmlLevel.pixelDensity) * (entity.sourceWidth / spriteRect.origWidth), (entity.transform.scale[2] / DFXmlLevel.pixelDensity) * (entity.sourceHeight / spriteRect.origHeight), entity.transform.scale[3] }
        prop.curScale = { prop.origScale[1], prop.origScale[2], prop.origScale[3] } -- Modify this to scale entity in 3d view
        prop:setScl( prop.origScale[1], prop.origScale[2], prop.origScale[3])
        prop:setPriority( -ez*DFXmlLevel.pixelDensity-entity.sortNudge )-- we put this in here to try and increase the precision in the z depth sorting

        -- not setting this here, because premult alpha is already the default
        --prop:setBlendMode(MOAIProp2D.GL_ONE, MOAIProp2D.GL_ONE_MINUS_SRC_ALPHA)
        
        -- mult through the alpha, so premult alpha works correctly.
        local o = entity.transform.opacity
        prop:setColor(1*o,1*o,1*o, o)

        prop:setRot( -entity.transform.rotation[3] )
        if ez > -1 then
            layer:insertProp( prop )
        else
            fgLayer:insertProp( prop )
        end
        prop.layer = layer
        prop.entity = entity
        entity.prop = prop

        else
            bSuccess = false
        end
    end


    local dir = DFFile.stripFileName(filePath)
    for index, subModule in ipairs(levelModule.subModules) do
        if not DFXmlLevel.loadAfterFX(dir..subModule.source, spriteSheets, world, layer, subModule.offsetX, subModule.offsetY, subModule.transform.position[3]-subModule.sortNudge, subModule) then bSuccess = false end
    end
    
    for id, entity in pairs(levelModule.entities) do
        table.insert(levelModule.allEntities, entity)
    end
    
    -- Don't have to recurse because submodules have already built an allEntities list
    for index, subModule in pairs(levelModule.subModules) do
        for id, entity in pairs(subModule.allEntities) do
            table.insert(levelModule.allEntities, entity)
        end
    end

    --if bDown then
        local compMaxY = -9999999
        local compMinY = 9999999

        for i,entity in ipairs(levelModule.allEntities) do
            local prop = entity.prop
            local ex, ey, ez = prop.origPos[1], prop.origPos[2], prop.origPos[3]
            local tdX, tdY = ex, ey
            local xmin,ymin,zmin,xmax,ymax,zmax = prop:getBounds()
            local xs, ys = prop.origScale[1], prop.origScale[2]

            local xpiv,ypiv = prop:getPiv()
            tdX,tdY = tdX-xpiv*xs, tdY-ypiv*ys

            xmin,ymin,xmax,ymax = xmin*xs+tdX,ymin*ys+tdY,xmax*xs+tdX,ymax*ys+tdY

            compMinY = math.min(ymin,compMinY)
            compMaxY = math.max(ymax,compMaxY)
        end
        if bDown then
            local diff = -(compMaxY-offsetY)
            for i,prop in ipairs(levelModule.allEntities) do
                local p2 = prop.prop
                p2.origPos[2] = p2.origPos[2]+diff
                p2.curPos[2] = p2.curPos[2]+diff
                p2:setLoc(p2.curPos[1],p2.curPos[2],p2.curPos[3])
            end
            compMaxY = compMaxY+diff
            compMinY = compMinY+diff
        end
        levelModule.minY = compMinY
        levelModule.maxY = compMaxY
    --end
   
    return levelModule, bSuccess
end

return DFXmlLevel
