local CreatePolygonStroke = {}

CreatePolygonStroke.MIN_SIZE = 5

function CreatePolygonStroke.new(frame, u, v, polyIndex)
    local self = {}
    setmetatable(self, { __index = CreatePolygonStroke })
    self.frame = frame
    self.tGeometry = GeoEdit.rGeo:getGeometry(frame)
    self.startU, self.startV = u, v
    local points = self:_createPoints(u, v)
    
    -- If we weren't provided a polygon index, create a new one
    if not polyIndex then
        self.tPolygon = { tExteriorPoints = points }
        table.insert(self.tGeometry.tPolygons, self.tPolygon)
        self.polyIndex = #self.tGeometry.tPolygons
        self.negativeIndex = 0
        
    -- Otherwise, create a new polygon in the interior of the old one
    else
        self.tPolygon = self.tGeometry.tPolygons[polyIndex]
        self.polyIndex = polyIndex
        if not self.tPolygon.tNegativePolygons then
            self.tPolygon.tNegativePolygons = { points }
        else
            table.insert(self.tPolygon.tNegativePolygons, points)
        end
        self.negativeIndex = #self.tPolygon.tNegativePolygons
    end
    
    GeoEdit:rebuild()
    return self
end

function CreatePolygonStroke:update(x, y, dx, dy)
    local px, py, pz, vx, vy, vz = GeoEdit.rLayer:wndToWorld(x, y)
    local u, v = GeoEdit:rayToUV(px, py, pz, vx, vy, vz)
    local points = self:_createPoints(u, v)
    if self.negativeIndex == 0 then
        self.tPolygon.tExteriorPoints = points
    else
        self.tPolygon.tNegativePolygons[self.negativeIndex] = points
    end
    
    self:_updateValid()
    GeoEdit:rebuild()
end

function CreatePolygonStroke:complete(x, y)
    local bValid = self:_updateValid()

    local tPolygons = self.tGeometry.tPolygons
    
    -- First remove the changes we made to the polygon list
    local tPoints
    if self.negativeIndex == 0 then
        tPoints = self.tPolygon.tExteriorPoints
        table.remove(tPolygons, self.polyIndex)
    else
        tPoints = self.tPolygon.tNegativePolygons[self.negativeIndex]
        table.remove(self.tPolygon.tNegativePolygons, self.negativeIndex)
        if self.negativeIndex == 1 then
            self.tPolygon.tNegativePolygons = nil
        end
    end
    
    -- Then, if they were valid, request the same changes through the editor
    if bValid then
        if self.negativeIndex == 0 then
            GeoEdit:requestInsertField(tPolygons, self.polyIndex, self.tPolygon)
        else
            if self.negativeIndex == 1 then
                GeoEdit:requestModifyField(tPolygons[self.polyIndex], 'tNegativePolygons', { tPoints })
            else
                GeoEdit:requestInsertField(tPolygons[self.polyIndex].tNegativePolygons, self.negativeIndex, tPoints)
            end
        end
    else
        GeoEdit:rebuild()
    end
end

function CreatePolygonStroke:_updateValid()
    local tPoints
    if self.negativeIndex == 0 then
        tPoints = self.tPolygon.tExteriorPoints
    else
        tPoints = self.tPolygon.tNegativePolygons[self.negativeIndex]
    end
    
    local bValid = true
    for i = 1, #tPoints do
        local index = { self.frame, self.polyIndex, self.negativeIndex, i }
        local bPointValid = true
        if not GeoEdit.rGeo:isPointValid(index) then
            bPointValid = false
        end
        if not GeoEdit.rGeo:isSegmentValid(index) then
            bPointValid = false
        end
        GeoEdit:setErrorPoint(index, not bPointValid)
        if not bPointValid then
            bValid = false
        end
    end
    return bValid
end

function CreatePolygonStroke:_createPoints(u, v)
    if u == self.startU and v == self.startV then
        v = self.startV + CreatePolygonStroke.MIN_SIZE
    end
    local du, dv = u - self.startU, v - self.startV
    
    local halfLength = math.max(math.abs(du), math.abs(dv))
    return {
        { self.startU - halfLength, self.startV + halfLength },
        { self.startU + halfLength, self.startV + halfLength },
        { self.startU + halfLength, self.startV - halfLength },
        { self.startU - halfLength, self.startV - halfLength },
    }
end

return CreatePolygonStroke