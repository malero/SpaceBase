local DFUtil = require('DFCommon.Util')
local Character = require('CharacterConstants')
local tAnimations = {}

tAnimations.sBasePath = 'Characters/Citizen_Base/Animations/'

tAnimations['walk'] = 
{
    sFilename='Citizen_Walk.anim',
}

tAnimations['walk_sad'] = 
{
    sFilename='Citizen_Walk_Sad.anim',
}

tAnimations['walk_happy'] = 
{
    sFilename='Citizen_Walk_Happy.anim',
}

tAnimations['walk_low_oxygen'] = 
{
    sFilename='Citizen_Walk_LowOxygen.anim',
}

tAnimations['interact'] = 
{
    sFilename='Citizen_Interact.anim',
}

tAnimations['tantrum'] = 
{
    sFilename='Citizen_Tantrum.anim',
}

tAnimations['walk_tantrum'] = 
{
    sFilename='Citizen_Tantrum_Run.anim',
    bUseRunSpeed=true,
}

tAnimations['sabotage_fists'] =
{
    sFilename='Citizen_SabotageMachine_Fists.anim',
}

tAnimations['sabotage_extinguisher'] =
{
    sFilename='Citizen_SabotageMachine_Extinguisher.anim',
}

tAnimations['maintain'] = 
{
    sFilename='Citizen_TechnicianMaintain.anim',
    sAccessory = 'Datapad',
}

tAnimations['build'] = 
{    
    sFilename = 'Citizen_BuilderConstruct.anim',
    sAccessory = 'Builder',
}

tAnimations['vaporize'] = 
{    
    sFilename='Citizen_BuilderVaporize.anim',
    sAccessory = 'Builder',
}

tAnimations['talk_greet'] = 
{
    tFilenames={
		'Citizen_Greet.anim',
	},
}

tAnimations['talk_introduce'] = 
{
    tFilenames={
		'Citizen_Greet.anim',
	},
}

tAnimations['talk_speak'] = 
{
    tFilenames={
		'Citizen_Talking.anim',
	},
}

tAnimations['talk_react_positive'] = 
{
    tFilenames={
		'Citizen_PositiveReact.anim',
	},
}

tAnimations['talk_react_negative'] = 
{
    tFilenames={
		'Citizen_NegativeReact.anim',
	},
}

tAnimations['talk_listen'] = 
{
    tFilenames={
        'Citizen_Listening.anim',
	},
}

tAnimations['talk_laugh'] = 
{
    tFilenames={
        'Citizen_Laughing.anim',
	},
}

tAnimations['talk_bye'] = 
{
    tFilenames={
		'Citizen_Talking.anim',
	},
}

tAnimations['talk_bye_positive'] = 
{
    tFilenames={
		'Citizen_HappyGoodbye.anim',
	},
}

tAnimations['talk_bye_negative'] = 
{
    tFilenames={
		'Citizen_UnhappyGoodbye.anim',
	},
}

tAnimations['become_friends'] = 
{
    tFilenames={
        'Citizen_BecomeFriends.anim',
	},
}

tAnimations['what_gives'] = 
{
    tFilenames={
        'Citizen_WhatGives.anim',
	},
}

tAnimations['give_present'] = 
{
    tFilenames={
        'Citizen_GivePresent.anim',
	},
}

tAnimations['take_present'] = 
{
    tFilenames={
        'Citizen_TakePresent.anim',
	},
}

tAnimations['watch_tv'] = 
{
    tFilenames={
        'Citizen_WatchTV.anim',
	},
}

tAnimations['watch_tv_like'] = 
{
    tFilenames={
        'Citizen_WatchTV_Enjoy.anim',
	},
}

tAnimations['watch_tv_dislike'] = 
{
    tFilenames={
        'Citizen_WatchTV_Dislike.anim',
	},
}

tAnimations['laser_cuffs_loop'] = 
{
    tFilenames={
        'Citizen_LaserCuffs_Loop.anim',
	},
}

tAnimations['laser_cuffs_walk'] = 
{
    tFilenames={
        'Citizen_LaserCuffs_Walk.anim',
	},
}

tAnimations['laser_cuffs_get_up'] = 
{
    tFilenames={
        'Citizen_LaserCuffs_GetUp.anim',
	},
}

tAnimations['sit'] = 
{
    sFilename='Citizen_Idle_A.anim',
}

tAnimations['breathe'] = 
{
    tFilenames={
		'Citizen_Idle_A.anim',
    	'Citizen_Idle_B.anim',
	},
}

tAnimations['drinkbooze'] = 
{
    tFilenames={
		'Citizen_Drink.anim',
	},
    sAccessory = 'Mug',
}

