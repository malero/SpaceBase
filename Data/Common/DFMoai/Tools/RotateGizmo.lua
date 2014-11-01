local BaseGizmo = require('DFMoai.Tools.BaseGizmo')

local RotateGizmo = {}
setmetatable(RotateGizmo, { __index = BaseGizmo })

RotateGizmo.RADIAL_SLICES = 64
RotateGizmo.INTERSECT_RANGE = 1 / 12

function RotateGizmo.new(rLayer, xScale, yScale, zScale, x, y, z)
    local self = {}
    setmetatable(self, { __index = RotateGizmo })
    self.tAxisScales = { xScale, yScale, zScale }
    self:init(rLayer)
    for i, scale in ipairs(self.tAxisScales) do
        if scale ~= 0 then
            self:_addAxis(i)
        end
    end
    self.rProp:setRot(x, y, z)
    return self
end

function RotateGizmo:isActive()
    return self._rotatingAxis ~= nil
end

function RotateGizmo:getDelta()
    if not self._tDelta then
        return 0, 0, 0
    end
    return unpack(self._tDelta)
end

function RotateGizmo:beginStroke(x, y)
    self._rOrigin = MOAITransform.new()
    self._rOrigin:setLoc(self.rProp:getLoc())
    self._rOrigin:setRot(self.rProp:getRot())
    self._rOrigin:forceUpdate()
    self._rotatingAxis, self._vx, self._vy, self._vz = self:_getClosestAxis(x, y)
end

function RotateGizmo:updateStroke(x, y)    
    if self._rotatingAxis then
        local ux, uy, uz = RotateGizmo.getAxisVector(self._rotatingAxis, 1)
        local vx, vy, vz = self:_getVector(x, y, ux, uy, uz)
        
        -- Get the angle between our current vector and our starting vector
        local theta = math.acos(vx * self._vx + vy * self._vy + vz * self._vz)
        
        -- Cross the two vectors to get the sign of the rotation
        local cx = self._vy * vz - self._vz * vy
        local cy = self._vz * vx - self._vx * vz
        local cz = self._vx * vy - self._vy * vx
        local sign = cx + cy + cz
        if sign < 0 then
            theta = - theta
        end
        
        self._tDelta = { RotateGizmo.getAxisVector(self._rotatingAxis, math.deg(theta)) }
        
        local ox, oy, oz = self._rOrigin:getRot()
        self.rProp:setRot(ox + self._tDelta[1], oy + self._tDelta[2], oz + self._tDelta[3])
    end
end

function RotateGizmo:endStroke()
    self._rOrigin = nil
    self._rotatingAxis = nil
end

function RotateGizmo:_getClosestAxis(sx, sy)

    local cx, cy, cz, vx, vy, vz = self:_getLocalRay(sx, sy)

    local closestAxis = nil
    local closestOffset = nil
    local startX, startY, startZ = nil, nil, nil
    for axis, scale in ipairs(self.tAxisScales) do
        if scale ~= 0 then        
            -- Project the ray into the plane of this rotation axis
            local nx, ny, nz = RotateGizmo.getAxisVector(axis, 1)
            local x, y, z = self:_getPlanePos(nx, ny, nz, cx, cy, cz, vx, vy, vz)
            
            local dist = math.sqrt(x * x + y * y + z * z)
            local ringOffset = math.abs(1 - dist / self._gizmoScale)
            if ringOffset < RotateGizmo.INTERSECT_RANGE then
                if closestAxis == nil or ringOffset < closestOffset then
                    closestAxis = axis
                    closestOffset = ringOffset
                    startX, startY, startZ = x / dist, y / dist, z / dist
                end
            end
        end
    end
    
    return closestAxis, startX, startY, startZ
end

function RotateGizmo:_getLocalRay(sx, sy)
    -- Get the ray for this screen space position
    local cx, cy, cz, vx, vy, vz = self.rLayer:wndToWorld(sx, sy)
    
    -- Convert the coordinate to the local space of the gizmo
    cx, cy, cz = self._rOrigin:worldToModel(cx, cy, cz)    
    vx, vy, vz = self._rOrigin:worldToModel(vx, vy, vz)
    
    -- Remove the world transformation from the vector transformation to local space
    local gx, gy, gz = self._rOrigin:worldToModel()
    return cx, cy, cz, vx - gx, vy - gy, vz - gz
end

function RotateGizmo:_getPlanePos(nx, ny, nz, cx, cy, cz, vx, vy, vz)
    local t = -(nx * cx + ny * cy + nz * cz) / (nx * vx + ny * vy + nz * vz)    
    return cx + t * vx, cy + t * vy, cz + t * vz
end

function RotateGizmo:_getVector(sx, sy, nx, ny, nz)
    local cx, cy, cz, vx, vy, vz = self:_getLocalRay(sx, sy)
    local x, y, z = self:_getPlanePos(nx, ny, nz, cx, cy, cz, vx, vy, vz)
    local len = math.sqrt(x * x + y * y + z * z)
    return x / len, y / len, z / len
end

function RotateGizmo:_addAxis(axis)

    local r, g, b = RotateGizmo.getAxisVector(axis)
    
    local vb = MOAIVertexBuffer.new()
    vb:setFormat(RotateGizmo.vertexFormat)
    vb:reserveVerts(2 * RotateGizmo.RADIAL_SLICES)
    
    function writeVertex(vx, vy, vz)
        vb:writeFloat(vx, vy, vz)
        vb:writeFloat(0, 0)
        vb:writeColor32(r, g, b)
    end    
    
    local theta = 0
    local dTheta = 2 * math.pi / RotateGizmo.RADIAL_SLICES
    for i = 1, RotateGizmo.RADIAL_SLICES do
        local au, av = math.cos(theta), math.sin(theta)
        local bu, bv = math.cos(theta + dTheta), math.sin(theta + dTheta)
        if axis == 1 then
            writeVertex(0, au, av)
            writeVertex(0, bu, bv)
        elseif axis == 2 then
            writeVertex(au, 0, av)
            writeVertex(bu, 0, bv)
        elseif axis == 3 then
            writeVertex(au, av, 0)
            writeVertex(bu, bv, 0)
        end
        theta = theta + dTheta
    end
    
    local rMesh = MOAIMesh.new()
    rMesh:setTexture(RotateGizmo.texture)
    rMesh:setPrimType(MOAIMesh.GL_LINES)
    rMesh:setVertexBuffer(vb)
    
    local rProp = MOAIProp.new()
    -- The default bounds have zero volume, which Moai will cull, so set an override
    rProp:setBounds(-1, -1, -1, 1, 1, 1)
    rProp:setDeck(rMesh)
    self:_addProp(rProp)
end

return RotateGizmo