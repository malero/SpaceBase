local t=
{
	-- Malero Research Mods
	LockdownLevel1=
	{
		sName='MALERORESRCH0001L1TEXT',
        sDesc='MALERORESRCH0001L1DESC',
		tPrereqs={},
	    nResearchUnits=750,
		sIcon = 'ui_jobs_iconJobResponse',
	},
	LockdownLevel2=
	{
		sName='MALERORESRCH0001L2TEXT',
        sDesc='MALERORESRCH0001L2DESC',
		tPrereqs={'LockdownLevel1'},
	    nResearchUnits=1500,
		nPoisonDamage=2,
		sIcon = 'ui_jobs_iconJobResponse',
	},
	LockdownLevel3=
	{
		sName='MALERORESRCH0001L3TEXT',
        sDesc='MALERORESRCH0001L3DESC',
		tPrereqs={'LockdownLevel2'},
	    nResearchUnits=2250,
		nPoisonDamage=4,
		nConvertChance=0.005,
		sIcon = 'ui_jobs_iconJobResponse',
	},
	LockdownLevel4=
	{
		sName='MALERORESRCH0001L4TEXT',
        sDesc='MALERORESRCH0001L4DESC',
		tPrereqs={'LockdownLevel3'},
	    nResearchUnits=3000,
		nPoisonDamage=6,
		nConvertChance=0.01,
		sIcon = 'ui_jobs_iconJobResponse',
	},
	LockdownLevel5=
	{
		sName='MALERORESRCH0001L5TEXT',
        sDesc='MALERORESRCH0001L5DESC',
		tPrereqs={'LockdownLevel4'},
	    nResearchUnits=3750,
		sIcon = 'ui_jobs_iconJobResponse',
	},
	PortableIncinerator=
	{
		sName='MALERORESRCH0002TEXT',
        sDesc='MALERORESRCH0002DESC',
		tPrereqs={},
	    nResearchUnits=1500,
		sIcon = 'ui_jobs_iconJobDoctor',
	},
	MaintenanceToolsLevel1=
	{
		sName='MALERORESRCH0003L1TEXT',
        sDesc='MALERORESRCH0003L1DESC',
		tPrereqs={},
	    nResearchUnits=1000,
		nCriticalChance=0.1,
		sIcon = 'ui_jobs_iconJobTechnician',
	},
	MaintenanceToolsLevel2=
	{
		sName='MALERORESRCH0003L2TEXT',
        sDesc='MALERORESRCH0003L2DESC',
		tPrereqs={
			'MaintenanceToolsLevel1',
		},
	    nResearchUnits=2000,
		nCriticalChance=0.2,
		sIcon = 'ui_jobs_iconJobTechnician',
	},
	MaintenanceToolsLevel3=
	{
		sName='MALERORESRCH0003L3TEXT',
        sDesc='MALERORESRCH0003L3DESC',
		tPrereqs={
			'MaintenanceToolsLevel2',
		},
	    nResearchUnits=3000,
		nCriticalChance=0.3,
		sIcon = 'ui_jobs_iconJobTechnician',
	},
	HumanResourcesLevel1=
	{
		sName='MALERORESRCH0004L1TEXT',
	    sDesc='MALERORESRCH0004L1DESC',
		tPrereqs={},
	    nResearchUnits=1000,
		nTransmissionSuccess=0.2,
		sIcon = 'ui_jobs_iconJobTechnician',
	},
	HumanResourcesLevel2=
	{
		sName='MALERORESRCH0004L2TEXT',
	    sDesc='MALERORESRCH0004L2DESC',
		tPrereqs={
			'HumanResourcesLevel1'
		},
	    nResearchUnits=2000,
		nTransmissionSuccess=0.3,
		sIcon = 'ui_jobs_iconJobTechnician',
	},
	HumanResourcesLevel3=
	{
		sName='MALERORESRCH0004L3TEXT',
	    sDesc='MALERORESRCH0004L3DESC',
		tPrereqs={
			'HumanResourcesLevel2'
		},
	    nResearchUnits=3000,
		nTransmissionSuccess=0.4,
		sIcon = 'ui_jobs_iconJobTechnician',
	},
	HumanResourcesLevel4=
	{
		sName='MALERORESRCH0004L3TEXT',
	    sDesc='MALERORESRCH0004L3DESC',
		tPrereqs={
			'HumanResourcesLevel3'
		},
	    nResearchUnits=4000,
		nTransmissionSuccess=0.5,
		sIcon = 'ui_jobs_iconJobTechnician',
	},
	-- DF Research
    VaporizeLevel2=
    {
        sName='RESRCH001TEXT',
        sDesc='RESRCH002TEXT',
        tPrereqs={},
        nResearchUnits=1200,
		sIcon = 'ui_jobs_iconJobBuilder',
    },
    MaintenanceLevel2=
    {
        sName='RESRCH009TEXT',
        sDesc='RESRCH010TEXT',
        tPrereqs={'MaintenanceLevel2Discovered'},
        nResearchUnits=1200,
        nConditionMultiplier=1.5,
		sIcon = 'ui_jobs_iconJobTechnician',
    },	
    BuildLevel2=
    {
        sName='RESRCH011TEXT',
        sDesc='RESRCH012TEXT',
        tPrereqs={},
        nResearchUnits=1000,
		sIcon = 'ui_jobs_iconJobBuilder',
    },
    PlantLevel2=
    {
        sName='RESRCH013TEXT',
        sDesc='RESRCH014TEXT',
        tPrereqs={},
        nResearchUnits=1000,
        nConditionMultiplier=2,
		sIcon = 'ui_jobs_iconJobBotanist',
    },
    LaserRifles=
    {
        sName='RESRCH003TEXT',
        sDesc='RESRCH004TEXT',
        tPrereqs={},
        nResearchUnits=1100,
		sIcon = 'ui_jobs_iconJobResponse',
    },
    ArmorLevel2=
    {
        sName='RESRCH005TEXT',
        sDesc='RESRCH006TEXT',
        tPrereqs={},
        nResearchUnits=900,
		sIcon = 'ui_jobs_iconJobResponse',
    },
    TeamTactics=
    {
        sName='RESRCH017TEXT',
        sDesc='RESRCH018TEXT',
        tPrereqs={'TeamTacticsDiscovered'},
        nResearchUnits=2000,
		sIcon = 'ui_jobs_iconJobResponse',
    },
    OxygenRecyclerLevel2=
    {
		-- sItemForDesc corresponds with an EnvObjectData entry
        sItemForDesc='OxygenRecyclerLevel2',
        tPrereqs={'AirScrubber'},
        nResearchUnits=1000,
		sIcon = 'ui_jobs_iconJobUnemployed',
    },
    GeneratorLevel2=
    {
		-- sItemForDesc corresponds with an EnvObjectData entry
        sItemForDesc='GeneratorLevel2',
        tPrereqs={},
        nResearchUnits=1000,
		sIcon = 'ui_jobs_iconJobUnemployed',
    },
    AirScrubber=
    {
        sItemForDesc='AirScrubber',
        tPrereqs={},
        nResearchUnits=750,
		sIcon = 'ui_jobs_iconJobDoctor',
    },
    DoorLevel2=
    {
        sItemForDesc='HeavyDoor',
        tPrereqs={},
        nResearchUnits=1200,
    },
    FridgeLevel2=
    {
        sItemForDesc='FridgeLevel2',
        tPrereqs={'FridgeLevel2Discovered'},
        nResearchUnits=800,
		sIcon = 'ui_jobs_iconJobBarkeep',
    },
    RefineryDropoffLevel2=
    {
        sItemForDesc='RefineryDropoffLevel2',
        tPrereqs={},
        nResearchUnits=1200,
		sIcon = 'ui_jobs_iconJobMiner',
    },
	WallMountedTurret2=
    {
        sItemForDesc='WallMountedTurret2',
        --tPrereqs={'WallMountedTurret','WallMountedTurretLevel2Discovered'},
		tPrereqs={'WallMountedTurretLevel2Discovered'},
        nResearchUnits=2000,
		sIcon = 'ui_jobs_iconJobResponse',
    },
	-- "blueprints": unlock research, don't give you new tech by themselves
	FridgeLevel2Discovered=
    {
        sName='PROPSX069TEXT',
        sDesc='PROPSX068TEXT',
        tPrereqs={},
        nResearchUnits=1,
		bDiscoverOnly=true,
    },
	TeamTacticsDiscovered=
    {
        sName='RESRCH017TEXT',
        sDesc='RESRCH018TEXT',
        tPrereqs={},
        nResearchUnits=1,
		bDiscoverOnly=true,
    },
    MaintenanceLevel2Discovered=
    {
        sName='RESRCH009TEXT',
        sDesc='RESRCH010TEXT',
        tPrereqs={},
        nResearchUnits=1,
		bDiscoverOnly=true,
	},
    WallMountedTurretLevel2Discovered=
    {
        sName='PROPSX080TEXT',
        sDesc='PROPSX081TEXT',
        tPrereqs={},
        nResearchUnits=1,
		bDiscoverOnly=true,
	},
}

return t
