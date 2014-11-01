----------------------------------------------------------------
-- Copyright (c) 2012 Double Fine Productions
-- All Rights Reserved. 
----------------------------------------------------------------

local Editor = require('DFMoai.Tools.Editor')
local Pickle = require('DFMoai.Pickle')
local Geo = require('DFCommon.Geo')
local Graphics = require('DFCommon.Graphics')

local AddPointStroke = require('Tools.GeoEdit.AddPointStroke')
local CreatePolygonStroke = require('Tools.GeoEdit.CreatePolygonStroke')
local MovePointStroke = require('Tools.GeoEdit.MovePointStroke')

-- Create GeoEdit in the global namespace
GeoEdit = {}
setmetatable(GeoEdit, { __index = Editor })

GeoEdit.POINT_HANDLE_SLICES = 4
GeoEdit.MAX_POINT_DIST = 5
GeoEdit.MAX_SEGMENT_DIST = 5

GeoEdit.vertexFormat = MOAIVertexFormat.new()
GeoEdit.vertexFormat:declareCoord(1, MOAIVertexFormat.GL_FLOAT, 3)
GeoEdit.vertexFormat:declareUV(2, MOAIVertexFormat.GL_FLOAT, 2)
GeoEdit.vertexFormat:declareColor(3, MOAIVertexFormat.GL_UNSIGNED_BYTE)

local rWhiteImage = MOAIImage.new()
rWhiteImage:init(4, 4)
rWhiteImage:fillRect(0, 0, 4, 4, 1, 1, 1, 1)
GeoEdit.texture = MOAITexture.new()
GeoEdit.texture:load(rWhiteImage)

local rBlendImage = MOAIImage.new()
rBlendImage:init(4, 4)
rBlendImage:fillRect(0, 0, 4, 4, 0.3, 0.3, 0.3, 0.3)
GeoEdit.meshTexture = MOAITexture.new()
GeoEdit.meshTexture:load(rBlendImage)

function GeoEdit:init(rViewport)
    Editor.init(self)
    
    -- Load our geo
    self.rViewport = rViewport
    self.rGeo = Geo.load(self:modelFile())
    self.rGeo:triangulate()
    self:ready('GeoEdit', self.rGeo.tData, Geo.rSchema)

    -- Set up input
    self.rStroke = nil
    self.pointerX, self.pointerY = MOAIInputMgr.device.pointer:getLoc()    
    
    -- Set up our editing rendering
    self.rLayer = MOAILayer.new()
    self.rLayer:setViewport(rViewport)
    MOAISim.pushRenderPass(self.rLayer)
        
    -- Set up the camera
    self.rCamera = MOAICamera.new()
    self.rCamera:setOrtho(false)
    self.rLayer:setCamera(self.rCamera)

    -- Place the geometry in the layer
    self.rGeoDeck = nil
    self.rGeoProp = MOAIProp.new()
    self.rLayer:insertProp(self.rGeoProp)
    
    -- Set up point visualization
    self._tErrorPoints = {}
    
    -- Set up our debug prop
    self.rDebugProp = MOAIProp.new()
    self.rDebugProp:setAttrLink(MOAIProp.INHERIT_TRANSFORM, self.rGeoProp, MOAIProp.TRANSFORM_TRAIT)
    self.rLayer:insertProp(self.rDebugProp)

    self.rMeshProp = MOAIProp.new()
    self.rMeshProp:setAttrLink(MOAIProp.INHERIT_TRANSFORM, self.rGeoProp, MOAIProp.TRANSFORM_TRAIT)
    self.rLayer:insertProp(self.rMeshProp)
end

-- 2HB messages
function GeoEdit:setReference(sSpritePath)
    if self.rGeoDeck and self.rGeoDeck.path == sSpritePath then
        return
    end
    if self.rGeoDeck then
        self.rGeoProp:setDeck(nil)
        Graphics.unloadSpriteSheet(self.rGeoDeck.path)
        self.rGeoDeck = nil
    end
    if sSpritePath then
        self.rGeoDeck = Graphics.loadSpriteSheet(sSpritePath)
        self.rGeoProp:setDeck(self.rGeoDeck)
        if self.rGeoDeck then
            local rect = self.rGeoDeck.rects[1]
            self:requestModifyField(self.rGeo.tData.tDefaultGeometry, 'tRect', { rect.x0, rect.y0, rect.x1, rect.y1 })
        end
        
        -- Send a list of frame names to the tool
        local tFrameNames = {}
        for i=1, #self.rGeoDeck.rects do
            table.insert(tFrameNames, '')
        end
        for sName, index in pairs(self.rGeoDeck.names) do
            tFrameNames[index] = sName
        end
        self:sendMessage('frameNames', Pickle.dumps(tFrameNames))
    end
    -- Initialize the camera position
    self:focusCamera()
