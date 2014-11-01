local Task=require('Utility.Task')
local World=require('World')
local GameRules=require('GameRules')
local Character=require('Character')
local Class=require('Class')
local Oxygen=require('Oxygen')

local VacuumPull = Class.create(Task)

--VacuumPull.OXYGEN_TO_VEL = .5
VacuumPull.MAX_VEL = 100
VacuumPull.VEL_SCALAR = 6
VacuumPull.MIN_VEL = 6
--VacuumPull.emoticon = 'alert'

function VacuumPull:init(rChar,tPromisedNeeds,rActivityOption)
    self.super.init(self,rChar,tPromisedNeeds,rActivityOption)
    self.duration = 9999*5
    self.rChar:playAnim('space_flail')
	local vx,vy,mag = Oxygen.getVacuumVec(self.rChar:getLoc())
	print('starting vacuum',GameRules.elapsedTime,'vac',vx,vy,mag)
end

function VacuumPull:tickVacuum(dt)
    dt = dt*VacuumPull.VEL_SCALAR
	local wx,wy = self.rChar:getLoc()
	if not self.rChar:inVacuum() then
        if not self.lastMag then
            return true
        else
            -- slow from max vacuum velocity to a standstill in about 2 seconds.
            self.lastMag = math.max(self.lastMag - self.lastMag * .5 * VacuumPull.MAX_VEL * dt, 0)
        end
	end

	local vx,vy,mag = Oxygen.getVacuumVec(wx,wy)
    if mag > VacuumPull.MIN_VEL then
        mag = math.min(mag,VacuumPull.MAX_VEL)
    else
        vx,vy,mag = self.lastvx,self.lastvy,self.lastMag
        if not mag or mag < VacuumPull.MIN_VEL then 
            return true 
        end
    end

	local targX,targY = World.getTargetLoc(wx,wy,vx,vy,mag,false,true)

	if targX ~= wx or targY ~= wy then
		local dx,dy = targX-wx,targY-wy
		if dt * dt * mag * mag > dx*dx+dy*dy then
			self.rChar:setLoc(targX,targY)
		else
			local targetMag = math.sqrt(dx*dx+dy*dy)
            local normalizedDX,normalizedDY = dx/targetMag,dy/targetMag
			self.rChar:setLoc(wx+normalizedDX * mag * dt, wy+normalizedDY * mag * dt)
		end
    else
        vx,vy,mag = 0,0,0
	end
    self.rChar.vacuumVecX, self.rChar.vacuumVecY =vx,vy
    self.lastvx,self.lastvy,self.lastMag = vx,vy,mag
end

function VacuumPull:onUpdate(dt)
    if self:tickVacuum(dt) then
        return true
    end
end

return VacuumPull
