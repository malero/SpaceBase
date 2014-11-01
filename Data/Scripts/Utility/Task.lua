local Class=require('Class')
local World=require('World')
local Pathfinder=require('Pathfinder')
local Character=require('CharacterConstants')
local Room=require('Room')
local Oxygen=require('Oxygen')
local DFMath=require('DFCommon.Math')
local Needs=require('Utility.Needs')
local ActivityOption=require('Utility.ActivityOption')
local DFUtil = require('DFCommon.Util')
local OptionData = require('Utility.OptionData')
local CharacterConstants = require('CharacterConstants')
local Malady = require('Malady')
local GameRules = require('GameRules')
local ObjectList = require('ObjectList')
local MiscUtil = require('MiscUtil')
local Profile = require('Profile')

local Task = Class.create()

--Task.INTERRUPT_PRI_LOW = 1
--Task.INTERRUPT_PRI_NORMAL = 2
--Task.INTERRUPT_PRI_HIGH = 3

Task.MAX_OBSTRUCTION_WAIT = 10
Task.EMOTICON_INITIAL_DURATION = 5

Task.DURATION_UNKNOWN_LONG = 60

function Task.fromSaveData(rChar, tData)
    local rClass = require(tData.sClass)
    if rClass.staticFromSaveData then
        return rClass.staticFromSaveData(rChar,tData)
        --[[
    else
        local tAOData = tData.tAOData or {}
        tAOData.bInfinite=true
        local rResumedAO = ActivityOption.new(tData.activityName, tAOData)

        local bSuccess, sReason = rResumedAO:fillOutBlackboard(rChar)
        if bSuccess then
            local rClass = require(tData.sClass)
            local rTask = rClass.new(rChar, {}, rResumedAO, tData)
            return rTask
        end
        ]]--
    end
end

function Task:_getGenericSaveData()
    local tData = {}
    tData.tAOData = {}
    tData.activityName = self.activityName
    tData.tPromisedNeeds = self.tPromisedNeeds
    tData.nPriority = self.nPriority
    tData.tPath = self.tPath
    tData.tTargetObject = self.rTargetObject and ObjectList.getTag(self.rTargetObject)
    tData.nPromisedUtility = self.nPromisedUtility
    return tData
end

function Task:init(rChar, tPromisedNeeds, rActivityOption,tSaveData)
    self.tPromisedNeeds = tPromisedNeeds
    self.rChar = rChar
    self.activityName = rActivityOption.name
    self.rActivityOption = rActivityOption
    self.tCommand = rActivityOption.tData.tCommand
    self.nPriority = rActivityOption:getPriority(rChar)
    --self.interruptPri = interruptPri or Task.INTERRUPT_PRI_NORMAL
    if self.HELMET_REQUIRED then
        self.rChar:showHelmet()
    end
    if g_GuiManager.getSelectedCharacter() == rChar then
        self:showEmoticon()
    end
    assert(tPromisedNeeds)
    assert(rChar)
    
    if rActivityOption.tData then
        if rActivityOption.tData.pathX then
            self.DBG_pathX,self.DBG_pathY = rActivityOption.tData.pathX, rActivityOption.tData.pathY
            self.DBG_pathTX,self.DBG_pathTY = g_World._getTileFromWorld(rActivityOption.tData.pathX, rActivityOption.tData.pathY)
        end
        if rActivityOption.tData.partnerX then
            self.DBG_partnerX,self.DBG_partnerY = rActivityOption.tData.partnerX, rActivityOption.tData.partnerY
            self.DBG_partnerTX,self.DBG_partnerTY = g_World._getTileFromWorld(rActivityOption.tData.partnerX, rActivityOption.tData.partnerY)
        end
    end
end

function Task:getTag(sTag)
    if self.rActivityOption then
        local val = self.rActivityOption:getTag(self.rChar,sTag)
        if val ~= nil then return val end
    end
    if self.rParentTask then return self.rParentTask:getTag(sTag) end
end

function Task:isChildTask()
    return self.rParentTask ~= nil
end

function Task:getPriority()
    return self.nPriority
end

function Task:getOptionData()
    return self.activityName and OptionData.tAdvertisedActivities[self.activityName]
end