tAnimations['incapacitated'] = 
{
    sFilename='Citizen_WoundedOnGround.anim',
}

tAnimations['incapacitated_cuffed'] = 
{
    sFilename='Citizen_LaserCuffs_Loop.anim',
}

tAnimations['sleep'] = 
{
    sFilename='Citizen_Sleeping.anim',
	sInto='Citizen_Goto_Sleep.anim',
	sOutOf='Citizen_Wakeup.anim',
}

tAnimations['death_fire'] = 
{
    sFilename='Citizen_Fire_Death.anim',
}

tAnimations['death_suffocate'] = 
{
    sFilename='Citizen_Shot_Death.anim',
}

tAnimations['death_shot'] = 
{
    sFilename='Citizen_Shot_Death.anim',
}

tAnimations['death_pose'] = 
{
    sFilename='Citizen_DeadPose.anim',
}

tAnimations['panic_breathe']=
{
    sFilename='Citizen_Panic_Idle.anim',
}

tAnimations['panic_walk']=
{
    sFilename='Citizen_Panic_Walk.anim',
}

tAnimations['on_fire_breathe']=
{
    sFilename='Citizen_On_Fire.anim',
}

tAnimations['fight_fire_armed']=
{
    sFilename='Citizen_FightFire_Armed.anim',
    sAccessory='Extinguisher',
}

tAnimations['fight_fire_unarmed']=
{
   sFilename='Citizen_FightFire_Unarmed.anim',
}

tAnimations['space_flail']=
{
   sFilename='Citizen_SpaceFlail.anim',
}

tAnimations['melee']=
{
   sFilename='Citizen_Box.anim',
}

tAnimations['nonviolent_takedown_victim']=
{
   sFilename='Stun_Takedown.anim',
}

tAnimations['cower']=
{
   sFilename='Citizen_Cower.anim',
}

tAnimations['pushups']=
{
   sFilename='Citizen_Pushups.anim',
}
tAnimations['situps']=
{
   sFilename='Citizen_Situps.anim',
}
tAnimations['jumping_jacks']=
{
   sFilename='Citizen_JumpingJacks.anim',
}

--[[
tAnimations['clean_floor']=
{
   sFilename='Citizen_CleanFloor.anim',
}
]]--

tAnimations['gaming_idle']=
{
   sFilename='Citizen_GamingIdle.anim',
   sAccessory='GameSystem'
}
tAnimations['gaming_frustration']=
{
   sFilename='Citizen_GamingFrustration.anim',
   sAccessory='GameSystem'
}
tAnimations['eat_replicator']=
{
   sFilename='Citizen_Eat.anim',
   sAccessory='FoodBar',
   tRaceOverrides = { 
        [Character.RACE_BIRDSHARK] = 'Citizen_Eat_Birdshark.anim',
   },
}
tAnimations['eat_vegetable']=
{
   sFilename='Citizen_Eat_Vegetable.anim',
   sAccessory='FoodVegetable',
   tRaceOverrides = { 
        [Character.RACE_BIRDSHARK] = 'Citizen_Eat_Vegetable_Birdshark.anim',
   },
}
tAnimations['eat_cooked_food']=
{
   sFilename='Citizen_Eat_Fork.anim',
   sAccessory='FoodFork',
   tRaceOverrides = { 
        [Character.RACE_BIRDSHARK] = 'Citizen_Eat_Fork_Birdshark.anim',
   },
}
tAnimations['cook']=
{
   sFilename='Citizen_Cooking.anim',
   sAccessory='FryingPan',
}
tAnimations['carry_breathe']=
{
   sFilename='Citizen_Carry.anim',
}
tAnimations['carry_walk']=
{
   sFilename='Citizen_WalkCarry.anim',
}
tAnimations['carry_walk_corpse']=
{
   sFilename='Citizen_WalkCarry_Body.anim',
}
tAnimations['carry_breathe_corpse']=
{
   sFilename='Citizen_Breathe_BodyBag.anim',
}
tAnimations['drop_off_corpse']=
{
   sFilename='Citizen_DropOff_BodyBag.anim',
}
tAnimations['fridge']=
{
   sFilename='Citizen_Fridge.anim',
}
--[[
tAnimations['smoke']=
{
   sFilename='Citizen_Smoking.anim',
}
]]--
--[[
tAnimations['plant_seed']=
{
   sFilename='Citizen_Plant.anim',
}
]]--
--[[
tAnimations['bartender_idle']=
{
   sFilename='Citizen_BartenderIdle_B.anim',
}
]]--
--[[
tAnimations['bartender_idle_alt']=
{
   sFilename='Citizen_BartenderIdle.anim',
}
]]--
tAnimations['bartender_mix']=
{
   sFilename='Citizen_BartenderMix.anim',
}
tAnimations['harvest']=
{
   sFilename='Citizen_Harvest.anim',
}
tAnimations['workout_dumbell']=
{
   sFilename='Citizen_CurlDumbell.anim',
   sAccessory = 'Dumbell',
}
tAnimations['workout_benchpress']=
{
   sFilename='Citizen_BenchPress.anim',
   sAccessory = 'Barbell',
}
tAnimations['run']=
{
   sFilename='Citizen_Run_WithIntent.anim',
   bUseRunSpeed=true,
}
tAnimations['yawn']=
{
   sFilename='Citizen_Yawn.anim',
}
tAnimations['sneeze']=
{
   sFilename='Citizen_Yawn.anim',
}
tAnimations['startle']=
{
   sFilename='Citizen_Startle.anim',
}

