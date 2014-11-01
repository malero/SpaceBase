local Class=require('Class')
local DFUtil = require("DFCommon.Util")
local EnvObject=require('EnvObjects.EnvObject')
local Gui = require('UI.Gui')

local Fridge = Class.create(EnvObject, MOAIProp.new)

function Fridge:init(sName, wx, wy, bFlipX, bFlipY, bForce, tSaveData, nTeam)
    EnvObject.init(self,sName, wx, wy, bFlipX, bFlipY, bForce, tSaveData, nTeam)
    local rData = EnvObject.getObjectData(self.sName)
    self.nCapacity = rData.nCapacity
    assert(self.nCapacity)
    self.tInventory = (tSaveData and tSaveData.tInventory) or {}
end

function Fridge:getFridgeSpace()
    local nCapacity = self.nCapacity
    for sName,tData in pairs(self.tInventory) do
        nCapacity = nCapacity-(tData.nCount or 1)
    end
    return nCapacity
end

function Fridge:hasFood()
    if self.bDestroyed or self.nCondition < 1 or not self:isFunctioning() then
        return nil
    end
    local sName = next(self.tInventory)
    return sName
end

return Fridge

