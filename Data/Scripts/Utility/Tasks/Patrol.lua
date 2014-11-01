local Task=require('Utility.Task')
local World=require('World')
local Class=require('Class')
local Room=require('Room')
local DFMath=require('DFCommon.Math')
local ObjectList=require('ObjectList')
local GameRules=require('GameRules')

local Patrol = Class.create(Task)

--Patrol.emoticon = 'work'
--Patrol.DURATION = 200
Patrol.DURATION = 6
Patrol.HELMET_REQUIRED = false

function Patrol:init(rChar, tPromisedNeeds, rActivityOption)
    Task.init(self, rChar, tPromisedNeeds, rActivityOption)
    self.duration = DFMath.randomFloat(self.DURATION*.9,self.DURATION*1.1)
    self.bDestroyDoors = rActivityOption.tData.bDestroyDoors
    self.bExploreHostileTerritory = rActivityOption.tData.bAllowHostilePathing
    self.nIdles = 0
    if rActivityOption.tBlackboard.tPath then
        self.bInitialPath = true
        self:setPath(rActivityOption.tBlackboard.tPath)
    else
        self:_startIdle()
    end
end

function Patrol:_startIdle()
    self.nIdleTime = DFMath.randomFloat(.5,1.5)
    self.rChar:playAnim('breathe')
end

function Patrol:_startWalk()
    self.nIdleTime = nil
    if not self:_setUpMoveToRoom() then
        self:_startIdle()
	end
end

function Patrol:_setUpMoveToRoom()
    local rRoom, bLocked, rDoor = self:_pickDoor()
	if rRoom then
		if bLocked and not rDoor:getScriptController() and not rDoor.bValidAirlock then
			self:queueTask('Utility.Tasks.AttackEnemy', {rVictim=rDoor})
			local targetWX,targetWY=rRoom:randomLocInRoom(false,true)
			self:queueTask('Utility.Tasks.RunTo', {pathX=targetWX,pathY=targetWY,bRun=true})
            return true
		else
			local bCreatedPath = self:_attemptPathToRoom(rRoom)
            if not bCreatedPath then
                Print(TT_Error, "Unable to path to patrol room.")
                return false
            end
            return true
		end
	end
end

function Patrol:_pickDoor()
    local rRoom = self.rChar:getRoom()
    if rRoom and rRoom ~= Room.getSpaceRoom() then
        local tCandidates = {}
        for addr,coord in pairs(rRoom.tDoors) do
            local rDoor = ObjectList.getDoorAtTile(coord.x,coord.y)
            if rDoor then
                local rEastRoom,rWestRoom = rDoor:getRooms()
                local rOtherRoom = nil
                if rEastRoom and rEastRoom ~= rRoom then rOtherRoom = rEastRoom
                elseif rWestRoom and rWestRoom ~= rRoom then rOtherRoom = rWestRoom end
                if rOtherRoom then
					if self.bDestroyDoors or not rDoor:locked(self.rChar) then
                        if rOtherRoom.nTeam == self.rChar:getTeam() or self.bExploreHostileTerritory then
            			    local nRoomAge = self.rChar.tMemory.tRooms[rOtherRoom.id] or 0
						    table.insert(tCandidates, {rDoor=rDoor,rRoom=rOtherRoom,bLocked=rDoor:locked(self.rChar), nRoomAge=nRoomAge+math.random(0,1)})
                        end
					end
                end
            end
        end
        if next(tCandidates) then
            self:_sortRooms(tCandidates)
            return tCandidates[1].rRoom, tCandidates[1].bLocked, tCandidates[1].rDoor
        end
    end
end

function Patrol:_sortRooms(tCandidates)
    table.sort(tCandidates, function(a,b) return a.nRoomAge < b.nRoomAge end)
end

function Patrol:_attemptPathToRoom(rRoom)
--    local wx,wy = World._getWorldFromTile(rRoom:getCenterTile(true,true))
    local wx,wy = rRoom:randomLocInRoom(false,true)
    if wx then
        local cx,cy = self.rChar:getLoc()
        if self:createPath(cx,cy,wx,wy,false,self.bExploreHostileTerritory) then
            return true
        end
    end
end

function Patrol:onUpdate(dt)
    --[[
    self.duration = self.duration - dt
    if self.duration < 0 then
        return true
    end
    ]]--

    if self.nIdleTime then
        self.nIdleTime = self.nIdleTime - dt
        if self.nIdleTime < 0 then
            self.nIdleTime = nil
            self.nIdles = self.nIdles+1
            self:_startWalk()
            -- some patrols have no good rooms to patrol, so we just chill in place for a bit then bail.
            if self.nIdleTime and self.nIdleTime > 0 and self.nIdles > 3 then
                return true
            end
        end
    elseif self:tickWalk(dt) then
        if self.bInitialPath then
            self.bInitialPath = false
            self:_startIdle()
        else
            return true
        end
    end
end

return Patrol
