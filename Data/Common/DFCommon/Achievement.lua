local DFSaveLoad = require('DFCommon.SaveLoad')
local DFUtil = require('DFCommon.Util')

local m = {
    sSaveFilename = 'Achievement',
    tAchievementTable = {},
}

-- setupAchievements
-- Initializes the achievements system, including per-platform
-- achievement backend (i.e. GameCenter on iOS)
--
-- tAchievementInfoTable: Defines the set of achievements.
-- achievement info table structure                         
-- UniqueKey = {
--                 type = <achievement type>, -- string value of the type of achievement.  it can be
--                                            -- 'progressive':total up to a number to unlock the achievement
--                                            -- 'uniquekeys':unique keys to total up to a number to unlock the achievement
--                 nNumRequired = <num required>, -- the total numer accumulated in order to unlock the achievement
--             }
-- e.g.
--    WinTenFights = {
--                       type = 'progressive',
--                       nNumRequired = 10,
--                   },
--    RecruitAllHeroes = {
--                           type = 'uniquekeys',
--                           nNumRequired = 3,
--                       },
--
function m.init(tAchievementInfoTable, tSaveTable)
    if not tAchievementInfoTable or not tSaveTable then
        Trace(TT_Error, "No Achievement info table passed")
        return
    end
    
    -- restore any progress we had from disk
    m.tAchievementTable = tSaveTable
    if m.tAchievementTable then        
        for key, value in pairs(tAchievementInfoTable) do
            if m.tAchievementTable[key] then
                -- update the existing values
                -- we're making the new stuff authoritative
                for tblKey, tblValue in pairs(value) do
                    if tblKey ~= 'nCurProgress' then -- safeguard. this should never be
                        m.tAchievementTable[key][tblKey] = DFUtil.deepCopy(tblValue)
                    end                    
                end
            else
                -- add the value
                m.tAchievementTable[key] = DFUtil.deepCopy(value)
            end
        end
    else
        -- create a new achievements save if we didn't have one.
        m.tAchievementTable = DFUtil.deepCopy(tAchievementInfoTable)
    end

    -- let's reprocess all achievements so that it is rewarded
    if m.tAchievementTable then
        for key, tAchievementInfo in pairs(m.tAchievementTable) do
            m._progressAchivement(tAchievementInfo, 0)
        end
    end                       
    
    if g_Game and g_Game.saveGame then
        g_Game:saveGame()
    end
    if MOAIEnvironment.osBrand == "iOS" then
        if MOAIGameCenterIOS then
            MOAIGameCenterIOS.authenticatePlayer()
        end
    end
end

-- updateAchievement
-- Indicates that the player has progressed a specific achievement.
-- Achievements much be included in the initial tAchievementInfoTable
--
-- sAchievementKey: The achievement id being unlocked.
-- achievementValue: The value of the progress, may be a string or number.
function m.updateAchievement(sAchievementKey, achievementValue)
    if not sAchievementKey then
        Trace(TT_Error, "No achievement key passed")
        return
    end
    if not m.tAchievementTable then
        Trace(TT_Error, "No achievement table loaded")
        return
    end
    if not m.tAchievementTable[sAchievementKey] then
        Trace(TT_Error, "Invalid Achievement"..sAchievementKey)
        return
    end
    local tAchievementInfo = m.tAchievementTable[sAchievementKey]
    if not tAchievementInfo.bIsCompleted then
        if not tAchievementInfo.nCurProgress then
            tAchievementInfo.nCurProgress = 0
        end
        if tAchievementInfo.type == 'progressive' then            
            m._progressAchivement(tAchievementInfo, achievementValue)
        elseif tAchievementInfo.type == 'uniquekeys' then
            if not tAchievementInfo.tValues then
                tAchievementInfo.tValues = {}
            end
            if not tAchievementInfo.tValues[achievementValue] then
                tAchievementInfo.tValues[achievementValue] = 1
                m._progressAchivement(tAchievementInfo, 1)
            end
        else
            Trace(TT_Error, "Unknown Achievement type for "..sAchievementKey)
        end
    end
end

-- showAchievements
-- Displays the standard system UI for achievements
function m.showAchievements()
    if MOAIEnvironment.osBrand == "iOS" and MOAIGameCenterIOS.isSupported() then
        MOAIGameCenterIOS.showDefaultAchievements()
    end
end


-- Private functions

-- _progressAchivement
-- Updates the internal bookkeeping for an achievement, including
-- passing that status on to the platform specific tracking system.
--
-- tAchievementInfo: The table for the achievement being updated.
-- achievementVale: The amount to increase the progress.
function m._progressAchivement(tAchievementInfo, achievementValue)
    if not tAchievementInfo then
        return
    end
    if not tAchievementInfo.nCurProgress then
        tAchievementInfo.nCurProgress = 0
    end
    tAchievementInfo.nCurProgress = tAchievementInfo.nCurProgress + achievementValue
    local progress = (tAchievementInfo.nCurProgress / tAchievementInfo.nNumRequired) * 100
    progress = math.min(progress, 100)   
    if progress >= 100 then
        tAchievementInfo.bIsCompleted = true
    end

    -- Save progress of completed achievements
    if g_Game and g_Game.saveGame then
        g_Game:saveGame()
    end
    if MOAIEnvironment.osBrand == "iOS" and MOAIGameCenterIOS then
        MOAIGameCenterIOS.reportAchievementProgress(tAchievementInfo.sGameCenterKey, progress)
    end    
    if tAchievementInfo.nCurProgress >= tAchievementInfo.nNumRequired then        
        Trace(TT_Info, "ACHIEVEMENT UNLOCKED: "..tAchievementInfo.sGameCenterKey)
    end
end

return m
