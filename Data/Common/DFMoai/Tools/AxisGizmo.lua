local BaseGizmo = require('DFMoai.Tools.BaseGizmo')
local AxisGizmo = {}
setmetatable(AxisGizmo, { __index = BaseGizmo })

AxisGizmo.CONE_HEIGHT = 1 / 3
AxisGizmo.CONE_RADIUS = 1 / 12
AxisGizmo.CONE_SLICES = 12

function AxisGizmo.new(rLayer, xScale, yScale, zScale)
    local self = {}
    setmetatable(self, { __index = AxisGizmo })
    self:init(rLayer)
    self.tAxisScales = { xScale, yScale, zScale }
    for i, scale in ipairs(self.tAxisScales) do
        self:addAxis(i, scale)
    end
    return self
end

function AxisGizmo:isActive()
    return self._movingAxis ~= nil
end

function AxisGizmo:getDelta()
    local x, y, z = self.rProp:getLoc()
    return x - self._originX, y - self._originY, z - self._originZ
end

function AxisGizmo:beginStroke(x, y)
    self._originX, self._originY, self._originZ = self.rProp:getLoc()
    self._movingAxis, self._startOffset = self:_getClosestAxis(x, y)
end

function AxisGizmo:updateStroke(x, y)    
    if self._movingAxis then
        local ux, uy, uz = AxisGizmo.getAxisVector(self._movingAxis, 1)
        local rx, ry, rz = self:_getAxisOffset(x, y, ux, uy, uz, self._originX, self._originY, self._originZ)
        
        local offset = rx * ux + ry * uy + rz * uz
        local delta = offset - self._startOffset
        self.rProp:setLoc(self._originX + delta * ux, self._originY + delta * uy, self._originZ + delta * uz)        
    end
end

function AxisGizmo:endStroke()
    self._movingAxis = nil
end

function AxisGizmo:_getClosestAxis(sx, sy)
    local closest = nil
    local closestDistSq = math.huge
    local closestOffset = 0
    for i, scale in ipairs(self.tAxisScales) do
        if scale ~= 0 then 
            local ux, uy, uz = AxisGizmo.getAxisVector(i, 1)
            local rx, ry, rz = self:_getAxisOffset(sx, sy, ux, uy, uz, self.rProp:getLoc())
                    
            -- Check to see if the axis position is along the widget handle
            local ax, ay, az = AxisGizmo.getAxisVector(i, 1 / ((1 + AxisGizmo.CONE_HEIGHT) * scale * self._gizmoScale))
            local axisPos = rx * ax + ry * ay + rz * az
            if 0 <= axisPos and axisPos <= 1 then
            
                -- Compute the radial distance to the axis
                local nux, nuy, nuz = 1 - ux, 1 - uy, 1 - uz
                local distSq = rx * rx * nux + ry * ry * nuy + rz * rz * nuz
                if distSq < closestDistSq then
                
                    -- Check to see if the radius is small enough to intersect the cone
                    local scaledRadius = AxisGizmo.CONE_RADIUS * math.abs(scale) * self._gizmoScale
                    local scaledRadiusSq = scaledRadius * scaledRadius
                    if distSq < scaledRadiusSq then
                        closest = i
                        closestDistSq = distSq
                        closestOffset = rx * ux + ry * uy + rz * uz
                    end
                    
                end
                
            end
        end
    end
    return closest, closestOffset
end

function AxisGizmo:_getAxisOffset(sx, sy, x, y, z, gx, gy, gz)
    -- Get the world position ray for the mouse position
    local cx, cy, cz, vx, vy, vz = self.rLayer:wndToWorld(sx, sy)
    
    -- Get the ray's position relative to the gizmo
    local px, py, pz = cx - gx, cy - gy, cz - gz
    
    -- Drop out the components along the axis we're measuring
    local dx, dy, dz = vx * (1 - x), vy * (1 - y), vz * (1 - z)
    
    -- Get the scalar for the ray that places it closest to the z plane
    local t = -(px * dx + py * dy + pz * dz) / (dx * dx + dy * dy + dz * dz)
    
    -- Get the point along the ray at that time
    return px + vx * t, py + vy * t, pz + vz * t
