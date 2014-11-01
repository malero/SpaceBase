-- Objects that advertise utility are expected to have:
--  getUtilityOptions: a function that returns an array of utility-supplying options.
--  OR tUtilityOptions: an array of utility-supplying options.

local DFMath = require('DFCommon.Math')
local DFUtil = require('DFCommon.Util')
local World = require('World')
local Needs = require('Utility.Needs')
local Room = require('Room')
local GlobalObjects = require('Utility.GlobalObjects')
local CommandObject = require('Utility.CommandObject')
local MiscUtil = require('MiscUtil')
local Profile = require('Profile')

local UtilityAI = {
    DEBUG_PROFILE = false,
}

function UtilityAI.getGlobalList()
    return { { stub=true, } }
end

function UtilityAI.createIdleTask(rChar)
    return require('Utility.Tasks.Breathe').new(rChar)
end

function UtilityAI.getNearbyCharacters(rChar)
    return require('CharacterManager').getCharacters()
end

function getOptionTargetName(option)
	if not option.tData then
		return nil
	elseif option.tData.rTarget then
		return option.tData.rTarget.tStats.sUniqueID
	elseif option.tData.rTargetObject then
		return option.tData.rTargetObject.sUniqueName
	end
	return nil
end

function UtilityAI.getBestTask(rChar, nMinPri, bLog, tGathererOverride)
    if UtilityAI.DEBUG_PROFILE then Profile.enterScope("GetBestTask") end

    local tValidOptions={} -- array of refs to options
    local tAllOptions={} -- {rOption=tOptionData, ... }
    local tSatisfiers={} -- { conditionName={ rOption=conditionValue, ... }, ... }
    
--    local nBestPri = -1

    local tGatherers = tGathererOverride or rChar.tActivityOptionGatherers

    for gatherName,gatherData in pairs(tGatherers) do

        if UtilityAI.DEBUG_PROFILE then Profile.enterScope("UtilityGather_"..gatherName) end
        local tObjects = gatherData.gatherFn(rChar)
        if UtilityAI.DEBUG_PROFILE then Profile.leaveScope("UtilityGather_"..gatherName) end

        for _, object in ipairs(tObjects) do
            for _,rOption in ipairs((object.getUtilityOptions and object:getUtilityOptions(rChar)) or object.tUtilityOptions) do
                assertdev(rOption.tBlackboard)
                -- It's possible that this option satisfies some preconditions. 
                -- Satisfiers are treated differently, so calc that up front.
                -- XXX:  Get rid of pairs call here
                local bSatisfier = false
                local tSatisfies = rOption:getSatisfies()
                for k,v in pairs(tSatisfies) do
                    if not tSatisfiers[k] then tSatisfiers[k] = {} end
                    tSatisfiers[k][rOption] = v
                    bSatisfier = true
                end            
            
                if UtilityAI.DEBUG_PROFILE then Profile.enterScope("UtilityScore"..rOption.name) end
                -- do the first round of quick tests on an option.
                -- Priority note: satisfiers don't have to fill priority prereqs.
                local bValid, sReason = rOption:earlyGates(rChar, (not bSatisfier and nMinPri) or 0)
                if UtilityAI.DEBUG_PROFILE then Profile.leaveScope("UtilityScore"..rOption.name) end

                local tOptionEntry = {rOption=rOption, bEarlyGatesValid=bValid, sReason=sReason}
                if bValid then
                    -- calc the option's max score. This is used to sort the options, and only evaluate the ones that have
                    -- a chance of succeeding.
                    tOptionEntry.nMaxScore=rOption:getMaxPotentialScore(rChar)
                    tOptionEntry.nPri=rOption:getPriority(rChar)
