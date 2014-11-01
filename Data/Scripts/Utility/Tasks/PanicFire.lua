local Task=require('Utility.Task')
local World=require('World')
local DFMath=require('DFCommon.Math')
local Class=require('Class')

local PanicFire = Class.create(Task)
PanicFire.sWalkOverride = 'panic_walk'
PanicFire.sBreatheOverride = 'panic_breathe'
PanicFire.DURATION_MIN = 5
PanicFire.DURATION_MAX = 5
PanicFire.IDLE_MIN = 0.5
PanicFire.IDLE_MAX = 1.5
--PanicFire.emoticon = 'alert'

function PanicFire:init(rChar,tPromisedNeeds,rActivityOption)
    Task.init(self,rChar,tPromisedNeeds,rActivityOption)
    self.duration = math.random(PanicFire.DURATION_MIN, PanicFire.DURATION_MAX)
    self:_idle()
end

function PanicFire:_idle()
    self.idleTime = DFMath.randomFloat(PanicFire.IDLE_MIN, PanicFire.IDLE_MAX)
    self.currentTaskIdle = true
    self.rChar:playAnim('panic_breathe')
end

function PanicFire:_walk()
    local x,y = self:_getRandomLocation()
    local cx,cy = self.rChar:getLoc()
    if self:createPath(cx,cy,x,y) then
        self.currentTaskIdle = false
    end
end

function PanicFire:onUpdate(dt)
    self.duration = self.duration - dt
    if self.duration < 0 then
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

    function PanicFire:_getRandomLocation()
        local x,y = self.rChar:getLoc()
        local maxMoveDistance = 4 * World.tileWidth
        local maxIterations = 10
        
        local iterations = 0
        while iterations < maxIterations do
            iterations = iterations + 1
            local newX, newY = x + math.random(-maxMoveDistance, maxMoveDistance), y + math.random(-maxMoveDistance, maxMoveDistance)
            local bPasses = World.isPathable( newX, newY ) and (World.getTileValueFromWorld(newX,newY) ~= World.logicalTiles.SPACE)
            if bPasses then                
                x,y = newX,newY
                break
            end
        end
        
        return x,y
    end


return PanicFire
