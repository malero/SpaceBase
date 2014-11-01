local GameRules = require('GameRules')
local HintData = require('HintData')

local Hint = {
    profilerName='Hint',
}

Hint.tickIndex = 1
Hint.CHECKS_PER_TICK = 3
Hint.DEFAULT_PRIORITY = 1

-- hint statuses:
-- name, how long condition has been true, how long since last display
-- (load/save this table + the UI state)
Hint.tActiveHints = {}

function Hint.init()    
end

function Hint.isActive(hint)
	for _,other in pairs(Hint.tActiveHints) do
		if hint == other then
			return true
		end
	end
	return false
end

function Hint.deactivate(hint)
	for i,other in ipairs(Hint.tActiveHints) do
		if hint.name == other.name then
            table.remove(Hint.tActiveHints, i)
            break
		end
	end
end

function Hint.getAllActiveHints()
    return Hint.tActiveHints
end

function Hint.onTick(dt)
    local tChecks = Hint.getNextHints()
    for i,tHint in ipairs(tChecks) do
		-- evaluate the hint
        local bActivate,tReplacements = tHint.checkFn()
		-- track time this hint has been true
		if not tHint.nTimeTrue or not bActivate then
			tHint.nTimeTrue = 0
		end
		if bActivate then
			if not tHint.nLastTrueTime then
				tHint.nLastTrueTime = GameRules.elapsedTime
			end
			tHint.nTimeTrue = tHint.nTimeTrue + (GameRules.elapsedTime - tHint.nLastTrueTime)
			tHint.nLastTrueTime = GameRules.elapsedTime
			if GameRules.bHintsDisabled then
				bActivate = false
			end
			-- store replacements for hints that need em
			tHint.tReplacements = tReplacements
			-- if "time true before display" set and time < that, don't show
			if tHint.nTimeTrueBeforeDisplay and tHint.nTimeTrue < tHint.nTimeTrueBeforeDisplay then
				bActivate = false
			end
			-- if "display X seconds then hide" set, check time
			if tHint.nDisplayTimeBeforeHide and tHint.nTimeTrue >= tHint.nDisplayTimeBeforeHide then
				bActivate = false
			end
		end
        if bActivate and not Hint.isActive(tHint) then
			Hint.activate(tHint)
        elseif not bActivate and Hint.isActive(tHint) then
			Hint.deactivate(tHint)
        end
    end
	-- determine current highest-priority hint(s)
	local nHighestPri = -1
	for _,tHint in pairs(Hint.tActiveHints) do
		-- also initialize priority here if needed
		if not tHint.nPriority then
			tHint.nPriority = Hint.DEFAULT_PRIORITY
		end
		if tHint.nPriority > nHighestPri then
			nHighestPri = tHint.nPriority
		end
	end
	-- only show hints at the highest current priority level
	for _,tHint in pairs(Hint.tActiveHints) do
		if tHint.nPriority < nHighestPri then
			Hint.deactivate(tHint)
		end
	end
    -- increment and cap at end of list
    -- this can result in variable # of hints processed per tick, don't care
    Hint.tickIndex = Hint.tickIndex + Hint.CHECKS_PER_TICK
    if Hint.tickIndex > table_size(HintData.tHints) then
        Hint.tickIndex = 1
    end
    --print('Hint.tickIndex: '..Hint.tickIndex)
end

function Hint.getHintWithName(sName)
	for _,hint in pairs(require('HintData').tHints) do
		if hint.name == sName then
			return hint
		end
	end
end

function Hint.getNextHints()
    local hints = {}
    local last = Hint.tickIndex + Hint.CHECKS_PER_TICK - 1
    last = math.min(last, table_size(HintData.tHints))
    for i = Hint.tickIndex,last do
		table.insert(hints, HintData.tHints[i])
    end
    return hints
end

function Hint.activate(tHint)
	table.insert(Hint.tActiveHints, tHint)
end

function table_size(t)
    local i = 0
    for _ in pairs(t) do i = i + 1 end
    return i
end

return Hint
