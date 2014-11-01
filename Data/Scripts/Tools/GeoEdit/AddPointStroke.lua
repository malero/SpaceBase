local AddPointStroke = {}

function AddPointStroke.new(segmentIndex, u, v)
    local self = {}
    setmetatable(self, { __index = AddPointStroke })
    self._segmentIndex = segmentIndex
    self._pointIndex = GeoEdit.rGeo:insertPoint(segmentIndex, u, v)
    return self
end

function AddPointStroke:update(x, y, dx, dy)
    GeoEdit.rGeo:setPoint(self._pointIndex, self:_getNewPoint(x, y))
    GeoEdit:setErrorPoint(self._pointIndex, not self:_isValid())    
    GeoEdit:rebuild()
end

function AddPointStroke:complete(x, y)
    local u, v = self:_getNewPoint(x, y)
    GeoEdit.rGeo:setPoint(self._pointIndex, u, v)
    local bValid = self:_isValid()
    
    GeoEdit.rGeo:removePoint(self._pointIndex)
    GeoEdit:removeErrorPoint(self._pointIndex)
    if bValid then
        GeoEdit.rGeo:requestInsertPoint(GeoEdit, self._segmentIndex, u, v)
    else
        GeoEdit:rebuild()
    end
end

function AddPointStroke:_isValid()
    return GeoEdit.rGeo:isPointValid(self._pointIndex) and GeoEdit.rGeo:isSegmentValid(self._segmentIndex) and GeoEdit.rGeo:isSegmentValid(self._pointIndex)
end

function AddPointStroke:_getNewPoint(x, y)
    local cx, cy, cz, vx, vy, vz = GeoEdit.rLayer:wndToWorld(x, y)
    local u, v = GeoEdit:rayToUV(cx, cy, cz, vx, vy, vz)
    return u, v
end

return AddPointStroke
