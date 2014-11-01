local Class=require('Class')
local DFGraphics = require('DFCommon.Graphics')
local DFMath = require('DFCommon.Math')
local Renderer=require('Renderer')
local Character=require('CharacterConstants')
local ObjectList=require('ObjectList')
local Base=require('Base')
local MiscUtil=require('MiscUtil')

local WorldObject = Class.create(nil, MOAIProp.new)

WorldObject.spriteSheetPath='Environments/Objects'
WorldObject.portraitSpriteSheetPath='UI/Portraits'

-- Little bit of duplication with EnvObject.lua. May make sense to move to the inspector UI?
WorldObject.tConditions=
{
    {nBelow=101, sSuffix='', linecode = "INSPEC051TEXT" },
    {nBelow=WorldObject.DAMAGED_CONDITION, sSuffix='_damaged', linecode = "INSPEC052TEXT" },
    {nBelow=1, sSuffix='_destroyed', linecode = "INSPEC053TEXT" },
}
WorldObject.tConditionColors=
{
	{nBelow=101, tBarColor = {0,   0.6,  0} },
	{nBelow=75, tBarColor  = {0.4, 0.5,  0} },
	{nBelow=50, tBarColor  = {0.7, 0.5,  0} },
	{nBelow=25, tBarColor  = {0.6, 0.25, 0} },
	{nBelow=1, tBarColor   = {0.7, 0,    0} },
}

function WorldObject.globalShutdown()
    local tTags = ObjectList.getTagsOfType(ObjectList.WORLDOBJECT)
    for _,objData in pairs(tTags) do
        objData.obj:remove()
    end
    WorldObject.tTickers = nil
end

function WorldObject.globalInit()
    WorldObject.tTickers = {}
end

-- tSpec:
-- required:
--  sClass
-- optional:
--  sNameLinecode
--  sDescLinecode
--  sSpriteName
--  sSpriteSheetPath
--  sPortraitSpriteName
--  sPortraitSpriteSheetPath
--  bHasConditions
function WorldObject:init(tSpec, sLayerName, wx, wy, tSaveData, nTeam)
    assert(tSpec)
    assert(sLayerName)
    self.sLayerName = sLayerName
    self.sClass = tSpec.sClass
    self.tSpec = tSpec
    assert(self.sClass)
    
    self.tag = ObjectList.addObject(ObjectList.WORLDOBJECT, self.sClass, self, tSaveData, false, false, nil, nil, false)
    self.nTeam = nTeam or Character.TEAM_ID_PLAYER

    self.sUniqueName = tSpec.sClass .. self.tag.objID
    self.sFriendlyName = (tSpec.sNameLinecode and g_LM.line(tSpec.sNameLinecode)) or 'Object'
    self.sDescription = (tSpec.sDescLinecode and g_LM.line(tSpec.sDescLinecode)) or ''

    self.rSpriteSheet = DFGraphics.loadSpriteSheet( self.tSpec.sSpriteSheetPath or self.spriteSheetPath )
    self:setDeck(self.rSpriteSheet)
    self.sSpriteName = self.tSpec.sSpriteName
    
    self.sPortrait = self.tSpec.sPortraitSpriteName or 'portrait_generic'
    self.sPortraitPath = self.tSpec.sPortraitSpriteSheetPath or self.portraitSpriteSheetPath
    
    if self.sSpriteName then
        if self.tSpec.bHasConditions then
            for i=1,#WorldObject.tConditions do
                DFGraphics.alignSprite(self.rSpriteSheet, self.sSpriteName..WorldObject.tConditions[i].sSuffix, "center", "center")
            end
        else
            DFGraphics.alignSprite(self.rSpriteSheet, self.sSpriteName, "center", "center")
        end
    end
    
    self:setLoc(wx,wy)

    self.nCondition = 100
    self:_setCondition(100)
	
    Renderer.getRenderLayer(self.sLayerName):insertProp(self)
end

function WorldObject:getEmergencyString()
end

function WorldObject:getContentsText()
    return nil
end

function WorldObject:getVaporizeCost()
    return 0
end