end

function GeoEdit:setFrame(frame)
    self.rGeoProp:setIndex(frame)
    self:refreshMesh(self.rMeshProp)
    self:rebuild()
    self:focusCamera()
end

function GeoEdit:customizeFrame(frame)
    local rect = self.rGeoDeck.rects[frame]
    self.rGeo:requestCustomizeFrame(self, frame, rect.x0, rect.y0, rect.x1, rect.y1)
end

function GeoEdit:triangulate()
    self.rGeo:triangulate()
    self:refreshMesh(self.rMeshProp)
    self.rGeo:sendGeneratedData(self)
end

function GeoEdit:showTriangulation(bShow)
    if not bShow then
        self.rLayer:removeProp(self.rMeshProp)
    else
        self:refreshMesh(self.rMeshProp)
        self.rLayer:insertProp(self.rMeshProp)
    end
end

function GeoEdit:setErrorPoint(pointIndex, bIsError)
    if bIsError then
        self:addErrorPoint(pointIndex)
    else
        self:removeErrorPoint(pointIndex)
    end
end

function GeoEdit:addErrorPoint(pointIndex)
    local polyIndex, negativeIndex, point = unpack(pointIndex)
    local tErrorPolys = self._tErrorPoints[polyIndex]
    if not tErrorPolys then
        tErrorPolys = {}
        self._tErrorPoints[polyIndex] = tErrorPolys
    end
    local tErrorPoly = tErrorPolys[negativeIndex]
    if not tErrorPoly then
        tErrorPoly = {}
        tErrorPolys[negativeIndex] = tErrorPoly
    end
    tErrorPoly[point] = true
end

function GeoEdit:removeErrorPoint(pointIndex)
    local polyIndex, negativeIndex, point = unpack(pointIndex)
    local tErrorPolys = self._tErrorPoints[polyIndex]
    if tErrorPolys then
        local tErrorPoly = tErrorPolys[negativeIndex]
        if tErrorPoly then
            tErrorPoly[point] = nil
        end
    end
end

function GeoEdit:isErrorPoint(pointIndex)
    local polyIndex, negativeIndex, point = unpack(pointIndex)
    local tErrorPolys = self._tErrorPoints[polyIndex]
    if tErrorPolys then
        local tErrorPoly = tErrorPolys[negativeIndex]
        if tErrorPoly then
            return tErrorPoly[point] == true
        end
    end
    return false
end

function GeoEdit:focusCamera()
    local index = self.rGeoProp:getIndex()
    local x0, y0, x1, y1
    if self.rGeoDeck then
        local rect = self.rGeoDeck.rects[index]
        x0, y0, x1, y1 = rect.x0, rect.y0, rect.x1, rect.y1
    else
        x0, y0, x1, y1 = unpack(self.rGeo.tData.tRect)
    end
    local width, height = x1 - x0, y1 - y0
    local viewportAspect = self.rViewport.sizeX / self.rViewport.sizeY
    if width / height < viewportAspect then
        width = height * viewportAspect
    end
    self.rCamera:setLoc((x0 + x1) * 0.5, (y0 + y1) * 0.5, self.rCamera:getFocalLength(width))
end

function GeoEdit:modifyField(tPath, value)
    Editor.modifyField(self, tPath, value)
    self:refreshMesh(self.rMeshProp)
    self:rebuild()
end

function GeoEdit:insertField(tPath, index, value)
    Editor.insertField(self, tPath, index, value)
    self:refreshMesh(self.rMeshProp)
    self:rebuild()
end

function GeoEdit:removeField(tPath, index)
    Editor.removeField(self, tPath, index)
    self:refreshMesh(self.rMeshProp)
    self:rebuild()
