local Task=require('Utility.Task')
local Fire=require('Fire')
local Inventory=require('Inventory')
local Class=require('Class')
local ObjectList=require('ObjectList')
local Character=require('Character')
local MiscUtil=require('MiscUtil')
local Inventory=require('Inventory')
local InventoryData=require('InventoryData')
local CommandObject=require('Utility.CommandObject')
local DFMath = require("DFCommon.Math")
local DFUtil=require('DFCommon.Util')
local CharacterConstants=require('CharacterConstants')
local Mine = Class.create(Task)

--Mine.emoticon = 'work'
Mine.MINING_MIN_DURATION = 2
Mine.MINING_MAX_DURATION = 4
Mine.HELMET_REQUIRED = true

function Mine:init(rChar,tPromisedNeeds,rActivityOption)
    Task.init(self,rChar,tPromisedNeeds,rActivityOption)
    self.nRocksMined = 0
    self.bInside = rActivityOption.tData.bInside
    assert(rActivityOption.tBlackboard.rChar == rChar)
    self:setPath(rActivityOption.tBlackboard.tPath)
end

function Mine:_tryToMine()
    if self.rChar:getInventoryCountByTemplate(InventoryData.MINE_PICKUP_NAME) >= Inventory.getMaxStacks(InventoryData.MINE_PICKUP_NAME) then
        return false
    end

    local cwx,cwy = self.rChar:getLoc()
    local wx,wy,cmdObj = CommandObject.findMineTile(cwx,cwy,self,3)
    if wx then
        -- MTF TODO: reserve the tile.
        self.targetX,self.targetY,self.cmdObj = wx,wy,cmdObj
        self.bMining = true
        self.rChar:playAnim('mining')
        self.rChar:faceWorld(wx,wy)
        self.duration = self:getDuration(Mine.MINING_MIN_DURATION, Mine.MINING_MAX_DURATION, Character.MINER)
        return true
    end
end

-- MTF TODO: there are some other tasks, such as build, that want this functionality.
-- Need to figure out best way to share it.
function Mine:_acquireNewTarget()
    if self.rChar:getInventoryCountByTemplate(InventoryData.MINE_PICKUP_NAME) >= Inventory.getMaxStacks(InventoryData.MINE_PICKUP_NAME) then
        return false
    end

    local cx,cy = self.rChar:getLoc()
    local tSortedTiles = CommandObject.getSortedTilesInRange(cx,cy,nil,CommandObject.COMMAND_MINE,self,self.bInside)

    local tTileDest = nil
    for i,tTileData in ipairs(tSortedTiles) do
        if i > 3 then
            break
        end
        if self:createPath(cx,cy, tTileData.x,tTileData.y, true) then
            return true
        end
    end
    return false
end

function Mine:onUpdate(dt)
    if not self.bMining then
        self:_tryToMine()
    end

    if self:tickWait(dt) then
        -- nothing
    elseif self.tPath then
        self:tickWalk(dt)
    elseif self.bMining then
        self.duration = self.duration - dt
        if self.duration < 0 then
            local cmdObj,cmdCoord = CommandObject.getCommandAtWorld(self.targetX,self.targetY)
            if cmdObj and cmdObj.commandAction == CommandObject.COMMAND_MINE then
                local tx, ty = g_World._getTileFromWorld(self.targetX,self.targetY)
                local bSuccess = CommandObject.performCommandAtTile(cmdObj,tx,ty)
                if bSuccess then
                    self.nRocksMined = self.nRocksMined+1
                    self.rChar:pickUpItem(Inventory.createItem(InventoryData.MINE_PICKUP_NAME),true)
                    -- log event in character's history
                    self.rChar.tStats.tHistory.nTotalMinedObjects = 1 + (self.rChar.tStats.tHistory.nTotalMinedObjects or 0)
				end
            end
            self.bMining = false
            --if not self:_tryToMine() then
                --return true
            --end
        end
    elseif self:_acquireNewTarget() then
        -- _acquireNewTarget will set a new self.tPath if successful. if not, we fall through to interrupt, below.
    else
        if self.nRocksMined > 0 then
            local fraction = self.nRocksMined / Inventory.getMaxStacks(InventoryData.MINE_PICKUP_NAME)
            if self.tPromisedNeeds['Duty'] then
                self.tPromisedNeeds = DFUtil.deepCopy(self.tPromisedNeeds)
                self.tPromisedNeeds['Duty'] = self.tPromisedNeeds['Duty'] * fraction
            end
            return true
        else
            self:interrupt("no targets")
        end
    end
end

return Mine