function Task:showEmoticon()
    if not OptionData.tAdvertisedActivities[self.activityName] or not OptionData.tAdvertisedActivities[self.activityName].UIText then
        return
    end
    
	if self.emoticon then
        self.rChar:setEmoticon( self.emoticon, g_LM.line(OptionData.tAdvertisedActivities[self.activityName].UIText) )
    else
        self.rChar:setEmoticon( nil, g_LM.line(OptionData.tAdvertisedActivities[self.activityName].UIText) )
    end
	DFUtil.timedCallback(self.EMOTICON_INITIAL_DURATION, MOAIAction.ACTIONTYPE_GAMEPLAY, false, function() self:dismissEmoticon() end)
end

function Task:dismissEmoticon()
    --if (self.emoticon and self.rChar.sEmoticon == 'ui_dialogicon_'..self.emoticon) 
    --or (self.emoticonText and self.rChar.sEmoticonText == self.emoticonText) then
        self.rChar:setEmoticon()
    --end
end

--[[
function Task:canInterruptFor(activityName)
    return self.interruptPri < Task.INTERRUPT_PRI_NORMAL
end
]]--

function Task:_endInteraction()
            if self.rInteractionObject then
                if self.rInteractionObject.onInteract then
                    self.rInteractionObject:onInteract(false,self.rChar)
                end
                if self.bInteractingOnObject then
                    local tx,ty,tw = self.rChar:getTileLoc()
                    local tx2,ty2,tw2 = self.rInteractionObject:getTileLoc()
                    if tx == tx2 and ty == ty2 and tw == tw2 then
                        local r = self.rChar:getRoom()
                        if r then
                            tx2,ty2,tw2 = r:_getPathableNeighbor(tx,ty)
                            if tx2 then
                                self.rChar:setTileLoc(tx2,ty2,tw2)
                            end
                        end
                    end
                    if self.sInteractOnObjectAnim and self.rChar:isPlayingAnim(self.sInteractOnObjectAnim) then
                        self.sInteractOnObjectAnim = nil
                        self.rChar:playAnim('breathe')
                    end
                    self.bInteractingOnObject = false
                end
                self.rInteractionObject = nil
            end
end

function Task:_addNeedReward(nFrac)
    nFrac = nFrac or 1
    
    for k,v in pairs(self.tPromisedNeeds) do
        if k ~= 'Mods' then
            self.rChar:addNeed(k,Needs.getAdjustedPromise(self.rChar.tStats.tPersonality, v, self.rActivityOption.name, k) * nFrac)
        end
    end
    local tD = self:getOptionData()
    if tD and tD.nJobExperience then
        local test = tD.JobForXP or self:getTag('Job')
        if not test then
            self:getTag('Job')
        end
        self.rChar:addJobExperience(tD.JobForXP or self:getTag('Job'), tD.nJobExperience * nFrac)
    end
end

function Task:onComplete(bSuccess)
    self.rChar:taskCompleting(self,bSuccess,self.rParentTask ~= nil)
    self:_endInteraction()
    if bSuccess then
        self:_addNeedReward()
        if self.HELMET_REQUIRED then
            self.rChar:hideHelmet()
        end
    end
	-- log task on completion
	local tTaskData = {}
	local GameRules = require('GameRules')
	tTaskData.time = GameRules.sStarDate..':'..GameRules.getStardateMinuteString()
	tTaskData.sTaskName = self.activityName
	tTaskData.bSuccess = bSuccess
	if not bSuccess then
		tTaskData.sInterruptReason = self.sInterruptReason
	end
	self.rChar:logTask(tTaskData)
end

function Task:estimatedTimeRemaining()
    return self.duration or 10
end

function Task:_updateQueue()
	if self.rQueuedTask and self.rQueuedTask.bComplete then
        if self.rQueuedTask.sInterruptReason then
            self:interrupt('Subtask interrupt:',self.rQueuedTask.sInterruptReason)
            return
        end
		self.rQueuedTask = nil
	end

	if not self.rQueuedTask and self.tQueue then
		local tQueueEntry = self.tQueue[1]
		table.remove(self.tQueue,1)
		if not next(self.tQueue) then self.tQueue = nil end

        self.rQueuedTask = nil
        if tQueueEntry.rTask then
            self.rQueuedTask = tQueueEntry.rTask 
        else
            tQueueEntry.tData.nPriorityOverride = self.nPriority
            local rStubAO = ActivityOption.new(self.activityName.."_"..tQueueEntry.sClass, tQueueEntry.tData)
            local bSuccess, sReason = rStubAO:fillOutBlackboard(self.rChar)
            if bSuccess then
                local rClass = require(tQueueEntry.sClass)
                self.rQueuedTask = rClass.new(self.rChar, {}, rStubAO)
            else
                Print(TT_Warning, 'Not queuing',tQueueEntry.sClass,' Reason:',sReason)
            end
        end
        if self.rQueuedTask then
            self.rQueuedTask.rParentTask = self
        end
	end