tAnimations['stance']={}
local tPistolStance={
    walk={
        sFilename='Citizen_Run_WithGun.anim',
        sAccessory='Pistol',   
        bUseRunSpeed=true,
    },
    shoot={
        sFilename='Citizen_EmergencyShoot_Pistol.anim',
        sAccessory='Pistol',   
    },
    breathe={
        sFilename='Citizen_EmergencyStance.anim',
        sAccessory='Pistol',   
    },
}
tAnimations['stance']['pistol'] = tPistolStance

local tRifleStance={
    walk={
        sFilename='Citizen_Run_WithGun.anim',
        sAccessory='Rifle',   
        bUseRunSpeed=true,
    },
    shoot={
        sFilename='Citizen_EmergencyShoot.anim',
        sAccessory='Rifle',   
    },
    breathe={
        sFilename='Citizen_EmergencyStance.anim',
        sAccessory='Rifle',   
    },
}
tAnimations['stance']['rifle'] = tRifleStance

local tStunnerStance={
    walk={
        sFilename='Citizen_Run_WithGun.anim',
        sAccessory='Pistol',   
        bUseRunSpeed=true,
    },
    shoot={
        sFilename='Citizen_EmergencyShoot_Pistol.anim',
        sAccessory='Pistol',   
    },
    breathe={
        sFilename='Citizen_EmergencyStance.anim',
        sAccessory='Pistol',   
    },
}
tAnimations['stance']['stunner'] = tStunnerStance

local tMeleeStance={
    walk={
        sFilename='Citizen_Run_WithIntent.anim',
        bUseRunSpeed=true,
    },
}
tAnimations['stance']['melee'] = tMeleeStance

local tCuffedStance={
    walk={
        sFilename='Citizen_LaserCuffs_Walk.anim',
    },
    breathe={
        sFilename='Citizen_LaserCuffs_Standing.anim',
    },
    talk_greet={
		sFilename='Citizen_LaserCuffs_Standing.anim',
	},
    talk_introduce={
		sFilename='Citizen_LaserCuffs_Standing.anim',
	},
    talk_speak={
		sFilename='Citizen_LaserCuffs_Standing.anim',
	},
    talk_react_positive={
		sFilename='Citizen_LaserCuffs_Standing.anim',
    },
    talk_react_negative={
		sFilename='Citizen_LaserCuffs_Standing.anim',
	},
    talk_listen={
        sFilename='Citizen_LaserCuffs_Standing.anim',
	},
    talk_laugh={
        sFilename='Citizen_LaserCuffs_Standing.anim',
	},
    talk_bye={
		sFilename='Citizen_LaserCuffs_Standing.anim',
	},
    talk_bye_positive={
		sFilename='Citizen_LaserCuffs_Standing.anim',
	},
    talk_bye_negative={
		sFilename='Citizen_LaserCuffs_Standing.anim',
	},
    become_friends={
        sFilename='Citizen_LaserCuffs_Standing.anim',
	},
    what_gives={
        sFilename='Citizen_LaserCuffs_Standing.anim',
	},
    panic_walk={
        sFilename='Citizen_LaserCuffs_Walk.anim',
    },
    panic_breathe={
        sFilename='Citizen_LaserCuffs_Standing.anim',
    },
    on_fire_breathe={
        sFilename='Citizen_LaserCuffs_Standing.anim',
    },
    cower={
        sFilename='Citizen_LaserCuffs_Standing.anim',
    },
    run={
        sFilename='Citizen_LaserCuffs_Walk.anim',
        bUseRunSpeed=true,
    },
    startle={
        sFilename='Citizen_LaserCuffs_Standing.anim',
    },
    sleep={
        sFilename='Citizen_LaserCuffs_Standing.anim',
    },
}
tAnimations['stance']['cuffed'] = tCuffedStance

return tAnimations
