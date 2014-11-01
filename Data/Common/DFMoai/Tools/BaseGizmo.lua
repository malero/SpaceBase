local BaseGizmo = {}

BaseGizmo.PIXEL_HEIGHT = 60

BaseGizmo.vertexFormat = MOAIVertexFormat.new()
BaseGizmo.vertexFormat:declareCoord(1, MOAIVertexFormat.GL_FLOAT, 3)
BaseGizmo.vertexFormat:declareUV(2, MOAIVertexFormat.GL_FLOAT, 2)
BaseGizmo.vertexFormat:declareColor(3, MOAIVertexFormat.GL_UNSIGNED_BYTE)

local rWhiteImage = MOAIImage.new()
rWhiteImage:init(4, 4)
rWhiteImage:fillRect(0, 0, 4, 4, 1, 1, 1, 1)
BaseGizmo.texture = MOAITexture.new()
BaseGizmo.texture:load(rWhiteImage)

function BaseGizmo:init(rLayer)
    self.rLayer = rLayer
    self.rProp = MOAIProp.new()
    self.tProps = {}
    self.tAxisProps = { {}, {}, {} }
end

function BaseGizmo:destroy()
    for _, rProp in ipairs(self.tProps) do
        self.rLayer:removeProp(rProp)
    end
end

function BaseGizmo:_addProp(rProp)
    rProp:setAttrLink(MOAIProp.INHERIT_TRANSFORM, self.rProp, MOAIProp.TRANSFORM_TRAIT)
    table.insert(self.tProps, rProp)
    self.rLayer:insertProp(rProp)
end

function BaseGizmo:_addAxisProp(axis, rProp)
    table.insert(self.tAxisProps[axis], rProp)
    self:_addProp(rProp)
end

function BaseGizmo:updateScale(rCamera, viewportWidth, viewportHeight)

    -- Get the vector from the camera's position to the gizmo
    local gx, gy, gz = self.rProp:getLoc()
    local cx, cy, cz = rCamera:getLoc()
    local vx, vy, vz = gx - cx, gy - cy, gz - cz
        
    -- Get the camera's forward vector
    local dx, dy, dz = rCamera:modelToWorld(0, 0, 1)
    dx, dy, dz = dx - cx, dy - cy, dz - cz
    
    -- Project the gizmo vector onto the camera's forward vector to get the vector
    -- to the camera-relative plane containing the gizmo
    local scalar = vx * dx + vy * dy + vz * dz
    local x, y, z = dx * scalar, dy * scalar, dz * scalar
    
    -- Get the distance to the plane containing the gizmo
    local length = math.sqrt(x * x + y * y + z * z)
    
    -- Compute the scale for the widget based on its screen-space ratio to the
    -- height of the window at that distance
    local targetRatio = BaseGizmo.PIXEL_HEIGHT / (viewportHeight * 0.5)
    local hFov = rCamera:getFieldOfView()
    local hExtent = math.tan(math.rad(hFov) * 0.5)
    local vExtent = hExtent * (viewportHeight / viewportWidth)
    local vFov = math.deg(math.atan(vExtent) * 2)
    
    -- Todo: add support for ortho cameras
    self._gizmoScale = targetRatio * length * math.tan(math.rad(vFov * 0.5))
    self.rProp:setScl(self._gizmoScale, self._gizmoScale, self._gizmoScale)
    
end

function BaseGizmo.getAxisVector(axis, scale)
    local vector = { 0, 0, 0 }
    vector[axis] = scale
    return unpack(vector)
end

return BaseGizmo