--                    nBestPri = math.max(rOption:getPriority(), nBestPri)
                end
                tAllOptions[rOption] = tOptionEntry

                -- For now, Satisfiers are not actions that can be taken on their own.
                -- They'll only be used to fulfill prereqs. So don't add them to the valid options list.
                if bValid and not bSatisfier then
                    if bValid then
                        table.insert(tValidOptions, rOption)
                    end
                end
            end
        end
    end
    
    -- evaluate options in order of max score.
    table.sort(tValidOptions, function(a,b) 
        if tAllOptions[a].nPri ~= tAllOptions[b].nPri then 
            return tAllOptions[a].nPri > tAllOptions[b].nPri 
        end
        return tAllOptions[a].nMaxScore > tAllOptions[b].nMaxScore 
    end)

    local nBestPri, nBestScore, tBestOptionData
    for _,rOption in ipairs(tValidOptions) do
        local tOptionEntry = tAllOptions[rOption]

        -- early out: if we've already calculated an option better than this option's max, we're done.
        if nBestPri and nBestPri > tOptionEntry.nPri then 
            break
        end
        if nBestScore and nBestScore > tOptionEntry.nMaxScore then
            break
        end

        UtilityAI._fillOutOptionEntry(rChar,tOptionEntry, tAllOptions,tSatisfiers)

        if tOptionEntry.bFullyValid then
            if not nBestPri or (tOptionEntry.nPri >= nBestPri and tOptionEntry.nTotalScore > nBestScore) then
                nBestPri = tOptionEntry.nPri
                nBestScore = tOptionEntry.nTotalScore
                tBestOptionData = tOptionEntry
            end
        end
    end
	
    local logStr = ''
    if bLog then
        if tBestOptionData then
            -- log the option we selected.
            logStr = logStr .. UtilityAI._getScoreStr(tBestOptionData) .. '\n'
        end
        for _,rOption in ipairs(tValidOptions) do
            -- log other options that made it past the first gates but then failed.
            local tOptionData = tAllOptions[rOption]
            if tOptionData ~= tBestOptionData then
                logStr = logStr .. UtilityAI._getScoreStr(tOptionData) .. '\n'
            end
        end
        for rOption,tOptionData in pairs(tAllOptions) do
            -- finally log all options that were gated early.
            if not tOptionData.bEarlyGatesValid then
                if tOptionData.sReason == 'wrong job' then
                    -- too much spam; we don't need to see this reason because it's usually obvious.
                else
                    logStr = logStr .. UtilityAI._getScoreStr(tOptionData) .. '\n'
                end
            end
        end
    end
    
    if UtilityAI.DEBUG_PROFILE then Profile.leaveScope("GetBestTask") end
    
    
    if tBestOptionData then
        if tBestOptionData.tSatisfiers then
            -- if there was an unsatisfied prereq for this option, that's actually what we take.
            -- then we'll redecide once that's done.
            return tBestOptionData.tSatisfiers[1], nBestScore, logStr
        else
            return tBestOptionData.rOption, nBestScore, logStr
        end
    end
    return nil,nil,logStr
end