end

function GeoEdit:refreshMesh(rProp)
    local vb, ib = self.rGeo:createBuffers()
    
    local rMesh = MOAIMeshDeck.new()
    rMesh:setTexture(GeoEdit.meshTexture)
    rMesh:setPrimType(MOAIMesh.GL_TRIANGLES)
    rMesh:setVertexBuffer(vb)
    rMesh:setIndexBuffer(ib)
    rMesh:reserve(1)
    rMesh:setIndexRange(1, self.rGeo:getIndexRange(self.rGeoProp:getIndex()))
    
    -- The default bounds have zero volume, which Moai will cull, so set an override
    rProp:setBounds(self.rGeoProp:getBounds())
    rProp:setDeck(rMesh)
    rProp:setIndex(1)
end

function GeoEdit:rebuild()

    local vb = MOAIVertexBuffer.new()
    vb:setFormat(GeoEdit.vertexFormat)
    local frame = self.rGeoProp:getIndex()
    local tGeometry = self.rGeo:getGeometry(frame)
    
    -- Measure the number of vertices we'll use in our debug geometry
    local vertexCount = 0
    for polyIndex, tPolygon in ipairs(tGeometry.tPolygons) do
        vertexCount = vertexCount + 2 * #tPolygon.tExteriorPoints * (1 + 2 * GeoEdit.POINT_HANDLE_SLICES)
        if tPolygon.tNegativePolygons then
            for _, tNegativePolygon in ipairs(tPolygon.tNegativePolygons) do
                vertexCount = vertexCount + 2 * #tNegativePolygon * (1 + 2 * GeoEdit.POINT_HANDLE_SLICES)
            end
        end
    end
    vb:reserveVerts(vertexCount)
    
    local function writeVertex(vb, u, v, r, g, b, a)
        vb:writeFloat(u, v, 0)
        vb:writeFloat(0, 0)
        vb:writeColor32(r, g, b, a)
    end
        
    local function writePoint(vb, pointIndex, r, g, b, a)
        if self:isErrorPoint(pointIndex) then
            r, g, b, a = 1, 0, 0, 1
        end
        local u, v = self.rGeo:getPoint(pointIndex)
        writeVertex(vb, u, v, r, g, b, a)
    end
    
    local function writeSegment(prevIndex, index, r, g, b, a)
        writePoint(vb, prevIndex, r, g, b, a)
        writePoint(vb, index, r, g, b, a)
        if self:isErrorPoint(index) then
            r, g, b, a = 1, 0, 0, 1
        end
        local u, v = self.rGeo:getPoint(index)
        local radius = GeoEdit.MAX_POINT_DIST
        local dTheta = 2 * math.pi / GeoEdit.POINT_HANDLE_SLICES
        local du, dv = radius, 0
        for i = 1, GeoEdit.POINT_HANDLE_SLICES do
            local theta = i * dTheta
            local ru, rv = radius * math.cos(theta), radius * math.sin(theta)
            writeVertex(vb, u + du, v + dv, r, g, b, a)
            writeVertex(vb, u + ru, v + rv, r, g, b, a)
            du, dv = ru, rv
        end
    end
        
    for polyIndex, tPolygon in ipairs(tGeometry.tPolygons) do
    
        -- Add the external outline for the polygon
        local exteriorCount = #tPolygon.tExteriorPoints
        if exteriorCount ~= 0 then
            local prevIndex = { frame, polyIndex, 0, exteriorCount }
            for index, point in ipairs(tPolygon.tExteriorPoints) do
                local index = { frame, polyIndex, 0, index}
                writeSegment(prevIndex, index, 0, 1, 0, 1)
                prevIndex = index
            end
        end
        
        -- Add the negative shapes for the polygon
        if tPolygon.tNegativePolygons then            
            for negativeIndex, tNegativePolygon in ipairs(tPolygon.tNegativePolygons) do
                local negativeCount = #tNegativePolygon
                if negativeCount ~= 0 then
                    local prevIndex = { frame, polyIndex, negativeIndex, negativeCount }
                    for index, point in ipairs(tNegativePolygon) do
                        local index = { frame, polyIndex, negativeIndex, index }
                        writeSegment(prevIndex, index, 0, 0, 1, 1)
                        prevIndex = index
                    end
                end
            end
        end
        
    end
    vb:bless()
    
    -- Create the mesh object
    local rMesh = MOAIMesh.new()
    rMesh:setTexture(GeoEdit.texture)
    rMesh:setPrimType(MOAIMesh.GL_LINES)
    rMesh:setVertexBuffer(vb)
    
    -- The default bounds have zero volume, which Moai will cull, so set an override
    self.rDebugProp:setBounds(self.rGeoProp:getBounds())
    self.rDebugProp:setDeck(rMesh)