end

function Task:getLeafTask()
    local rQueuedTask = self
    while rQueuedTask do
        if rQueuedTask.rQueuedTask then
            rQueuedTask = rQueuedTask.rQueuedTask
        else
            return rQueuedTask
        end
    end
end

function Task:getTag(sTag)
    return self.rActivityOption:getTag(self.rChar, sTag)
end

function Task:update(dt)
    if self.bComplete then return true end

	self:_updateQueue()
    
    if self.bComplete then return true end

	if self.rQueuedTask then
		self.rQueuedTask:update(dt)
	elseif self:onUpdate(dt) then
        self:complete()
        return true
    end
end

-- For early unreserves. In the standard case, you can just complete or interrupt the 
-- task and the unreserve will be handled for you.
function Task:unreserve()
    self.rActivityOption:unreserve(self.rChar)
    self.bEarlyUnreserve = true
end

function Task:interrupt(sReason)
    assertdev(not self.bComplete)
    if self.bComplete then return end

    self:dismissEmoticon()
    self.bComplete = true
    self.sInterruptReason = sReason or 'none'

    if not self.bInitialized then
        -- early interrupt
    elseif not self.bEarlyUnreserve then
        self.rActivityOption:unreserve(self.rChar)
    end

    self:onComplete(false)
    if self.tCommand then
        -- SAFETY TEST:
        -- whether or not we complete a command, let's refresh to catch weird cases where a
        -- command can be made invalid by circumstances we don't currently test for.
        -- If we can test for all of them in CommandObject's delegate listeners
        -- (specifically: prop buffers getting encroached)
        -- then we can remove this test.
        self.tCommand:retestCommandValidity()
    end
end

function Task:complete()
    if self.bComplete then
        Print(TT_Error, 'Task already complete: '..tostring(self.activityName))
        -- nuking this assert for now. Character:angerEvent can interrupt a task, and having to test for that
        -- every time before returning true is too cumbersome to be reasonable.
        -- Leaving the error trace though for debugging. For now.
        --assertdev(not self.bComplete)
        return
    end
    -- reset emoticon if it's still hanging round
    self:dismissEmoticon()
    self.rChar:setElevatedSpacewalk(false)
    self.bComplete = true
    if not self.bEarlyUnreserve then
        self.rActivityOption:unreserve(self.rChar)
    end
    self:onComplete(true)
    if self.tCommand then
        -- SAFETY TEST:
        -- see Task:interrupt
        self.tCommand:retestCommandValidity()
    end
end

function Task:chainTaskRef(rTask)
    self:complete()
    self.rChar:forceTask(rTask)
end

function Task:queueTask(sTaskName,tData)
	if not self.tQueue then self.tQueue={} end
    tData.bInfinite = true -- don't allow reservations on subtasks
	table.insert(self.tQueue, {sClass=sTaskName,tData=tData})
end

function Task:queueTaskRef(sTaskName,rTask)
	if not self.tQueue then self.tQueue={} end
	table.insert(self.tQueue, {sClass=sTaskName,rTask=rTask})
end

function Task:optionRemoved()
    --if not self.bUninterruptible then
        self:interrupt("Option removed.")
    --end
end

function Task:obstructionWait(dt)
    if not self.nObstructionTime then
        self.nObstructionTime=0
    else
        self.nObstructionTime = self.nObstructionTime + dt
    end
    if self.nObstructionTime < Task.MAX_OBSTRUCTION_WAIT then
        return false
    end
    self.nObstructionTime = nil
    return true
end

function Task:requireSpacesuit()
    if OptionData.tAdvertisedActivities[self.activityName] then 
        local tPrereqs = OptionData.tAdvertisedActivities[self.activityName].Prerequisites
        return tPrereqs and tPrereqs['WearingSuit']
    end
    return false
