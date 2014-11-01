local DFThreeDee = {
    modulesToUpdate = {},
    
    cameraHFOV = 0,
    cameraHFOVrad = 0,
    cameraTanHalf = 0,
    cameraPos = { 0,0,0 },
    projectionPlaneWidth = 0,
    defaultProjectionPlaneWidth = 2048 / 400,
    
    thread = nil,
}

-- NOTE: apparently unused.
function DFThreeDee.setupCamera(hFOV)
    DFThreeDee.cameraHFOV = hFOV
    DFThreeDee.cameraHFOVrad = math.rad(hFOV)
    DFThreeDee.cameraTanHalf = math.tan(DFThreeDee.cameraHFOVrad * 0.5)
end

function DFThreeDee.setCameraPosition(posX, posY, posZ)
    DFThreeDee.cameraPos = {posX, posY, posZ}
    DFThreeDee.projectionPlaneWidth = 2 * -DFThreeDee.cameraPos[3] * DFThreeDee.cameraTanHalf
end

function DFThreeDee.addModuleToUpdate(module)
    table.insert(DFThreeDee.modulesToUpdate, module)
end

function DFThreeDee.removeAllModules()
    DFThreeDee.modulesToUpdate = {}
end

function DFThreeDee.removeModule(module)
    for idx,mod in ipairs(DFThreeDee.modulesToUpdate) do
        if mod == module then
            table.remove(DFThreeDee.modulesToUpdate,idx)
            return
        end
    end
    assert(false)
end

function DFThreeDee._updateAllEntities()
    local camPos = { DFThreeDee.cameraPos[1], DFThreeDee.cameraPos[2], DFThreeDee.cameraPos[3] }
    
    for index, module in ipairs(DFThreeDee.modulesToUpdate) do
        for id, entity in ipairs(module.allEntities) do
            local prop = entity.prop
            local relPosX = prop.curPos[1] - camPos[1]
            local relPosY = prop.curPos[2] - camPos[2]
            local relPosZ = prop.curPos[3] - camPos[3] -- Z is dist from camera
            local scalar = (-camPos[3]) / relPosZ -- -DFThreeDee.cameraPos[3] is dist of camera from proj plane
            prop:setLoc(relPosX * scalar, relPosY * scalar)
            prop:setScl(prop.curScale[1] * scalar, prop.curScale[2] * scalar)
        end
    end
end

function DFThreeDee._threadRun()
    while true do
        DFThreeDee._updateAllEntities()
        coroutine.yield()
    end
end

function DFThreeDee.init()
    DFThreeDee.thread = MOAICoroutine.new()
    DFThreeDee.thread:run(DFThreeDee._threadRun)
end

return DFThreeDee
