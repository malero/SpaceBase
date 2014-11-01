local Task=require('Utility.Task')
local World=require('World')
local Class=require('Class')
local Room=require('Room')
local Log=require('Log')
local DFMath=require('DFCommon.Math')
local Character=require('Character')
local WanderAround = Class.create(Task)

--WanderAround.emoticon = 'wander'

function WanderAround:init(rChar,tPromisedNeeds,rActivityOption)
    self.super.init(self,rChar,tPromisedNeeds,rActivityOption)
    self.duration = math.random(5,10)
    self.bSpace=rActivityOption.tData.bSpace
    self.startX,self.startY = self.rChar:getLoc()
    if rActivityOption.tBlackboard.tPath then
        self:setPath(rActivityOption.tBlackboard.tPath)
    else
        self:_idle()
    end
end

function WanderAround:_idle()
    self.idleTime = DFMath.randomFloat(.5,1.5)
    self.currentTaskIdle = true
    self.rChar:playAnim('breathe')
end

function WanderAround:_walk()
    local x,y = self:_getRandomLocation()
    local cx,cy = self.rChar:getLoc()
    if self:createPath(cx,cy,x,y) then
        self.currentTaskIdle = false
    else
        self:_idle()
    end    
end

function WanderAround:onUpdate(dt)
    self.duration = self.duration - dt
    if self.duration < 0 then
        local tLogData = {}
        if self.bSpace then
            Log.add(Log.tTypes.WANDER_SPACE, self.rChar, tLogData)
        else            
            Log.add(Log.tTypes.WANDER, self.rChar, tLogData)
        end
        return true
    end

    if self.currentTaskIdle then
        self.idleTime = self.idleTime - dt
        if self.idleTime < 0 then
            self:_walk()
        end
    else
        if self:tickWalk(dt) then
            self:_idle()
        end
    end
end

function WanderAround:_getRandomLocation()
	local x,y
	local maxMoveDistance = 4 * World.tileWidth
    -- spacewalking wanderers stay on a leash relative to where they started, so they don't end up off the map.
    -- MTF TODO: successive wander task selections re-set this leash, so characters can get very far.
    -- Need to figure out a solution to this.
    if self.bSpace then
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

		local bPasses
        local tileX,tileY = World._getTileFromWorld(newX,newY)
        tileX,tileY = World.clampTileToBounds(tileX,tileY)
        newX,newY = World._getWorldFromTile(tileX,tileY)
        local bTileInSpace = World._getTileValue(tileX,tileY) == World.logicalTiles.SPACE
        if self.bSpace then
            bPasses = bTileInSpace
        else
            bPasses = World.isPathable( newX, newY, true ) and not self.rChar:inHazardousLoc(newX,newY)
        end
        --[[
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
        ]]--
		if bPasses then                
			x,y = newX,newY
			break
		end
	end
	
	return x,y
end


return WanderAround