end

function Task:attemptInteractOnObject(sAnim, rObj, nDuration)
    local bSuccess,sReason = self:attemptInteractWithObject(sAnim, rObj, nDuration, false)
    if bSuccess then
        self.bInteractingOnObject = true
        self.sInteractOnObjectAnim = sAnim
	    local xOff,yOff,dir
	    if rObj.bFlipX then
		    xOff = rObj.tData.tAnimOffsetFlipped.x
		    yOff = rObj.tData.tAnimOffsetFlipped.y
		    dir = rObj.tData.animDirFlipped or 'SE'
	    else
		    xOff = rObj.tData.tAnimOffset.x
		    yOff = rObj.tData.tAnimOffset.y
		    dir = rObj.tData.animDir or 'SW'
	    end
	    self.rChar:setDirection(dir)
	    local x,y = rObj:getLoc()
	    x = x + xOff
	    y = y + yOff
	    local z = g_World.getHackySortingZ(x, y) + 100
	    -- bForce arg tells us to ignore collision with objects
	    self.rChar:setLoc(x, y, z, true)
        return true
    else
        return bSuccess, sReason
    end
end

function Task:attemptInteractWithObject(sAnim, rObj, nDuration, bPlayOnce)
    if rObj and not rObj.bDestroyed then
        if rObj.rUser and rObj.rUser ~= self.rChar then
            return false, 'object busy'
        end
        local ctx,cty,ctw = g_World._getTileFromWorld(self.rChar:getLoc())
        
        local testFn=function(tx,ty,tw)
            if ctw == tw then
                if self:attemptInteractWithTile(sAnim,tx,ty,nDuration, bPlayOnce) then
                    self.rInteractionObject = rObj
                    Malady.interactedWith(self.rChar,rObj)
                    if self.rInteractionObject.onInteract then
                        self.rInteractionObject:onInteract(true,self.rChar)
                    end
                    return true
                end
            end
        end
        
        if rObj.getFootprint then
            local tTiles = rObj:getFootprint()
            for _,addr in ipairs(tTiles) do
                local tx,ty = g_World.pathGrid:cellAddrToCoord(addr)
                if testFn(tx,ty,1) then 
                    return true 
                end
            end
        else
            local tx,ty,tw = rObj:getTileLoc()
            return testFn(tx,ty,tw)
        end
    end
end

function Task:attemptInteractWithTile(sAnim, tx, ty, nDuration, bPlayOnce)
    local ctx,cty = g_World._getTileFromWorld(self.rChar:getLoc())
    self:_endInteraction()
    if World._areTilesAdjacent(ctx,cty,tx,ty,true,true) then
        self.nInteracting = nDuration
        if sAnim then self.rChar:playAnim(sAnim, bPlayOnce) end
        self.rChar:faceTile(tx,ty)
        return true
    end
end

function Task:interacting()
    return self.nInteracting
end


function Task:tickInteraction(dt)
    if self.nInteracting then
        self.nInteracting = self.nInteracting - dt
        if self.nInteracting <= 0 then
            self.nInteracting = nil
            self:_endInteraction()
        end
    end
    return (self.nInteracting == nil)
end

