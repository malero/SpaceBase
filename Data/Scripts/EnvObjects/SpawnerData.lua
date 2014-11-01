local Character=require('CharacterConstants')
local SpawnerData = {}

SpawnerData.tSpawners =
{
    AllRandom={},
    Human={ tStats={nRace=Character.RACE_HUMAN}},
    Jelly={ tStats={nRace=Character.RACE_JELLY}},

    -- bodies.
    DeadRandom={ tStatus={health = Character.STATUS_DEAD}},
}

return SpawnerData