function WorldObject.setGhostCursor(tx,ty,objName,bFlipX)
    if WorldObject.rDebugCursor then
        WorldObject.rDebugCursor:setVisible(false)
    end

    local DBG_OBJECT_INFO = {
        BreachShip={
            sSpriteName='raider_spacebus',
            sSpriteSheetPath='Environments/Objects',
        },
    }
    local tSpec = DBG_OBJECT_INFO[objName]
    if tSpec then
        if not WorldObject.rDebugCursorSpriteSheet or WorldObject.rDebugCursorSpriteSheet.path ~= tSpec.sSpriteSheetPath then
            WorldObject.rDebugCursorSpriteSheet = DFGraphics.loadSpriteSheet(tSpec.sSpriteSheetPath)
        end
        if not WorldObject.rDebugCursor then
            WorldObject.rDebugCursor = MOAIProp.new()
            Renderer.getRenderLayer(require('Character').RENDER_LAYER):insertProp(WorldObject.rDebugCursor)
        end
        WorldObject.rDebugCursor:setDeck(WorldObject.rDebugCursorSpriteSheet)
        WorldObject.rDebugCursor:setIndex(WorldObject.rDebugCursorSpriteSheet.names[tSpec.sSpriteName])
        WorldObject.rDebugCursor:setVisible(true)
        if bFlipX then
            WorldObject.rDebugCursor:setScl(-1,1)
        end
        local wx,wy = g_World._getWorldFromTile(tx,ty)
        WorldObject.rDebugCursor:setLoc(wx,wy,10000)
    end
end

function WorldObject.clearGhostCursor()
    if WorldObject.rDebugCursor then WorldObject.rDebugCursor:setVisible(false) end
end

function WorldObject:getVelocity()
    return 0,0,0
end

function WorldObject:_setCondition(c)
    self.nCondition = c
    if self.nCondition < 1 then
        self.nCondition = 0
    end

    if not self.bHasConditions then 
        if self.sSpriteName then
            local index = self.rSpriteSheet.names[self.sSpriteName]
            if index then
                self:setIndex(index)
            end
        end
        return 
    end

    local suffix = self:_getCurConditionTextureSuffix()
    if self.sSpriteName then
        local spriteName = self.sSpriteName .. suffix
        local index = self.rSpriteSheet.names[spriteName]
        if index then
            self:setIndex(index)
        end
    end
end

function WorldObject:remove()
    if self.bDestroyed then return end
    
    WorldObject.tTickers[self] = nil
    self.bDestroyed = true
    ObjectList.removeObject(self.tag)
    self.tag=nil
    Renderer.getRenderLayer(self.sLayerName):removeProp(self)
end

function WorldObject:getTileCoords()
    return g_World._getTileFromWorld(self:getLoc())
end

-- Assume all worldobjects are elevated for now.
function WorldObject:getLoc()
    local x,y,z = self._UserData:getLoc()
    return x,y,z,2
end

function WorldObject:getSaveTable(xShift,yShift)
    local t = {}
    xShift = xShift or 0
    yShift = yShift or 0
    t.wx,t.wy = self:getLoc()
    t.wx,t.wy = t.wx+xShift,t.wy+yShift
    t.nCondition = self.nCondition
    t.tSpec = self.tSpec
    t.sLayerName = self.sLayerName
    t.nTeam = self.nTeam
    return t
end

function WorldObject:getTileLoc()
    local tx, ty = g_World._getTileFromWorld(self:getLoc())
    return tx,ty,2
end

function WorldObject:getTeam()
    return self.nTeam
end

function WorldObject.getHostileObjectsInRange(wx, wy, nRange, rAsking)
    local tObjs = {}
    nRange=nRange*nRange
    local tTags = ObjectList.getTagsOfType(ObjectList.WORLDOBJECT)
    for objID,objData in pairs(tTags) do
        local obj = objData.obj
        if not Base.isFriendly(rAsking,obj) then
            local nDist = DFMath.distance2DSquared(wx,wy, obj:getLoc())
            local nMargin = (obj.getHitRadius and obj.getHitRadius()) or 0
            nMargin = nMargin*nMargin
            if nDist < nRange + nMargin then
                table.insert(tObjs,{rEnt=obj, nDist2=nDist})
            end
        end
    end
    return tObjs
end

-- BEGIN STUB ENVOBJECT INTERFACE IMPLEMENTATION
-- for use by ObjectInspector
function WorldObject:getCustomInspectorName()
end

function WorldObject:getDescription()
    return self.sDescription
end

function WorldObject:canResearch()
    return false
end

function WorldObject:slatedForTeardown()
    return false
end

function WorldObject:canDeactivate()
    return false
end

function WorldObject:getUniqueID()
    return self.sUniqueName
end
-- END STUB ENVOBJECT INTERFACE IMPLEMENTATION

function WorldObject.staticTick(dt)
    for r,_ in pairs(WorldObject.tTickers) do
        r:onTick(dt)
    end
end

function WorldObject.fromSaveTable(t, xOff, yOff, nTeam)
    local rClass = require(t.tSpec.sClass)
    if rClass.fromSaveTable then
        return rClass.fromSaveTable(t, xOff, yOff, nTeam)
    end
    xOff = xOff or 0
    yOff = yOff or 0

    local wo = rClass.new(t.tSpec, t.sLayerName, t.wx+xOff, t.wy+yOff, t, t.nTeam)
    
    return wo
end

return WorldObject
