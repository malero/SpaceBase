local Task=require('Utility.Task')
local Patrol=require('Utility.Tasks.Patrol')
local World=require('World')
local Character=require('CharacterConstants')
local Class=require('Class')
local Room=require('Room')
local MiscUtil=require('MiscUtil')
local DFMath=require('DFCommon.Math')
local ObjectList=require('ObjectList')
local GameRules=require('GameRules')

local Sabotage = Class.create(Patrol)

Sabotage.ANGER_REDUCTION = 10
-- lerped based on object condition.
Sabotage.MAX_CONDITION_DAMAGE = 50
Sabotage.MIN_CONDITION_DAMAGE = 25

-- Extends patrol to pick an adjacent room, go to it, and break something.

function Sabotage:init(rChar, tPromisedNeeds, rActivityOption)
    Patrol.init(self, rChar, tPromisedNeeds, rActivityOption)
    self:_startWalk()
end

function Sabotage:_startSabotage()
    if self.rTargetObject then 
        self.bSmash = math.random() > .5 or not self.rTargetObject:hasPower()
        if self:attemptInteractWithObject('sabotage_fists', self.rTargetObject, 3) then
            return true
        end
    end
end

function Sabotage:_setUpMoveToRoom()
    local bSuccess = Patrol._setUpMoveToRoom(self)
    if not bSuccess then
        if self.rChar:getRoom() then 
            bSuccess = self:_attemptPathToRoom(self.rChar:getRoom())
        end
    end
    return bSuccess
end

function Sabotage:_attemptPathToRoom(rRoom)
    local bSuccess = false
    for i=1,5 do
        self.rTargetObject = MiscUtil.randomKey(rRoom.tProps)
        if self.rTargetObject then
            bSuccess = self:createPathTo(self.rTargetObject)
        end
        if bSuccess then break end
    end
    return bSuccess or Patrol._attemptPathToRoom(self, rRoom)
end

function Sabotage:_sortRooms(tCandidates)
    local rCharRoom = self.rChar:getRoom()
    if rCharRoom:getTeam() == self.rChar:getTeam() then
        table.insert(tCandidates, self.rChar:getRoom())
    end

    for _,t in ipairs(tCandidates) do
        t.nScore = math.random()
    end
    table.sort(tCandidates, function(a,b) return a.nScore < b.nScore end)
end

function Sabotage:onUpdate(dt)
    if not self.rChar:hasUtilityStatus(Character.STATUS_RAMPAGE_NONVIOLENT) then
        return true
    end

    if self:interacting() then
        if self:tickInteraction(dt) then
            -- We successfully sabotaged a thing. 
            if self.bSmash then
                g_World.playExplosion(self.rTargetObject:getLoc())
                self.rTargetObject:damageCondition(DFMath.lerp(self.MIN_CONDITION_DAMAGE,self.MAX_CONDITION_DAMAGE,.01*self.rTargetObject.nCondition))
            else
                self.rTargetObject:sabotagePowerLoss()
            end

            local tag = ObjectList.getTag(self.rChar)
            local tx,ty,tw = self.rChar:getTileLoc()
            Room.sendAlert(tx,ty,tw,7,function(rWitness)
                rWitness:storeMemory(Character.MEMORY_SAW_TANTRUM_RECENTLY, tag, 5)
            end)
            
            if not self.rChar.tStatus.bRampageObserved then
                local rRoom = self.rChar:getRoom()
                if rRoom then
                    local tChars = rRoom:getCharactersInRoom()
                    for rChar,_ in pairs(tChars) do
                        if rChar ~= self.rChar and rChar:getTeam() == Character.TEAM_ID_PLAYER then
                            self.rChar.tStatus.bRampageObserved = true
                        end
                    end
                end
            end
            return true
        end
    elseif self:tickWalk(dt) then
        if not self:_startSabotage() then
            -- we failed to sabotage a thing. No big deal.
            self:interrupt('failed to path to or find sabotage object')
            return
        end
    end
end

function Sabotage:onComplete(bSuccess)
    Task.onComplete(self, bSuccess)
    if bSuccess then
        self.rChar:angerReduction(self.ANGER_REDUCTION)
    end
end

return Sabotage
