local DFMath = require("DFCommon.Math")
local Room = require("Room")
local MiscUtil = require("MiscUtil")

local PathUtil = {}

function PathUtil.findNearbyProp(tx,ty,tw, nMaxDist, callback)
    local rRoom = Room.getRoomAtTile(tx,ty,tw)
    if not rRoom then return end
    
    local tRoomData = {rRoom,0}
    local tRooms = {tRoomData}
    local tReached = {rRoom=tRoomData}

    while #tRooms > 0 do
        local tTestRoomData = table.remove(tRooms,1)
        local rTestRoom = tTestRoomData[1]

        local nBestDist
        local rBestProp
        local tProps = rTestRoom:getProps()
        for rProp,_ in pairs(tProps) do
            local ptx,pty,ptw = rProp:getTileLoc()
            local nDist = MiscUtil.isoDist(tx,ty,ptx,pty)
            if nDist <= nMaxDist and (not nBestDist or nDist < nBestDist) then
                if callback(rProp) then
                    nBestDist = nDist
                    rBestProp = rProp
                end
            end
        end
        if rBestProp then return rBestProp end

        local tAdjoining = rTestRoom:getAccessibleByDoor()
        for rAdjoining,tAdjacencyData in pairs(tAdjoining) do
            local tDoorCoords = tAdjacencyData.tDoorCoords[1]
            if tDoorCoords then
                local nDist = MiscUtil.isoDist(tx,ty,tDoorCoords.x,tDoorCoords.y)
                if not tReached[rAdjoining] then
                    table.insert(tRooms,{rAdjoining,nDist})
                    tReached[rAdjoining] = nDist
                else
                    if nDist < tReached[rAdjoining] then
                        tReached[rAdjoining] = nDist
                    end
                end
            end
        end

        table.sort(tRooms, function(a,b) 
            return a[2] < b[2]
        end)
    end

end

return PathUtil
