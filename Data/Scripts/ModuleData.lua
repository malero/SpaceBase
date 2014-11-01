local Character=require('CharacterConstants')
local MiscUtil=require('MiscUtil')
local DFUtil = require('DFCommon.Util')

local t=
{
    editMode=
    {
        editMode={},
    },
    startingModules=
    {
        space = {
            shipsWithCrew="emptySpace",
            weight = 1,
        },
    },
    tutorialModules=
    {
        easyMode = {
            shipsWithCrew="easyMode",
            weight = 1,
        },
    },

    asteroidModules=
    {
        asteroid01={weight=1, filename="asteroid01",},
        asteroid02={weight=2, filename="asteroid02",},
        asteroid03={weight=2, filename="asteroid03",},
        asteroid04={weight=3, filename="asteroid04",},
        asteroid05={weight=2, filename="asteroid05",},
        asteroid06={weight=3, filename="asteroid06",},
        asteroid07={weight=2, filename="asteroid07",},
        asteroid08={weight=2, filename="asteroid08",},
        asteroid09={weight=1, filename="asteroid09",},
        asteroid10={weight=4, filename="asteroid10",},
        asteroid11={weight=1, filename="asteroid11",},
        asteroid12={weight=2, filename="asteroid12",},
        asteroid13={weight=2, filename="asteroid13",},
        asteroid14={weight=3, filename="asteroid14",},
        asteroid15={weight=2, filename="asteroid15",},
        asteroid16={weight=3, filename="asteroid16",},
        asteroid17={weight=2, filename="asteroid17",},
    },

    immigrationEvents=
    {
        basicImmigration={},
    },
	
    hostileImmigrationEvents=
    {
        hostileImmigration={},
    },
	
    friendlyDerelictEvents=
    {
        tinycross1Friendly={ shipsWithCrew='tinycross1Friendly', weight=1, difficulty=0 },
        tinycross2Friendlies={ shipsWithCrew='tinycross2Friendlies', weight=1, difficulty=0 },
        dualdomeFriendlies={ shipsWithCrew='dualdomeFriendlies', weight=1, difficulty=0.15 },
        donutFriendlies={ shipsWithCrew='donutFriendlies', weight=1, difficulty=0.15 },
        minerFriendlies={ shipsWithCrew='minerFriendlies', weight=1, difficulty=0 },
        tetriFriendlies={ shipsWithCrew='tetriFriendlies', weight=1, difficulty=0.4 },
        friendlyFreighter={ shipsWithCrew='friendlyFreighter', weight=1, difficulty=0.3 },
    },
    hostileDerelictEvents=
    {
		tinycross1Monster={ shipsWithCrew='tinycross1Monster', weight=1, difficulty=0 },
		tinycross1Hostile={ shipsWithCrew='tinycross1Hostile', weight=1, difficulty=0 },
		tinycross2Hostiles={ shipsWithCrew='tinycross2Hostiles', weight=1, difficulty=0.1 },
		dualdomeHostiles={ shipsWithCrew='dualdomeHostiles', weight=1, difficulty=0.4 },
		donutHostiles={ shipsWithCrew='donutHostiles', weight=1, difficulty=0.4 },
		KillbotCube={ shipsWithCrew='KillbotCube', weight=1, difficulty=0.5 },
		monsterFreighter={ shipsWithCrew='monsterFreighter', weight=1, difficulty=0.25 },
		enemyUFO={ shipsWithCrew='enemyUFO', weight=1, difficulty=0.25 },
	},
	
    -- Can be used in the shipsWithCrew table below.
    characterSpawns={
        -- FRIENDLIES
        AllRandom={ nFactionBehavior=Character.FACTION_BEHAVIOR.Friendly, },
        Friendly={ nFactionBehavior=Character.FACTION_BEHAVIOR.Friendly, },
        FriendlyNoItems={ nFactionBehavior=Character.FACTION_BEHAVIOR.Friendly, bNoStuff=true },
        Settler={ 
            nFactionBehavior=Character.FACTION_BEHAVIOR.Citizen, 
            tStatus={bBaseFounder=true,
					 bImmuneToParasite=true,
					 nMorale=50},
            tNeeds={Energy=80,Hunger=80},
        },
        SpacewalkingSettler={ 
            nFactionBehavior=Character.FACTION_BEHAVIOR.Citizen, 
            tStatus={bSpacewalking=true,
					 bBaseFounder=true,
					 bImmuneToParasite=true,
					 nMorale=50},
            tNeeds={Energy=80,Hunger=80},
        },
		Spacewalker={ 
            nFactionBehavior=Character.FACTION_BEHAVIOR.Friendly, 
            tStatus={bSpacewalking=true},
        },
        Human={ 
            nFactionBehavior=Character.FACTION_BEHAVIOR.Friendly, 
            tStats={nRace=Character.RACE_HUMAN},
        },
        Jelly={ 
            nFactionBehavior=Character.FACTION_BEHAVIOR.Friendly, 
            tStats={nRace=Character.RACE_JELLY},
        },

        -- HOSTILES
        Monster={ 
            nFactionBehavior=Character.FACTION_BEHAVIOR.EnemyGroup,
            tStats={
                nRace = Character.RACE_MONSTER,
                sName = 'Monster',
            },
        },
        KillBot={ 
            nFactionBehavior=Character.FACTION_BEHAVIOR.EnemyGroup,
            tStats={
                nRace = Character.RACE_KILLBOT,
                sName = 'Kill Bot',
            },
        },
        Raider={
            nFactionBehavior=Character.FACTION_BEHAVIOR.EnemyGroup,
            tStats={
                sName = 'Raider',
                nJob = Character.RAIDER,
            },
        },

        -- CORPSES
        DeadRandom={
			tStatus={
				health = Character.STATUS_DEAD,
				nDeathCause = Character.COMBAT_RANGED,
			},
		},
    },
	-- for spawning (envobject and non-envobject) stuff on ships
	objectSpawns={
		Datacube={ bInvItem=true, sTemplate='ResearchDatacube' },
		RandomStuff={ bInvItem=true, },
		TurretV1={ sType='WallMountedTurret' },
	},
	
    -- file + crew. these layouts are used by derelicts, boarders, etc.
    shipsWithCrew=
    {
        ----------------------------------------------
        -- STARTING SHIP LAYOUTS
        ----------------------------------------------
        easyMode=
        {
            filename="Box",
            crew={
                Oxygen1={Settler=1},
                Hall1={Settler=1},
                Hall2={Settler=1},
                Hall3={Settler=1},
                Power1={Settler=1},
            },
        },
		
		emptySpace=
		{
			filename="DeepSpace",
			crew={
				Citizen1={SpacewalkingSettler=1},
                Citizen2={SpacewalkingSettler=1},
                Citizen3={SpacewalkingSettler=1},
            },
		},

        ----------------------------------------------
        -- BOARDING aka docking LAYOUTS
        ----------------------------------------------
        planeBoardingFriendly=
        {
            filename="lilplane",
            crew={
                Hall1={AllRandom=1},
                Hall2={AllRandom=1},
            },
			objects={
				HallData1={Datacube=1, Nothing=2},
			},
        },
        planeBoardingHostile=
        {
            bHostile=true,
            filename="lilplane",
            crew={
                Hall1={Raider=1},
                Hall2={Raider=1},
            },
			objects={
				HallData1={Datacube=1, Nothing=1},
				Ext1={TurretV1=1, Nothing=1},
			},
        },
        tinycross1BoardingFriendly=
        {
            filename="tinycross1",
            crew={
                Bedroom1={AllRandom=1},
                Oxygen1={AllRandom=1},
            },
			objects={
				HallData1={Datacube=1, Nothing=2},
			},
        },
        tinycross1BoardingHostile=
        {
            bHostile=true,
            filename="tinycross1",
            crew={
                Bedroom1={Raider=1},
                Oxygen1={Raider=1},
            },
			objects={
				HallData1={Datacube=1, Nothing=1},
			},
        },
        tinycross2BoardingFriendly=
        {
            filename="tinycross2",
            crew={
                Oxygen1={AllRandom=3,Nobody=1},
                Oxygen2={AllRandom=2,Nobody=1},
                Hall1={AllRandom=1},
            },
        },
        tinycross2BoardingHostile=
        {
            bHostile=true,
            filename="tinycross2",
            crew={
                Oxygen1={Raider=2,DeadRandom=1},
                Oxygen2={Raider=1},
                Hall1={Raider=1},
            },
        },
        wingshipFriendly=
        {
            filename="wingship1",
            crew={
                Resi1={AllRandom=3,Nobody=1},
                Garden1={AllRandom=2,Nobody=1},
                Life1={AllRandom=1},
            },
			objects={
				HallData1={Datacube=1, Nothing=2},
			},
        },
        wingshipHostile=
        {
            bHostile=true,
            filename="wingship1",
            crew={
                Resi1={Raider=3,DeadRandom=1},
                Garden1={Raider=2,DeadRandom=1},
                Life1={Raider=1},
            },
			objects={
				HallData1={Datacube=1, Nothing=1},
				HullTurret={TurretV1=1, Nothing=1},
			},
        },
        dualdomeBoardingFriendly=
        {
            filename="dualdome2",
            crew={
                Garden1={AllRandom=5,Nobody=1},
                Garden2={AllRandom=2,Nobody=1},
                Entry={AllRandom=3,Nobody=1},
                Resi1={AllRandom=5,Nobody=1},
                Resi2={AllRandom=2,Nobody=1},
            },
			objects={
				GardenData1={Datacube=1, Nothing=2},
			},
        },
        dualdomeBoardingHostile=
        {
            bHostile=true,
            filename="dualdome2",
            crew={
                Garden1={Raider=5,DeadRandom=1},
                Garden2={Raider=2,DeadRandom=1},
                Entry={Raider=3,DeadRandom=1},
                Resi1={Raider=5,DeadRandom=1},
                Resi2={Raider=2,DeadRandom=1},
            },
			objects={
				GardenData1={Datacube=1, Nothing=1},
				Ext1={TurretV1=1, Nothing=1},
				Ext2={TurretV1=1, Nothing=1},
			},
        },

        ----------------------------------------------
        -- DERELICT LAYOUTS
        ----------------------------------------------
        monsterFreighter=
        {
            bHostile=true,
            filename="freighter1",
            crew={
                Hall1={Monster=1, DeadRandom=1,},
                Hall2={Monster=1, DeadRandom=1,},
                Resi1={Monster=1,},
            },
			objects={
				CargoData1={Datacube=1, Nothing=1},
			},
        },
        friendlyFreighter=
        {
            filename="freighter1",
            crew={
                Hall1={AllRandom=1, Nobody=0,},
                Hall2={AllRandom=1, Nobody=0,},
                Resi1={AllRandom=1, Nobody=0,},
            },
			objects={
				CargoData1={Datacube=1, Nothing=2},
			},
        },
        enemyUFO=
        {
            bHostile=true,
            filename="ufo",
            crew={
                Hall1={ Raider=1 },
                Hall2={ Raider=1, Nobody=1 },
                Lab1={ Raider=1 },
                Lab2={ Raider=1 , Nobody=1 },
                Reac1={ Raider=1 },
                Reac2={ Raider=1 , Nobody=1 },
            },
			objects={
				Data1={Datacube=1},
			},
        },
        tinycross1Friendly=
        {
            filename="tinycross1",
            crew={
                Entry1={ AllRandom=1, Nobody=1},
                Resi1={ AllRandom=1, },
                Resi2={ AllRandom=1, },
            },
			objects={
				HallData1={Datacube=1, Nothing=2},
			},
        },
        tinycross1Monster=
        {
            bHostile=true,
            filename="tinycross1",
            crew={
                Entry1={ Monster=1, KillBot=1, },
                Resi1={ DeadRandom=1, },
                Resi2={ DeadRandom=2, Nothing=1, },
            },
			objects={
				HallData1={Datacube=1, Nothing=1},
			},
        },
        tinycross1Hostile=
        {
            bHostile=true,
            filename="tinycross1",
            crew={
                Entry1={ Raider=3, DeadRandom=1 },
                Resi1={ Raider=2, DeadRandom=1 },
                Resi2={ Raider=1, },
            },
			objects={
				HallData1={Datacube=1, Nothing=1},
			},
        },
        tinycross2Hostiles=
        {
            bHostile=true,
            filename="tinycross2",
            crew={
                Oxygen1={ Raider=3, DeadRandom=1 },
                Oxygen2={ Raider=2, DeadRandom=1 },
                Hall1={ Raider=1, Nobody=1 },
            },
        },
        tinycross2Friendlies=
        {
            filename="tinycross2",
            crew={
                Oxygen1={ Friendly=3, Nobody=1 },
                Oxygen2={ Friendly=2, Nobody=1 },
                Hall1={ Friendly=1, Nobody=1 },
            },
        },
        dualdomeFriendlies=
        {
            filename="dualdome2",
            crew={
                Garden1={AllRandom=5,Nobody=1},
                Garden2={AllRandom=2,Nobody=1},
                Entry={AllRandom=3,Nobody=1},
                Resi1={AllRandom=5,Nobody=1},
                Resi2={AllRandom=2,Nobody=1},
            },
			objects={
				GardenData1={Datacube=1, Nothing=2},
			},
        },
        dualdomeHostiles=
        {
            bHostile=true,
            filename="dualdome2",
            crew={
                Garden1={Raider=5,DeadRandom=1},
                Garden2={Raider=2,DeadRandom=1},
                Entry={Raider=3,Nobody=1},
                Resi1={Raider=5,DeadRandom=1},
                Resi2={Raider=2,DeadRandom=1},
            },
			objects={
				GardenData1={Datacube=1, Nothing=1},
				Ext1={TurretV1=1, Nothing=1},
				Ext2={TurretV1=1, Nothing=1},
			},
        },
		donutFriendlies=
        {
            filename="SpaceDonut1",
            crew={
                Resi1={ Friendly=1, Nobody=1 },
                Reactor1={ Friendly=1, Nobody=1 },
                Reactor2={ Friendly=1, Nobody=0.5 },
                LifeSup1={ Friendly=1, Nobody=0.5 },
                Garden1={ Friendly=1, Nobody=1 },
            },
			objects={
				ReacData1={Datacube=1, Nothing=2},
			},
        },
		donutHostiles=
        {
            filename="SpaceDonut1",
            bHostile=true,
            crew={
                Resi1={ Monster=1, Nobody=2 },
                Reactor1={ Monster=1, Nobody=1 },
                Reactor2={ Monster=1, Nobody=0.5 },
                LifeSup1={ Raider=1, Nobody=0.5 },
                Garden1={ Monster=1, Nobody=2 },
            },
			objects={
				ReacData1={Datacube=1, Nothing=1},
				ReacTurret1={TurretV1=1, Nothing=3},
			},
        },
		KillbotCube=
		{
			filename="killbot1",
			bHostile=true,
			crew={
				Box1={ KillBot=1, Nobody=1 },
				Box2={ KillBot=2, Nobody=1 },
				Box3={ KillBot=3, Nobody=1 },
				Box4={ KillBot=2, Nobody=1 },
				Box5={ KillBot=1, Nobody=1 },
			},
			objects={
				Box5={Datacube=1, Nothing=1},
				Ext1={TurretV1=1, Nothing=1},
				Ext2={TurretV1=2, TurretV2=1, Nothing=1},
				Ext3={TurretV1=1, Nothing=1},
			},
		},
		minerFriendlies=
        {
            filename="MiningPlatform1",
            crew={
                Resi1={ Friendly=1, Nobody=0.25 },
                Reactor1={ Friendly=1, Nobody=0.25 },
            },
        },
		tetriFriendlies=
        {
            filename="Tetricluster",
            crew={
                LS={ Friendly=1, Nobody=2 },
                Hall1={ Friendly=1, Nobody=1 },
                Hall2={ Friendly=1, Nobody=2 },
                Garden={ Friendly=1, Nobody=0.5 },
                Reac={ Friendly=1, Nobody=1 },
                Resi={ Friendly=1, Nobody=1 },
                Pub={ Friendly=1, Nobody=0 },
            },
			objects={
				PubData1={Datacube=1, Nothing=1},
			},
        },
    },

    -- DOCKING
    friendlyDockingEvents=
    {
        planeBoardingFriendly={ shipsWithCrew='planeBoardingFriendly', weight=1, difficulty=0 },
        tinycross1BoardingFriendly={ shipsWithCrew='tinycross1BoardingFriendly', weight=1, difficulty=0.1 },
        tinycross2BoardingFriendly={ shipsWithCrew='tinycross2BoardingFriendly', weight=1, difficulty=0.25 },
        dualdomeBoardingFriendly={ shipsWithCrew='dualdomeBoardingFriendly', weight=1, difficulty=0.25 },
        donutFriendlies={ shipsWithCrew='donutFriendlies', weight=1, difficulty=0.1 },
        tetriFriendlies={ shipsWithCrew='tetriFriendlies', weight=.5, difficulty=0.4 },
        wingshipFriendly={ shipsWithCrew='wingshipFriendly', weight=1, difficulty=0.25 },
    },
    hostileDockingEvents=
    {
        planeBoardingHostile={ shipsWithCrew='planeBoardingHostile', weight=1, difficulty=0 },
        tinycross1BoardingHostile={ shipsWithCrew='tinycross1BoardingHostile', weight=1, difficulty=0 },
        tinycross2BoardingHostile={ shipsWithCrew='tinycross2BoardingHostile', weight=1, difficulty=0.1 },
        dualdomeBoardingHostile={ shipsWithCrew='dualdomeBoardingHostile', weight=1, difficulty=0.35 },
        donutHostiles={ shipsWithCrew='donutHostiles', weight=1, difficulty=0.25 },
        KillbotCube={ shipsWithCrew='KillbotCube', weight=2, difficulty=0.5 },
        wingshipHostile={ shipsWithCrew='wingshipHostile', weight=1, difficulty=0 },
    },
}

return t
