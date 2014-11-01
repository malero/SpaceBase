local DFUtil = require('DFCommon.Util')
local Character = require('CharacterConstants')
local tAnimations = {}

tAnimations.sBasePath = 'Characters/Murder_Robot/Animations/'

tAnimations['death_pose'] = 
{
    sFilename='MurderRobot_DeadPose.anim',
}
tAnimations['death_fire'] = 
{
    sFilename='MurderRobot_Death.anim',
}

tAnimations['death_suffocate'] = 
{
    sFilename='MurderRobot_Death.anim',
}

tAnimations['death_shot'] = 
{
    sFilename='MurderRobot_Death.anim',
}

tAnimations['breathe'] = 
{
    sFilename='MurderRobot_Idle.anim',
}

tAnimations['walk'] = 
{
    sFilename='MurderRobot_Walk.anim',
}
tAnimations['shoot'] = 
{
    sFilename='MurderRobot_Attack.anim',
}

return tAnimations
