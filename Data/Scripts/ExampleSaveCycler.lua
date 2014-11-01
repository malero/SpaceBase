local GameRules=require('GameRules')
local ExampleSaveCycler = {}

local DFSaveLoad = require("DFCommon.SaveLoad")

local EXAMPLE_SAVES = {
    Demo={
		'JP_CoolBase4b',
        'JakeBaseWithBrig',
        'JP_CoolBase1d',
		'JP_CoolBase3c',
		'JP_CoolBase2a',
    },
    Perf={
        "a_bunch_of_16x16_rooms",
        'Hateren47_megabase',
        'KillerB_megabase',
        "51people",
        "4_16x16_rooms_full_of_civies",
        "bunch_of_doors",
        "snoop_doggs_dream_base",
    },
}

function ExampleSaveCycler.nextSave(sType)
    sType = sType or 'Demo'
    if nil == ExampleSaveCycler.nSave then
        ExampleSaveCycler.nSave = 1
    end

    ExampleSaveCycler.nSave = ExampleSaveCycler.nSave + 1

    if ExampleSaveCycler.nSave > #EXAMPLE_SAVES[sType] then
        ExampleSaveCycler.nSave = 1
    end

    -- load the save file from the data dir
    GameRules.loadGame("Data/ExampleSaves/" .. EXAMPLE_SAVES[sType][ExampleSaveCycler.nSave] .. ".sav", true)
    GameRules.startLoop()
end

return ExampleSaveCycler