-- world coords
function Task:_incrementPathStep()
    self.tPath.nextStep = self.tPath.currentStep + 1

    local targetX,targetY = self.tPath[self.tPath.nextStep].x,self.tPath[self.tPath.nextStep].y
    local tx,ty = World._getTileFromWorld(targetX,targetY)

	-- MTF HACK:
	-- I removed diagonal movement, but that led to some pretty ugly zigzagging. So...
	-- if current and nextnext are adjacent
	-- but through a corner (dir nsew)
	-- if both diags are clear, just cut through the corner.
	local nextNext = self.tPath.nextStep+1
	if nextNext <= #self.tPath then
                --Profile.enterScope("isoWalkHack")
		local txNextNext,tyNextNext = World._getTileFromWorld(self.tPath[nextNext].x,self.tPath[nextNext].y)
		local txCurrent,tyCurrent = World._getTileFromWorld(self.tPath[self.tPath.currentStep].x,self.tPath[self.tPath.currentStep].y)
		local _,_,dir = World.isAdjacentToTile(txCurrent,tyCurrent, txNextNext, tyNextNext, true, false)
		if dir then
			local bCheat = false
			local dirA,dirB = nil,nil
			if dir == World.directions.N then
				dirA = World.directions.NW
				dirB = World.directions.NE
			elseif dir == World.directions.E then
				dirA = World.directions.SE
				dirB = World.directions.NE
			elseif dir == World.directions.W then
				dirA = World.directions.NW
				dirB = World.directions.SW
			elseif dir == World.directions.S then
				dirA = World.directions.SW
				dirB = World.directions.SE
			end
			if dirA then
				if World._isPathable(World._getAdjacentTile(txCurrent,tyCurrent,dirA)) and 
						World._isPathable(World._getAdjacentTile(txCurrent,tyCurrent,dirB)) then
					self.tPath.nextStep = nextNext
				end
			end

		end
                --Profile.leaveScope("isoWalkHack")
	end
	local wx,wy = self.tPath[self.tPath.nextStep].x,self.tPath[self.tPath.nextStep].y
    local tx,ty = World._getTileFromWorld(wx,wy)
	return wx,wy,tx,ty
end

function Task:_enteredNewTile()
    self.nObstructionTime = nil
    if self.rChar.tStats.nTeam == Character.TEAM_ID_PLAYER and not self.rChar:isElevated() then
        Room.visibilityBlip(self.rChar:getTileLoc())
    end
    self.rChar:enteredNewTile()
    --[[
    if self.rChar.rBlobShadow then
        local tileValue = World.getTileValueFromWorld( self.rChar:getLoc() )
        if tileValue == World.logicalTiles.SPACE then        
            self.rChar.rBlobShadow:setVisible(false)
        else
            self.rChar.rBlobShadow:setVisible(true)
        end
    end
    ]]--
end

-- Do we think we'll be available to take on this proposed queued task in a reasonable amount of time?
-- i.e. are we almost done here?
function Task:availableForInterruption(sProposedQueuedTaskName)
    if sProposedQueuedTaskName == 'Chat' or sProposedQueuedTaskName == 'ChatPartner' then
        return self:estimatedTimeRemaining() < 4.5
    elseif sProposedQueuedTaskName == 'GetFieldScanned' then
        return self:estimatedTimeRemaining() < 9
    end
    return false
end

-- UTILITY FUNCTIONS:
-- Not used by Task.lua. Intended for subclass use.