end

function GeoEdit:thread()
    while true do
        self:_tickInput()
        coroutine.yield()
    end
end

function GeoEdit:_tickInput()
    -- Update our mouse delta
    local x, y = MOAIInputMgr.device.pointer:getLoc()
    local dx, dy = x - self.pointerX, y - self.pointerY
    self.pointerX, self.pointerY = x, y

    -- Get the world-space ray for this mouse position
    local px, py, pz, vx, vy, vz = self.rLayer:wndToWorld(x, y)
    
    local frame = self.rGeoProp:getIndex()
    local mouseLeft = MOAIInputMgr.device.mouseLeft
    local keyboard = MOAIInputMgr.device.keyboard
    local bAltDown = keyboard:keyIsDown(MOAIKeyboardSensor.ALT)
    local bControlDown = keyboard:keyIsDown(MOAIKeyboardSensor.CONTROL)
    if not self.rStroke then
        if mouseLeft:down() then
        
            -- Get the local-space position of the ray in the geometry
            local u, v = self:rayToUV(px, py, pz, vx, vy, vz)

            -- Find the closest point and reject it if it's too far away
            local point, pointDistSq = self.rGeo:closestPoint(frame, u, v)
            if point and pointDistSq > GeoEdit.MAX_POINT_DIST * GeoEdit.MAX_POINT_DIST then
                point = nil
            end

            -- Find the closest segment and reject it if it's too far away
            local segment, segmentDistSq = self.rGeo:closestSegment(frame, u, v)
            if segment and segmentDistSq > GeoEdit.MAX_SEGMENT_DIST * GeoEdit.MAX_SEGMENT_DIST then
                segment = nil
            end

            if point and not bControlDown then
                if not bAltDown then
                    self.rStroke = MovePointStroke.new(point, u, v)
                else
                    -- Todo: replace with an actual RemovePointStroke that can validate that
                    -- the resulting geometry is valid
                    self.rGeo:requestRemovePoint(self, point)
                end
            elseif segment ~= nil then
                self.rStroke = AddPointStroke.new(segment, u, v)
            else
                local polyIndex = self.rGeo:findPolygon(frame, u, v)
                if not bAltDown then
                    -- Todo: enable polygon move if there's an intersection with a polygon
                    if not polyIndex then
                        self.rStroke = CreatePolygonStroke.new(frame, u, v)
                    end
                else
                    if polyIndex then
                        self.rStroke = CreatePolygonStroke.new(frame, u, v, polyIndex)
                    end
                end
            end
        end
    elseif self.rStroke then
        if dx ~= 0 or dy ~= 0 then
            self.rStroke:update(x, y, dx, dy)
        end
        if mouseLeft:up() then
            self.rStroke:complete(x, y)
            self.rStroke = false
        end
    end
end

function GeoEdit:rayToUV(px, py, pz, vx, vy, vz)
    -- Translate the ray into local space
    px, py, pz = self.rGeoProp:worldToModel(px, py, pz)
    vx, vy, vz = self.rGeoProp:worldToModel(vx, vy, vz)
    
    -- Remove the translation from the vector transformation
    local ox, oy, oz = self.rGeoProp:worldToModel()
    vx, vy, vz = vx - ox, vy - oy, vz - oz
    
    -- Project the point into our plane
    local t = -pz / vz
    return px + vx * t, py + vy * t
end

-- Setup the main window
local rGameViewport, rUiViewport = Graphics.createWindow("GeoEdit", 640, 480)
local rThread = MOAICoroutine.new()
rThread:run(function()
    GeoEdit:init(rUiViewport)
    GeoEdit:thread()
end)
