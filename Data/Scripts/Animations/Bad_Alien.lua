local DFUtil = require('DFCommon.Util')
local Character = require('CharacterConstants')
local tAnimations = {}

tAnimations.sBasePath = 'Characters/Bad_Alien/Animations/'

tAnimations['death_pose'] = 
{
    sFilename='BadAlien_DeadPose.anim',
}

tAnimations['sleep'] = 
{
    sFilename='BadAlien_DeadPose.anim',
}

tAnimations['death_fire'] = 
{
    sFilename='BadAlien_Death.anim',
}

tAnimations['death_suffocate'] = 
{
    sFilename='BadAlien_Death.anim',
}

tAnimations['death_shot'] = 
{
    sFilename='BadAlien_Death.anim',
}

tAnimations['breathe'] = 
{
    sFilename='BadAlien_Idle.anim',
}

tAnimations['walk'] = 
{
    sFilename='BadAlien_Walk.anim',
}
tAnimations['melee'] = 
{
    sFilename='BadAlien_Attack.anim',
}
tAnimations['hit_react'] = 
{
    sFilename='BadAlien_HitReact.anim',
}
tAnimations['scream'] = 
{
    sFilename='BadAlien_PrimalScream.anim',
}
tAnimations['eat'] = 
{
    sFilename='BadAlien_Kill.anim',
}



return tAnimations
