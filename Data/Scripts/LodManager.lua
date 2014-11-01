local LodManager = {}

LodManager.tLodProfiles = {
    ["very_low"] = { 
        tSceneLods = {
            "ambient_low",
            "gameplay_low",
        },
        tShaderLods = {
            tFlagOverrides = {
                ["g_bGradientLighting"] = false,
                ["g_bRimLighting"] = false,
            },
        },
    },
    
    ["low"] = { 
        tSceneLods = {
            "ambient_low",
            "gameplay_medium",
        },
        tShaderLods = {
            tFlagOverrides = {
                ["g_bRimLighting"] = false,
            },
        },
    },
    
    ["medium"] = { 
        tSceneLods = {
            "ambient_medium",
            "gameplay_medium",
        },
        tShaderLods = {
            tFlagOverrides = {
                ["g_bRimLighting"] = false,
            },
        },
    },
    
    ["high"] = { 
        tSceneLods = {
            "ambient_medium",
            "gameplay_high",
        },
    },
    
    ["very_high"] = { 
        tSceneLods = {
            "ambient_high",
            "gameplay_high",
        },
    },
}

LodManager.tAcceptedSceneLods = {}

function LodManager.clearSceneLods()

    LodManager.tAcceptedSceneLods = {}
end

function LodManager.addSceneLod(sLodName, bEnabled)

    bEnabled = bEnabled or true
    LodManager.tAcceptedSceneLods[sLodName] = bEnabled
end

function LodManager.applyLodProfile(sName)

    local tProfile = LodManager.tLodProfiles[sName]
    assert(tProfile ~= nil)

    -- Reset the scene-LODs
    LodManager.clearSceneLods()
    
    -- Add scene LODs
    LodManager.addSceneLod("default")
    
    for _, sLod in ipairs(tProfile.tSceneLods) do
        LodManager.addSceneLod(sLod)
    end
    
    -- Reset shader LODSs
    MOAIShaderMgr.clearPermutationFlagOverrides()
    MOAIShaderMgr.clearPermutationSwitchOverrides()
    
    -- Set shader LODs
    if tProfile.tShaderLods ~= nil then
    
        local tFlagOverrides = tProfile.tShaderLods.tFlagOverrides
        if tFlagOverrides ~= nil then
            for sFlagName, bIsEnabled in pairs(tFlagOverrides) do
                MOAIShaderMgr.setPermutationFlagOverride(sFlagName, bIsEnabled)
            end
        end
        
        local tSwitchOverrides = tProfile.tShaderLods.tSwitchOverrides
        if tSwitchOverrides ~= nil then
            for sOptionName, sOverride in pairs(tSwitchOverrides) do
                MOAIShaderMgr.setPermutationSwitchOverride(sOptionName, sOverride)
            end
        end
    end
end

function LodManager.acceptExplicitSceneLod(sLodName)

    sLodName = sLodName or "default"
    if LodManager.tAcceptedSceneLods[sLodName] == true then
        return true
    end
    
    return false
end
    
function LodManager.acceptSceneLod(sLodName, sLodType)

    sLodName = sLodName or "default"
    if LodManager.acceptExplicitSceneLod(sLodName) then
        return true
    end
    
    -- The requested LOD wasn't found explicitly...
    sLodType = sLodType or "explicit"
    if sLodType ~= "explicit" and sLodName ~= "default" then
        
        -- ...so let's check if it's included in the selector
        local idxSeperator = string.find(sLodName, "_")
        if idxSeperator ~= nil then
        
            local sGroupName = string.sub(sLodName, 1, idxSeperator)
            
            local lodNameLength = #sLodName
            local sCurType = string.sub(sLodName, idxSeperator + 1, lodNameLength)
            
            -- Include LODs above the requested one?
            if sLodType == "include_higher" then
            
                if sCurType == "low" then
                    if LodManager.acceptExplicitSceneLod(sGroupName .. "medium") then return true end
                    if LodManager.acceptExplicitSceneLod(sGroupName .. "high") then return true end
                elseif sCurType == "medium" then
                    if LodManager.acceptExplicitSceneLod(sGroupName .. "high") then return true end
                end
            
            -- Include LODs below the requested one?
            elseif sLodType == "include_lower" then
            
                if sCurType == "high" then
                    if LodManager.acceptExplicitSceneLod(sGroupName .. "medium") then return true end
                    if LodManager.acceptExplicitSceneLod(sGroupName .. "low") then return true end
                elseif sCurType == "medium" then
                    if LodManager.acceptExplicitSceneLod(sGroupName .. "low") then return true end
                end
            end
        end
    end
    
    return false
end

return LodManager
