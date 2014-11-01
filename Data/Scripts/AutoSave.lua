local AutoSave = {
    profilerName='AutoSave',
}
AutoSave.TIME_BETWEEN_AUTOSAVES = 90 -- in real-time seconds
AutoSave.LOG = true
local GameRules=nil
local EventController=nil
local DFUtil=require('DFCommon.Util')

function AutoSave.init()    
    GameRules=require('GameRules')
    EventController=require('EventController')
    AutoSave.nTimeSinceLastSave = (AutoSave.nTimeSinceLastSave or 0)

    -- Fix file case of save name.
    if MOAIEnvironment.osBrand == "Linux" then
        local dir = MOAIEnvironment.documentDirectory .. '/Saves/'
        local filename = GameRules.sAutoSaveFile .. '.sav'
        local newName = DFUtil.findFileCase(dir, filename)
        if newName then
            newName = string.sub(newName, 1, #newName - 4)
            Trace(TT_Warning, "Adjusting case of auto save from %s to %s", filename, newName)
            GameRules.sAutoSaveFile = newName
        end
    end
end

function AutoSave.onTick(dt)
    if GameRules.inEditMode or GameRules.playerTimeScale == 0 then return end
    if not g_Config:getConfigValue("autosave") and not GameRules.bQueuedSave then return end
    
    AutoSave.nTimeSinceLastSave = (AutoSave.nTimeSinceLastSave or 0) + dt
    if GameRules.bQueuedSave or AutoSave.nTimeSinceLastSave > AutoSave.TIME_BETWEEN_AUTOSAVES then
        GameRules.bQueuedSave = nil
        AutoSave.saveGame()
    end
end

function AutoSave.saveGame()
    if GameRules.inEditMode or GameRules.playerTimeScale == 0 or not g_Config:getConfigValue("autosave") then 
        return 
    end
    if EventController.tCurrentEventPersistentState then 
        print('postponing autosave until after event')
        return 
    end
    
        if AutoSave.LOG then print("Autosaving...") end
        require('GameRules').saveGame()
        AutoSave.nTimeSinceLastSave = 0
end

return AutoSave
