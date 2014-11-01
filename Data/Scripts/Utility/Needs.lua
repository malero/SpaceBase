local OptionData = require('Utility.OptionData')
local Log = require('Log')
local Character = require('CharacterConstants')

local Needs = {
    MAX_VALUE = 100,
    MIN_VALUE = -100,
}

function Needs.getAdjustedPromise(tPersonality, promisedVal, activityName, needName)
    if type(promisedVal) ~= 'table' then return promisedVal end

    local score = promisedVal.base

    if promisedVal.Bravery then
        score = score + promisedVal.Bravery * tPersonality.nBravery
    end

    return score
end

-- curve types
-- the maths terminology here is probably inaccurate

function Needs.genericCurve(val)
    return 100*100/(val+200)
end

function Needs.powerFnCurve(val, amplitude)
	local amplitude = amplitude or 175
    return 100*100 / (val + amplitude)
end

function Needs.logCurve(val, xOffset, amplitude, frequency)
	local xOffset = xOffset or 95
	local amplitude = amplitude or 1.5 -- lower = greater
	local frequency = frequency or 2
	return -math.log(val + xOffset) * frequency / amplitude
end

function Needs.linearCurve(val, steepness)
	local steepness = steepness or 3
	return -val / steepness
end

function Needs.quadraticCurve(val, xOffset, pow, amplitude, frequency)
	local xOffset = xOffset or -100
	local pow = pow or 2
	local amplitude = amplitude or 100
	local frequency = frequency or 2
	return ((val + xOffset)^pow / amplitude) / frequency
end

-- need-specific curves
-- just pluggin' values into the archetypes above

function Needs.dutyCurve(val)
	return Needs.linearCurve(val, 4.8)
end

function Needs.socialCurve(val)
	return Needs.quadraticCurve(val, -100, 2, 100, 6)
end

function Needs.amusementCurve(val)
	return Needs.quadraticCurve(val, -40, 2, 100, 4)
end

function Needs.energyCurve(val)
	return Needs.quadraticCurve(val, -60, 2, 200, 14)
end

function Needs.hungerCurve(val)
	return Needs.quadraticCurve(val, -40, 2, 50, 10)
end

-- score functions
-- (for now the generic one works for everything)

function Needs.genericScoreFn(curVal, futureVal, curveFn)
    curVal = Needs.clamp(curVal)
    futureVal = Needs.clamp(futureVal)
	local score = 0
	if not curveFn then
		score = Needs.genericCurve(curVal) - Needs.genericCurve(futureVal)
	else
		score = curveFn(curVal) - curveFn(futureVal)
	end
	-- infinity
	if score == 1/0 then
		print('Needs.lua: score was INF')
		score = 1000
	-- NaN
	elseif score ~= score then
		print('Needs.lua: score was NaN')
		score = 0
	end
	return score
end

function Needs.clamp(needValue)
    return math.max(math.min(needValue,Needs.MAX_VALUE),Needs.MIN_VALUE)
end

Needs.tNeedList={
    Duty=
    {
        scoreFn = Needs.genericScoreFn,
		curveFn = Needs.dutyCurve,
		-- post logs of this type if the need exceeds bad/good thresholds
		tLowMoraleLogType = Log.tTypes.MORALE_LOW_DUTY,
		tHighMoraleLogType = Log.tTypes.MORALE_HIGH_DUTY,
        graphColor = { 0, 0, 1, 1.0 },
    },
    Social=
    {
        scoreFn = Needs.genericScoreFn,
		curveFn = Needs.socialCurve,
		tLowMoraleLogType = Log.tTypes.MORALE_LOW_SOCIAL,
		tHighMoraleLogType = Log.tTypes.MORALE_HIGH_SOCIAL,
        graphColor = { 1, 0, 0, 1.0 },
    },
    Amusement=
    {
        scoreFn = Needs.genericScoreFn,
		curveFn = Needs.amusementCurve,
		tLowMoraleLogType = Log.tTypes.MORALE_LOW_AMUSEMENT,
		tHighMoraleLogType = Log.tTypes.MORALE_HIGH_AMUSEMENT,
        graphColor = { 0, 1, 1, 1.0 },
    },
    Energy=
    {
        scoreFn = Needs.genericScoreFn,
		curveFn = Needs.energyCurve,
		initMin = 0.75,
		initMax = 0.75,
		tLowMoraleLogType = Log.tTypes.MORALE_LOW_ENERGY,
		tHighMoraleLogType = Log.tTypes.MORALE_HIGH_ENERGY,
        graphColor = { 1, 1, 0, 1.0 },
    },
    Hunger=
    {
        scoreFn = Needs.genericScoreFn,
		curveFn = Needs.hungerCurve,
		tLowMoraleLogType = Log.tTypes.MORALE_LOW_HUNGER,
		tHighMoraleLogType = Log.tTypes.MORALE_HIGH_HUNGER,
		graphColor = { 0, 1, 0, 1.0 },
    },
    --[[
    SurvivalLow=
    {
        scoreFn = Needs.survivalLowScoreFn,
    },
    SurvivalNormal=
    {
        scoreFn = Needs.survivalNormalScoreFn,
    },
    System=
    {
        scoreFn = Needs.SystemScoreFn,
    },
    ]]--
}

return Needs
