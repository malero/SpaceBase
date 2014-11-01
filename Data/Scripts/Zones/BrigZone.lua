local ObjectList=require('ObjectList')
local Class=require('Class')
local MiscUtil=require('MiscUtil')
local Zone=require('Zones.Zone')
local Room=require('Room')
local GameRules=require('GameRules')
local ObjectList=require('ObjectList')

local BrigZone = Class.create(Zone)

BrigZone.tBrigs={}

function BrigZone.reset()
    BrigZone.tBrigs = {}
end

function BrigZone.getBrigRoomForChar(rChar)
    local tag = rChar and rChar.tStatus.tAssignedToBrig
    if not tag then return end
    local rRoom = ObjectList.getObject(tag)
    if not rRoom or rRoom:getZoneName() ~= 'BRIG' then
        rChar:assignedToBrig(nil)
        return
    end
    return rRoom
end

function BrigZone:init(rRoom)
	Zone.init(self, rRoom)
    BrigZone.tBrigs[rRoom.id] = rRoom
    self.tAssignmentSlots = {}
end

function BrigZone:getAssignmentSlots()
    if not self.lastCheckTime or GameRules.elapsedTime-self.lastCheckTime > .1 then
        self.lastCheckTime=GameRules.elapsedTime
        local tag = self:getRoom() and ObjectList.getTag(self:getRoom())
        for n=#self.tAssignmentSlots-1,1,-1 do
            local rChar = ObjectList.getObject(self.tAssignmentSlots[n].char)
            if not rChar or rChar.tStatus.tAssignedToBrig ~= tag or rChar:isDead() then
                table.remove(self.tAssignmentSlots,n)
            end
        end

        if #self.tAssignmentSlots == 0 or (self.tAssignmentSlots[ #self.tAssignmentSlots ].char and ObjectList.getObject(self.tAssignmentSlots[ #self.tAssignmentSlots ].char)) then
            table.insert(self.tAssignmentSlots,{})
        end
    end
    return self.tAssignmentSlots,#self.tAssignmentSlots-1
end

function BrigZone:remove()
    local id = self:getRoom() and self:getRoom().id
    if id then BrigZone.tBrigs[id] = nil end
    Zone.remove(self)
end

function BrigZone:isCharAssigned(rChar)
    local t = ObjectList.getTag(rChar)
    for i,v in ipairs(self.tAssignmentSlots) do
        if v.char == t then
            return true
        end
    end
    return false
end

function BrigZone:charAssigned(rChar)
    if not self:isCharAssigned(rChar) then
        self:assignChar(nil,rChar)
    end
end

function BrigZone:unassignChar(rChar)
    if not rChar then return end
    local tag = ObjectList.getTag(rChar)
    local selfTag = self:getRoom() and ObjectList.getTag(self:getRoom())
    if rChar.tStatus and rChar.tStatus.tAssignedToBrig == selfTag then rChar.tStatus.tAssignedToBrig = nil end
    for n=#self.tAssignmentSlots,1,-1 do
        if self.tAssignmentSlots[n].char == tag then
            table.remove(self.tAssignmentSlots, n)
        end
    end
    self.lastCheckTime = nil
end

function BrigZone:assignChar(nSlotIdx,rChar)
    if not nSlotIdx then nSlotIdx = #self.tAssignmentSlots+1 end
    if not rChar then
        if self.tAssignmentSlots[nSlotIdx] and self.tAssignmentSlots[nSlotIdx].char then
            local rOld = ObjectList.getObject(self.tAssignmentSlots[nSlotIdx].char)
            if rOld and rOld.tStatus then rOld.tStatus.tAssignedToBrig = nil end
        end
        table.remove(self.tAssignmentSlots,nSlotIdx)
    elseif not self:isCharAssigned(rChar) then
        local prevBrig = BrigZone.getBrigRoomForChar(rChar)
        self.tAssignmentSlots[nSlotIdx] = {char=ObjectList.getTag(rChar)}
        rChar:assignedToBrig(self.rRoom,prevBrig ~= nil)
    end
    -- ensure there's always an empty slot.
    if #self.tAssignmentSlots < 1 or self.tAssignmentSlots[#self.tAssignmentSlots].char then
        table.insert(self.tAssignmentSlots,{})
    end
    self.lastCheckTime = nil
end

return BrigZone