end

function AxisGizmo:addAxis(axis, scale)
    if scale == 0 then
        return
    end

    local x, y, z = 0, 0, 0
    local r, g, b = 0, 0, 0
    local rx, ry, rz = 0, 0, 0
    if axis == 1 then
        x = scale
        r = 1
        if scale < 0 then
            rz = 90
        else
            rz = -90
        end
    elseif axis == 2 then
        y = scale
        g = 1
        if scale < 0 then
            rx = 180
        end
    elseif axis == 3 then
        z = scale
        b = 1
        if scale < 0 then
            rx = -90
        else
            rx = 90
        end
    end
    self:_addAxisProp(axis, AxisGizmo.makeAxisProp(x, y, z, r, g, b))
    self:_addAxisProp(axis, AxisGizmo.makeConeProp(x, y, z, r, g, b, rx, ry, rz))
end

function AxisGizmo.makeAxisProp(x, y, z, r, g, b)
    local vb = MOAIVertexBuffer.new()
    vb:setFormat(AxisGizmo.vertexFormat)
    vb:reserveVerts(2)
    vb:writeFloat(0, 0, 0)
    vb:writeFloat(0, 0)
    vb:writeColor32(r, g, b)
    vb:writeFloat(x, y, z)
    vb:writeFloat(0, 0)
    vb:writeColor32(r, g, b)
    vb:bless()

    local rMesh = MOAIMesh.new()
    rMesh:setTexture(AxisGizmo.texture)
    rMesh:setPrimType(MOAIMesh.GL_LINES)
    rMesh:setVertexBuffer(vb)
    
    local rProp = MOAIProp.new()
    -- The default bounds have zero volume, which Moai will cull, so set an override
    rProp:setBounds(-1, -1, -1, 1, 1, 1)
    rProp:setDeck(rMesh)
    return rProp
end

function AxisGizmo.makeConeProp(x, y, z, r, g, b, rx, ry, rz)

    local vb = MOAIVertexBuffer.new()
    vb:setFormat(AxisGizmo.vertexFormat)

    function writeVertex(vx, vy, vz)
        vb:writeFloat(vx, vy, vz)
        vb:writeFloat(0, 0)
        vb:writeColor32(r, g, b)
    end
    
    function buildCone(vb, height)
        local dTheta = 2 * math.pi / AxisGizmo.CONE_SLICES
        local theta = 0
        local x0, z0 = AxisGizmo.CONE_RADIUS, 0
        for i=1, AxisGizmo.CONE_SLICES do
            local nextTheta = theta + dTheta
            local x1, z1 = AxisGizmo.CONE_RADIUS * math.cos(nextTheta), AxisGizmo.CONE_RADIUS * math.sin(nextTheta)
            writeVertex(x0, 0, z0)
            writeVertex(x1, 0, z1)
            writeVertex(0, height, 0)
            x0, z0 = x1, z1
            theta = nextTheta
        end
    end
    
    -- We build two cone manifolds, each with three verts per slice
    vb:reserveVerts(2 * 3 * AxisGizmo.CONE_SLICES)        
    buildCone(vb, 0)
    buildCone(vb, AxisGizmo.CONE_HEIGHT)
    vb:bless()
    
    local rMesh = MOAIMesh.new()
    rMesh:setTexture(AxisGizmo.texture)    
    rMesh:setVertexBuffer(vb)
    rMesh:setPrimType(MOAIMesh.GL_TRIANGLES)
    
    local rProp = MOAIProp.new()
    rProp:setDeck(rMesh)
    rProp:setLoc(x, y, z)
    rProp:setRot(rx, ry, rz)
    return rProp    

end

return AxisGizmo