-- tickWalk
-- Assumes self.tPath is set.
-- @return: true if finished, tx, ty of obstructing tile on unsuccessful exit
function Task:tickWalk(dt)
    if not self.tPath then
        return true
    end

    if self.sSymptomAnim then
        if not self.rChar:isPlayingAnim(self.sSymptomAnim) then
            self.sSymptomAnim = nil
        else
            return
        end
    else
        local tAnimatingMalady
        self.sSymptomAnim,tAnimatingMalady = self.rChar:getIdleAnim()
        if self.sSymptomAnim then
            -- So, we only actually play the anim if we're not in a spacesuit, but we still
            -- register it as played anyway.
            if not self.rChar:wearingSpacesuit() then
                self.rChar:playAnim(self.sSymptomAnim,true)
            end
            self.rChar:playedIdleAnim(self.sSymptomAnim,tAnimatingMalady)
        end
    end

    local sTickReturn, tData = self.tPath:tick(dt)

    if sTickReturn and sTickReturn ~= 'blocked' and sTickReturn ~= 'deelevate' and sTickReturn ~= 'elevate' then
        self:_enteredNewTile()
    end
    if self.bComplete then
        -- handle task completion/interruption in _enteredNewTile
        return
    end

    if sTickReturn == 'complete' then
        self.tPath = nil
        if tData then
            self.bPathCompletionSuccess = false
            if self.bInterruptOnPathFailure then
                self:interrupt('Path failed:'..tostring(tData))
                return false
            else
                return true
            end
        else
            self.bPathCompletionSuccess = true
            return true
        end
    elseif sTickReturn == 'enqueue' then
        for _,tTaskSpec in ipairs(tData) do
            self:queueTask(tTaskSpec.sName,tTaskSpec.tData)
        end
    elseif sTickReturn == 'nextStep' then
        if not self.rChar:wearingSpacesuit() then
		    local _,_,vacuumMag = Oxygen.getVacuumVec(tData.nNextX, tData.nNextY)
            if vacuumMag > Oxygen.VACUUM_THRESHOLD_END then
		        local _,_,curVacuumMag = Oxygen.getVacuumVec(tData.nPrevX, tData.nPrevY)
                if curVacuumMag < vacuumMag then
                    Print(TT_Gameplay,'Character interrupting path due to vacuum.')
                    self.bPathCompletionSuccess = false
                    self.tPath = nil
                    if self.bInterruptOnPathFailure then
                        self:interrupt('Path blocked by vacuum.')
                        return
                    else
                        return true, tData.nNextTX,tData.nTextTY
                    end
                end
            end
        end
    elseif sTickReturn == 'spacewalk' then
    elseif sTickReturn == 'elevate' then
        self.rChar:setElevatedSpacewalk(true)
    elseif sTickReturn == 'deelevate' then
        self.rChar:setElevatedSpacewalk(false)
    elseif sTickReturn == 'blocked' then
        if self:obstructionWait(dt) then
            Print(TT_Gameplay,'Character giving up on path due to obstruction.',self.rChar:getUniqueID())
            self.bPathCompletionSuccess = false
            -- give up
            self.tPath = nil
            --Profile.leaveScope("tickWalk")
            if self.bInterruptOnPathFailure then
                self:interrupt('Path obstructed.')
                return
            else
                return true, tData.nNextTX,tData.nTextTY
            end
        else
            return
        end
    end
	-- are we near a door? (do only once we've moved)
	local tx, ty = World._getTileFromWorld(self.rChar:getLoc())
	local ObjectList = require('ObjectList')
	for i=2,9 do
		local dx,dy = World._getAdjacentTile(tx, ty, i)
		local door = ObjectList.getDoorAtTile(dx, dy)
		if door then
			door:open()
		end
	end
end

function Task:setPath(tPath)
    self.tPath = tPath

    assertdev(self.tPath)
    if not self.tPath then return end

    self.tPath:start(self.rChar,self.sWalkOverride,self.sBreatheOverride)
    self.tPath.elapsedMoveTime = nil
end

--[[
function Task:getRandomLocation(bSafe)
	local x,y
	local maxMoveDistance = 4 * World.tileWidth
    -- spacewalking wanderers stay on a leash relative to where they started, so they don't end up off the map.
    -- MTF TODO: successive wander task selections re-set this leash, so characters can get very far.
    -- Need to figure out a solution to this.
    if self.rChar:spacewalking() then
        x,y = self.startX,self.startY
        maxMoveDistance = 4 * World.tileWidth
    else
        x,y= self.rChar:getLoc()
    end
	local maxIterations = 10
	
	local iterations = 0
	while iterations < maxIterations do
		iterations = iterations + 1
		local newX, newY = x + math.random(-maxMoveDistance, maxMoveDistance), y + math.random(-maxMoveDistance, maxMoveDistance)
		local bPasses = World.isPathable( newX, newY ) 
		if bPasses then            
			local r = Room.getRoomAt(newX,newY)
            if self.rChar:spacewalking() then
                if r and (r:getOxygenScore() > Character.OXYGEN_SUFFOCATING or r:isDangerous()) then
                    bPasses = false
                end
			elseif not r or r:isDangerous(self.rChar) then
				bPasses = false
			end
		end
		if bPasses then                
			x,y = newX,newY
			break
		end
	end
	
	return x,y
end
]]--

function Task:createPathTo(rTarget,requiredDirection)
    local wx,wy = self.rChar:getLoc()
    local targetX,targetY
    if requiredDirection then
        local tileX,tileY = rTarget:getTileLoc()
        tileX,tileY = g_World._getAdjacentTile(tileX,tileY,requiredDirection)
        targetX,targetY = g_World._getWorldFromTile(tileX,tileY)
        return self:createPath(wx,wy,targetX,targetY)
    else
        targetX,targetY = rTarget:getLoc()
        return self:createPath(wx,wy,targetX,targetY,true)
    end
end

-- world coords
function Task:createPath(wx,wy, targetX,targetY, bNearest, bAllowHostilePathing)
    if bAllowHostilePathing == nil then bAllowHostilePathing = self.rActivityOption.tData.bAllowHostilePathing end
    
    local tPath = Pathfinder.getPath(wx, wy, targetX, targetY, self.rChar, {bPathToNearest=bNearest, nRequiredTeam=(not bAllowHostilePathing and self.rChar:getTeam())})
    if tPath then
        self:setPath(tPath)
        return true
    end
end

function Task:setWait(nSeconds)
    self.nTaskWait = nSeconds
end

function Task:tickWait(dt)
    if self.nTaskWait then
        self.nTaskWait = self.nTaskWait-dt
        if self.nTaskWait <= 0 then
            self.nTaskWait = nil
            return false
        end
        return true
    end
    return false
end

-- Generic handler for anim events to pass data to tasks
function Task:handleGenericAnimEvent(sAnimEventName, tParameters)

end

function Task:getDuration(nMinDuration, nMaxDuration, nJobID)
    if nJobID then
        return DFMath.lerp(nMaxDuration, nMinDuration, self.rChar:getJobCompetency(nJobID))
    else
        return DFMath.lerp(nMinDuration, nMaxDuration, math.random())
    end
end

function Task:getJobSuccess(nJob)
	-- common logic for job skill (competence) checks
	local competency = self.rChar:getJobCompetency(nJob)
    local nNoFailThreshold = self.NO_FAIL_COMPETENCY_THRESHOLD or CharacterConstants.NO_FAIL_COMPETENCY_THRESHOLD
	if competency >= nNoFailThreshold then
        --Print(TT_Gameplay, '** Task:getJobSuccess auto-succeed; thresh: comp '..competency..', job '..nJob..', char '..self.rChar:getUniqueID())
		return true
	end
    -- MAX_CHANCE_TO_FAIL = % chance to fail at 0% competence
    -- MIN_CHANCE_TO_FAIL = % chance to fail at 100% competence
    local nMaxFailChance = self.MAX_CHANCE_TO_FAIL or CharacterConstants.MAX_CHANCE_TO_FAIL
    local nMinFailChance = self.MIN_CHANCE_TO_FAIL or CharacterConstants.MIN_CHANCE_TO_FAIL
	local nChanceToSucceed = 1 - DFMath.lerp(nMaxFailChance, nMinFailChance, competency)
    local bSuccess = math.random() < nChanceToSucceed
    --Print(TT_Gameplay, '** Task:getJobSuccess '..tostring(bSuccess)..'; chance ' .. tostring(nChanceToSucceed) .. ', comp '..tostring(competency)..', job '..tostring(nJob)..', char '..tostring(self.rChar:getUniqueID()))
    return bSuccess
end

---------------------------------------------
-- COOPERATIVE TASK UTILITIES
---------------------------------------------
-- hacky, low-quality timeout test just for egregiously bad failures.
function Task:_hackyFollowTimeoutTest(dt)
    if GameRules.elapsedTime > self.nNextTimeoutTest then
        self.nNextTimeoutTest=GameRules.elapsedTime+5
        local tx,ty = g_World._getTileFromWorld(self.rChar:getLoc())
        local ttx,tty = g_World._getTileFromWorld(self.rTargetObject:getLoc())
        local nDist = MiscUtil.isoDist(tx,ty,ttx,tty)
        if not self.nLastTimeoutDist then
            self.nLastTimeoutDist = nDist
        elseif nDist >= self.nLastTimeoutDist then
            return true
        else
            self.nLastTimeoutDist = nDist
        end
    end
end

function Task:_testCoopStillValid(sPendingTaskRequired)
    if self.rTargetObject:getCurrentTaskName() == sPendingTaskRequired then
        if self.rTargetObject.rCurrentTask.rTargetObject ~= self.rChar then
            return false, "Target has an appointment with another character."
        end
    elseif self.rTargetObject:getPendingTaskName() ~= sPendingTaskRequired then 
        return false, "Target character not waiting for the task we want."
    elseif self.rTargetObject:getPendingTaskPartner() ~= self.rChar then
        return false, "Target character waiting for correct task, but not with us."
    end
    return true
end

function Task:getActivityFriendlyName()
	-- override in subclasses for fancier behavior, eg Tasks/Explore.lua
	return g_LM.line(OptionData.tAdvertisedActivities[self.activityName].UIText)
end

return Task