function UtilityAI._fillOutOptionEntry(rChar,tOptionEntry,tAllOptions,tSatisfiers,nDepth)
    if not nDepth then nDepth = 1
    else nDepth = nDepth+1 end

    -- Bail early on already-computed options.
    if tOptionEntry.bFullyValid ~= nil then
        return
    end
    assert(tOptionEntry.bEarlyGatesValid ~= nil)
    if tOptionEntry.bEarlyGatesValid == false then
        tOptionEntry.bFullyValid = false
        return
    end

    -- Calc prereqs.
    local tUnsatisfiedPrereqs = tOptionEntry.rOption:getUnsatisfiedPrereqs(rChar)
    local nPrereqScore = 0

    for k,v in pairs(tUnsatisfiedPrereqs) do

        -- NOTE: for now, we only support 1 level of planning.
        -- So if a satisfier has its own prereqs, we can test them for true/false.
        -- But we will NOT add their prereq satisfiers as further tasks, because we only allow 1 level.
        -- To support further levels of planning we'd need to write a mildly intelligent planner.
        -- In short: if nDepth > 1, and we still have unsatisfied prereqs, this option is unavailable.
        if nDepth == 1 then
            -- rBestOption is the best satisfier for this unsatisfied prereq.
            local nBestScore,rBestOption
            if tSatisfiers[k] then
                for rOption,satisfyValue in pairs(tSatisfiers[k]) do
                    -- verify that the activity satisfies this condition in the correct way.
                    if satisfyValue == v then
                        UtilityAI._fillOutOptionEntry(rChar,tAllOptions[rOption],tAllOptions,tSatisfiers,nDepth)
                        if tAllOptions[rOption].nTotalScore then
                            -- the prereq is valid. Is it good enough?
                            if not nBestScore or tAllOptions[rOption].nTotalScore > nBestScore then
                                nBestScore = tAllOptions[rOption].nTotalScore 
                                rBestOption = rOption
                                -- For now, I'm setting a restriction that Satisfiers should only return <=0 utility.
                                -- The idea is to see a Satisfier as a cost to the desired task, not as an added
                                -- benefit, which would run the risk of trying to turn this into GOAP while insufficiently
                                -- costing the additional time cost of the intermediate activities.
                                assert(nBestScore <= 0)
                            end
                        end
                    end
                end
            end

            if not nBestScore then
                tOptionEntry.bPrereqsValid = false
                tOptionEntry.bFullyValid = false
                tOptionEntry.sReason = 'Failed prereq: '..k
                return
            end

            if not tOptionEntry.tSatisfiers then tOptionEntry.tSatisfiers = {} end
            table.insert(tOptionEntry.tSatisfiers, rBestOption)
            nPrereqScore = nPrereqScore+nBestScore
            if rBestOption:overridesPathTest() then
                tOptionEntry.bOverridePathTest = true
            end
        
            local nOverrideStartWX,nOverrideStartWY,reason = rBestOption:getPathStartOverride(rChar)
            if nOverrideStartWX then        
                tOptionEntry.nOverrideStartWX, tOptionEntry.nOverrideStartWY = nOverrideStartWX,nOverrideStartWY
            elseif reason then
                tOptionEntry.bPrereqsValid = false
                tOptionEntry.bFullyValid = false
                tOptionEntry.sReason = 'Prereq: '..k..'; '..reason
                return
            end
        end
    end

    tOptionEntry.bPrereqsValid = true

    -- Perform final scoring.
    tOptionEntry.bFullyValid = UtilityAI._fillInLateGates(rChar,tOptionEntry)
    -- Bail early on already-failed options.
    if not tOptionEntry.bFullyValid then 
        return 
    end

    tOptionEntry.nTotalScore = tOptionEntry.nRealScore + nPrereqScore
end
        

function UtilityAI._fillInLateGates(rChar,tOptionEntry)
    if tOptionEntry.bLateGatesValid ~= nil then
        return tOptionEntry.bLateGatesValid 
    end

    local bValid, sReason = tOptionEntry.rOption:lateGates(rChar, tOptionEntry.bOverridePathTest, tOptionEntry.nOverrideStartWX, tOptionEntry.nOverrideStartWY)
    tOptionEntry.bLateGatesValid = bValid

    if bValid then
        local nScore = tOptionEntry.rOption:getRealScore(rChar)
        tOptionEntry.nRealScore = nScore
    else
        tOptionEntry.sReason = sReason
    end
    return bValid
end

function UtilityAI._getScoreStr(tOptionData) --option,utility,reason)
    -- print each option on a single line
    local rOption = tOptionData.rOption
    local scoreStr = rOption.name
    -- if option has an associated object / location, include that
    local targetName = getOptionTargetName(rOption)
    if targetName then
        scoreStr = scoreStr .. ' @ ' .. targetName
    end
    if tOptionData.nTotalScore or tOptionData.nMaxScore then
        -- list need fulfillments offered
        scoreStr = scoreStr .. ' ('
        local bSnip = false
        for k,v in pairs(rOption.tBlackboard.tAdvertisedNeeds) do
            bSnip = true
            scoreStr = scoreStr .. k .. '='..v..', '
        end
        -- snip last comma
        scoreStr = string.sub(scoreStr, 1, -3) .. ')'
    end
    -- pad so that scores line up for easier reading
    scoreStr = MiscUtil.padString(scoreStr, #'ExtinguishFireBareHanded' + 15)
    if tOptionData.nTotalScore then
        scoreStr = scoreStr .. ': ' .. string.format('%.3f', tOptionData.nTotalScore ) .. ' total '
    elseif tOptionData.nMaxScore then
        scoreStr = scoreStr .. ': ' .. string.format('%.3f', tOptionData.nMaxScore ) .. ' max   '
    else
        scoreStr = scoreStr .. ': ' .. string.format('%.3f', 0 ) .. ' gated '
    end
    scoreStr = MiscUtil.padString(scoreStr, #scoreStr + 6)
    if tOptionData.sReason then
        scoreStr = scoreStr .. ' reason: ' .. tOptionData.sReason 
    end
    return scoreStr
end

return UtilityAI
