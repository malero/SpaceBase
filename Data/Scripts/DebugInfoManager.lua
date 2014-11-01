local LuaGrid = require('LuaGrid')

kDEBUG_MODE_NONE = 0
kDEBUG_MODE_CHAR = 1
kDEBUG_MODE_ROOM = 2
kDEBUG_MODE_PROP = 3
kDEBUG_MODE_LIGHT = 4
kDEBUG_MODE_LAST = kDEBUG_MODE_LIGHT

local DebugInfoManager = {}

DebugInfoManager.kDEBUG_PAGE_STATS = 0
DebugInfoManager.kDEBUG_PAGE_MORALE_NEEDS = 1
DebugInfoManager.kDEBUG_PAGE_AFFINITY = 2
DebugInfoManager.kDEBUG_PAGE_DECISION = 3
DebugInfoManager.kDEBUG_PAGE_TASK = 4
DebugInfoManager.kDEBUG_PAGE_LAST = DebugInfoManager.kDEBUG_PAGE_TASK
DebugInfoManager.kDEBUG_PAGE_FIRST = DebugInfoManager.kDEBUG_PAGE_STATS

DebugInfoManager.drawSelectedDebug = false
DebugInfoManager.nDebugMode = kDEBUG_MODE_NONE
DebugInfoManager.nDebugInfoPage = DebugInfoManager.kDEBUG_PAGE_STATS
DebugInfoManager.tDebugInfoBoxes = {}
DebugInfoManager.profilerName='DebugInfoManager'

local ObjectList = nil

function DebugInfoManager.cycleInfoPage()
    DebugInfoManager.nDebugInfoPage = DebugInfoManager.nDebugInfoPage + 1
    if DebugInfoManager.nDebugInfoPage > DebugInfoManager.kDEBUG_PAGE_LAST then
        DebugInfoManager.nDebugInfoPage = DebugInfoManager.kDEBUG_PAGE_FIRST
    end
end

function DebugInfoManager.cycleDebugMode()
    DebugInfoManager.nDebugMode = DebugInfoManager.nDebugMode + 1
    if DebugInfoManager.nDebugMode > kDEBUG_MODE_LAST then
        DebugInfoManager.nDebugMode = kDEBUG_MODE_NONE
    end
    
    DebugInfoManager.updateDebugInfoBoxes()
end

function DebugInfoManager.init()    
    ObjectList = require('ObjectList')
    DebugInfoManager.debugColorGrid = LuaGrid.new()
    DebugInfoManager.debugColorGrid:initDiamondGrid(g_World.width, g_World.height, g_World.tileWidth, g_World.tileHeight)
    DebugInfoManager.debugColorGrid:fill(0)
    
    DebugInfoManager.debugTexture = nil
end

function DebugInfoManager.updateDebugInfoBoxes()
    DebugInfoManager.showTexture(nil)
    
    -- clear the list; we're performing some major manipulation on it regardless
    for _,element in pairs(DebugInfoManager.tDebugInfoBoxes) do
        -- hide to remove props
        element:hide()
    end
    DebugInfoManager.tDebugInfoBoxes = {}
	if DebugInfoManager.nDebugMode == kDEBUG_MODE_CHAR then
        local CharacterManager = require('CharacterManager')
        local tChars = CharacterManager.getCharacters()
        for _,char in pairs(tChars) do
            local info = DebugInfoManager.createDebugInfoBox(char)
            table.insert(DebugInfoManager.tDebugInfoBoxes, info)
        end
	elseif DebugInfoManager.nDebugMode == kDEBUG_MODE_ROOM then
        local Room = require('Room')
        for _,room in pairs(Room.tRooms) do
            local info = DebugInfoManager.createDebugInfoBox(room)
            table.insert(DebugInfoManager.tDebugInfoBoxes, info)
        end
    elseif DebugInfoManager.nDebugMode == kDEBUG_MODE_PROP then
        for _,objData in pairs(ObjectList.getTagsOfType(ObjectList.ENVOBJECT)) do
            local info = DebugInfoManager.createDebugInfoBox(objData.obj)
            table.insert(DebugInfoManager.tDebugInfoBoxes, info)
        end
    elseif DebugInfoManager.nDebugMode == kDEBUG_MODE_LIGHT then
        local Lighting = require('Lighting')
        DebugInfoManager.showTexture(Lighting.LightTexture)
    end
end

function DebugInfoManager.createDebugInfoBox(rObj)
    local ObjectDebugInfo = require('UI.ObjectDebugInfo')
    local rDebugLabel = ObjectDebugInfo.new('DebugWorld', rObj)
    rDebugLabel:show(50)
    return rDebugLabel
end

function DebugInfoManager.onTick( dt )
    if not #DebugInfoManager.tDebugInfoBoxes then
        return
    end
    for _,box in pairs(DebugInfoManager.tDebugInfoBoxes) do
        box:refresh()
    end
end

function DebugInfoManager.setDebugGridColor(tx,ty,color)
    color = color or {0,0,0,0}
    DebugInfoManager.debugColorGrid:setColor(tx,ty,unpack(color))
end

function DebugInfoManager.clearDebugGrid()
    DebugInfoManager.debugColorGrid:fill(0)
end

function DebugInfoManager.setDebugGridEnabled(bEnabled)
    g_World.setAnalysisPropEnabled(bEnabled,DebugInfoManager.debugColorGrid)
end

function DebugInfoManager.showTexture(rTexture)
    DebugInfoManager.debugTexture = rTexture
end

return DebugInfoManager
