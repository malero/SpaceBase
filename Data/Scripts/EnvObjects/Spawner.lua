local Class=require('Class')
local GameRules=require('GameRules')
local Character=require('CharacterConstants')
local EnvObject=require('EnvObjects.EnvObject')
local ObjectList=require('ObjectList')
local SpawnerData=require('EnvObjects.SpawnerData')
local CharacterManager=require('CharacterManager')

local Spawner = Class.create(EnvObject, MOAIProp.new)

function Spawner.getAllOnTeam(nTeam)
    local tLocators = {}
    local it = ObjectList.getTypeIterater(ObjectList.ENVOBJECT,false,'Spawner')
    local rLocator = it()
    while rLocator do
        if nTeam == -1 or rLocator.nTeam == nTeam then
            tLocators[rLocator:getSpawnType()] = rLocator
        end
        rLocator = it()
    end
    return tLocators
end

function Spawner:init(sName, wx, wy, bFlipX, bFlipY, bForce, tSaveData, nTeam)
    EnvObject.init(self,sName, wx,wy, bFlipX, bFlipY, bForce, tSaveData, nTeam)

    if tSaveData and tSaveData.tParams then
        self.tParams = tSaveData.tParams
    else
        self.tParams = { spawnerName='LocX' }
    end
end

function Spawner:setSpawnType(s)
    self.tParams.spawnerName = s
end

function Spawner:getSpawnType()
    return self.tParams.spawnerName
end

function Spawner:getSaveTable(xShift,yShift)
    local tData = EnvObject.getSaveTable(self,xShift,yShift)
    tData.tParams = self.tParams
    return tData
end

return Spawner
