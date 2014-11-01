local MovePointStroke = {}

function MovePointStroke.new(pointIndex, u, v)
    local self = {}
    setmetatable(self, { __index = MovePointStroke })
    self._pointIndex = pointIndex
    self._startU, self._startV = u, v
    self._startPointU, self._startPointV = GeoEdit.rGeo:getPoint(pointIndex)
    return self
end

function MovePointStroke:update(x, y, dx, dy)
    GeoEdit.rGeo:setPoint(self._pointIndex, self:_getNewPoint(x, y))
    GeoEdit:setErrorPoint(self._pointIndex, not self:_isValid())
    GeoEdit:rebuild()
end

function MovePointStroke:complete(x, y)
    local u, v = self:_getNewPoint(x, y)
    GeoEdit.rGeo:setPoint(self._pointIndex, u, v)
    GeoEdit:removeErrorPoint(self._pointIndex)
    if self:_isValid() then
        GeoEdit.rGeo:requestModifyPoint(GeoEdit, self._pointIndex, u, v)
    else
        GeoEdit.rGeo:setPoint(self._pointIndex, self._startPointU, self._startPointV)
        GeoEdit:rebuild()
    end
end

function MovePointStroke:_isValid()
    return GeoEdit.rGeo:isPointValid(self._pointIndex) and GeoEdit.rGeo:isSegmentValid(GeoEdit.rGeo:neighbor(self._pointIndex, -1)) and GeoEdit.rGeo:isSegmentValid(self._pointIndex)
end

function MovePointStroke:_getNewPoint(x, y)
    local cx, cy, cz, vx, vy, vz = GeoEdit.rLayer:wndToWorld(x, y)
    local u, v = GeoEdit:rayToUV(cx, cy, cz, vx, vy, vz)
    local du, dv = u - self._startU, v - self._startV
    return self._startPointU + du, self._startPointV + dv
end

return MovePointStroke
