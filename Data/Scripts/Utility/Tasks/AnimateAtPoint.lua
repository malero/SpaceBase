local Task=require('Utility.Task')
local Class=require('Class')
local DFUtil = require('DFCommon.Util')

-- generic class for common "go to a point and animate" tasks

local AnimateAtPoint = Class.create(Task)

-- list of anims to play
AnimateAtPoint.tAnims = {
	-- bPlayOnce: if true, phase ends as soon as anim finishes
	{sAnimName = 'death_shot', bPlayOnce = true},
	{sAnimName = 'breathe'},
}

AnimateAtPoint.nPhaseDurationMin = 6
AnimateAtPoint.nPhaseDurationMax = 9
AnimateAtPoint.nPhasesMin = 2
AnimateAtPoint.nPhasesMax = 4

function AnimateAtPoint:init(rChar, tPromisedNeeds, rActivityOption)
    Task.init(self, rChar, tPromisedNeeds, rActivityOption)
    self.bInterruptOnPathFailure = true
	if rActivityOption.tBlackboard.tPath then
		self:setPath(rActivityOption.tBlackboard.tPath)
	end
	-- task will comprise multiple phases, precalc and store in a table
	self.tPhases = {}
	self.nPhase = math.random(self.nPhasesMin, self.nPhasesMax)
	self.duration = 0
	for i=1,self.nPhase do
		local tPhase = {}
		local tAnim = DFUtil.arrayRandom(self.tAnims)
		tPhase.sAnimName = tAnim.sAnimName
		tPhase.bPlayOnce = false
		if tAnim.bPlayOnce then
			-- play once: duration is length of anim
			tPhase.nDuration = rChar:getAnimDuration(tPhase.sAnimName)
			assertdev(tPhase.nDuration ~= nil)
            if tPhase.nDuration == nil then tPhase.nDuration = 1 end
			tPhase.bPlayOnce = true
		else
			-- random phase duration
			tPhase.nDuration = math.random(self.nPhaseDurationMin, self.nPhaseDurationMax)
		end
		table.insert(self.tPhases, tPhase)
		-- track total duration
		self.duration = self.duration + tPhase.nDuration
	end
	-- timer that tells us when a phase is over
	self.nCurrentPhaseDuration = self.tPhases[#self.tPhases].nDuration
end

function AnimateAtPoint:_animate()
	local tAnim = self.tPhases[self.nPhase]
	self.rChar:playAnim(tAnim.sAnimName, tAnim.bPlayOnce)
	self.bAnimating = true
end

function AnimateAtPoint:onComplete(bSuccess)
	Task.onComplete(self, bSuccess)
end

function AnimateAtPoint:onUpdate(dt)
	-- done?
	if self.duration <= 0 then
		return true
	-- new phase?
	elseif self.nCurrentPhaseDuration <= 0 then
		self.nPhase = self.nPhase - 1
        if self.nPhase <= 0 then return true end

		self.nCurrentPhaseDuration = self.tPhases[self.nPhase].nDuration
		self:_animate()
	-- starting?
	elseif self:tickWalk(dt) and not self.bAnimating then
		self:_animate()
	end
	if self.bAnimating then
		self.nCurrentPhaseDuration = self.nCurrentPhaseDuration - dt
		self.duration = self.duration - dt
	end
end

return AnimateAtPoint
