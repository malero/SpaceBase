local AxisGizmo = require('DFMoai.Tools.AxisGizmo')

local ScaleGizmo = {}
setmetatable(ScaleGizmo, { __index = AxisGizmo })

ScaleGizmo.CUBE_HALF_WIDTH = 1 / 12

function ScaleGizmo.new(rLayer, xScale, yScale, zScale)
    local self = {}
    setmetatable(self, { __index = ScaleGizmo })
    self:init(rLayer)
    
    self.tAxisScales = { xScale, yScale, zScale }
    for i, scale in ipairs(self.tAxisScales) do
        self:addAxis(i, scale)
    end
    self:_addProp(ScaleGizmo.makeCubeProp(0, 0, 0, 1, 1, 0))
    return self
end

function ScaleGizmo:addAxis(axis, scale)
    if scale == 0 then
        return
    end
    local x, y, z = ScaleGizmo.getAxisVector(axis, scale)
    local r, g, b = ScaleGizmo.getAxisVector(axis, 1)
    self:_addAxisProp(axis, ScaleGizmo.makeCubeProp(x, y, z, r, g, b))
    self:_addAxisProp(axis, ScaleGizmo.makeAxisProp(x, y, z, r, g, b))
end

function ScaleGizmo:isActive()
    return self._scalingAxis ~= nil
end

function ScaleGizmo:getDelta()
    if not self._tDelta then
        return 1, 1, 1
    end
    return unpack(self._tDelta)
end

function ScaleGizmo:beginStroke(x, y)
    self._originX, self._originY, self._originZ = self.rProp:getLoc()
    self._scalingAxis, self._startOffset = self:_getClosestAxis(x, y)
    self._bScaleAll = self._scalingAxis and (math.abs(self._startOffset) < self._gizmoScale * ScaleGizmo.CUBE_HALF_WIDTH)
end

function ScaleGizmo:updateStroke(x, y)    
    if self._scalingAxis then

        local delta
        if self._bScaleAll then
            local ox, oy = self.rLayer:worldToWnd(self._originX, self._originY, self._originZ)
            delta = (x - ox) * self._gizmoScale / ScaleGizmo.PIXEL_HEIGHT
        else
            local ux, uy, uz = ScaleGizmo.getAxisVector(self._scalingAxis, 1)
            local rx, ry, rz = self:_getAxisOffset(x, y, ux, uy, uz, self._originX, self._originY, self._originZ)
            local offset = rx * ux + ry * uy + rz * uz
            delta = self.tAxisScales[self._scalingAxis] * (offset - self._startOffset)
        end
        
        local scale = (self._gizmoScale + delta) / self._gizmoScale

        self._tDelta = { 1, 1, 1 }
        if self._bScaleAll then
            self._tDelta = { scale, scale, scale }
        else
            self._tDelta[self._scalingAxis] = scale
        end
        
        for i, rPropList in ipairs(self.tAxisProps) do
            local axisScale = self.tAxisScales[i]
            if axisScale ~= 0 and (self._bScaleAll or i == self._scalingAxis) then
                local rCubeProp, rAxisProp = unpack(rPropList)
                rCubeProp:setLoc(ScaleGizmo.getAxisVector(i, scale * axisScale))
                rAxisProp:setScl(unpack(self._tDelta))
            end
        end
    end
end

function ScaleGizmo:endStroke()
    self:_setScale(1, 1, 1)
    self._scalingAxis = nil
end

function ScaleGizmo:_setScale(x, y, z)
    local scales = { x, y, z }
    for i, scale in ipairs(scales) do
        local axisScale = self.tAxisScales[i]
        if axisScale ~= 0 then
            local rCubeProp, rAxisProp = unpack(self.tAxisProps[i])
            rCubeProp:setLoc(ScaleGizmo.getAxisVector(i, scale * axisScale))
            rAxisProp:setScl(x, y, z)
        end
    end
end

function ScaleGizmo.makeCubeProp(x, y, z, r, g, b)

    local vb = MOAIVertexBuffer.new()
    vb:setFormat(ScaleGizmo.vertexFormat)

    function writeVertex(v)
        vb:writeFloat(unpack(v))
        vb:writeFloat(0, 0)
        vb:writeColor32(r, g, b)
    end
    
    function buildFace(v0, v1, v2, v3)
        writeVertex(v0)
        writeVertex(v1)
        writeVertex(v2)
        writeVertex(v0)
        writeVertex(v2)
        writeVertex(v3)
    end
    
    --[[
         6__________7
        /|         /|
       / |        / |
      2__________3  |
      |  |       |  |
      |  4_______|__5
      | /        | /
      |/         |/
      0__________1
      
    --]]
    local v0 = { -ScaleGizmo.CUBE_HALF_WIDTH, -ScaleGizmo.CUBE_HALF_WIDTH, -ScaleGizmo.CUBE_HALF_WIDTH }
    local v1 = {  ScaleGizmo.CUBE_HALF_WIDTH, -ScaleGizmo.CUBE_HALF_WIDTH, -ScaleGizmo.CUBE_HALF_WIDTH }
    local v2 = { -ScaleGizmo.CUBE_HALF_WIDTH,  ScaleGizmo.CUBE_HALF_WIDTH, -ScaleGizmo.CUBE_HALF_WIDTH }
    local v3 = {  ScaleGizmo.CUBE_HALF_WIDTH,  ScaleGizmo.CUBE_HALF_WIDTH, -ScaleGizmo.CUBE_HALF_WIDTH }
    local v4 = { -ScaleGizmo.CUBE_HALF_WIDTH, -ScaleGizmo.CUBE_HALF_WIDTH,  ScaleGizmo.CUBE_HALF_WIDTH }
    local v5 = {  ScaleGizmo.CUBE_HALF_WIDTH, -ScaleGizmo.CUBE_HALF_WIDTH,  ScaleGizmo.CUBE_HALF_WIDTH }
    local v6 = { -ScaleGizmo.CUBE_HALF_WIDTH,  ScaleGizmo.CUBE_HALF_WIDTH,  ScaleGizmo.CUBE_HALF_WIDTH }
    local v7 = {  ScaleGizmo.CUBE_HALF_WIDTH,  ScaleGizmo.CUBE_HALF_WIDTH,  ScaleGizmo.CUBE_HALF_WIDTH }
    
    
    -- Three vertices per triangle, two triangles per face, six faces per cube
    vb:reserveVerts(3 * 2 * 6)
    buildFace(v0, v1, v3, v2)
    buildFace(v4, v5, v7, v6)
    buildFace(v0, v4, v6, v2)
    buildFace(v1, v5, v7, v3)
    buildFace(v0, v1, v5, v4)
    buildFace(v2, v3, v7, v6)
    vb:bless()
    
    local rMesh = MOAIMesh.new()
    rMesh:setTexture(ScaleGizmo.texture)    
    rMesh:setVertexBuffer(vb)
    rMesh:setPrimType(MOAIMesh.GL_TRIANGLES)
    
    local rProp = MOAIProp.new()
    rProp:setDeck(rMesh)
    rProp:setLoc(x, y, z)
    return rProp

end

return ScaleGizmo