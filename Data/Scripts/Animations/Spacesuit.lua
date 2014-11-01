local DFUtil = require('DFCommon.Util')
local Character = require('CharacterConstants')
local tAnimations = {}

tAnimations.sBasePath = 'Characters/Spacesuit/Animations/'

tAnimations['breathe']=
{
   sFilename='Spacewalk_Idle.anim',
}
tAnimations['carry_breathe']=
{
   sFilename='Spacewalk_Idle.anim',
}
tAnimations['walk']=
{
   sFilename='Spacewalk_Walk.anim',
}
tAnimations['carry_walk']=
{
   sFilename='Spacewalk_Walk.anim',
}
tAnimations['walk_rock']=
{
   sFilename='Spacewalk_Walk_Rock.anim',
}
tAnimations['mining']=
{
   sFilename='Spacewalk_Mining.anim',
}
tAnimations['build']=
{
   sFilename='Spacewalk_Build.anim',
}
tAnimations['death_shot']=
{
   sFilename='Spacewalk_Death.anim',
}
tAnimations['death_fire']=
{
   sFilename='Spacewalk_Death.anim',
}
tAnimations['death_flail']=
{
   sFilename='Spacewalk_Death.anim',
}
tAnimations['death_suffocate']=
{
   sFilename='Spacewalk_Death.anim',
}
tAnimations['death_pose']=
{
   sFilename='Spacewalk_Death.anim',
}
tAnimations['melee']=
{
   sFilename='Spacewalk_Shoot.anim',
}

tAnimations['stance']={}
local tPistolStance={
    --walk={
        --sFilename='Citizen_Run_WithGun.anim',
        --sAccessory='Pistol',   
    --},
    shoot={
        sFilename='Spacewalk_Shoot.anim',
        sAccessory='Pistol',   
    },
    --idle={
        --sFilename='Citizen_EmergencyStance.anim',
        --sAccessory='Pistol',   
    --},
}
tAnimations['stance']['pistol'] = tPistolStance

local tRifleStance={
    --walk={
        --sFilename='Citizen_Run_WithGun.anim',
        --sAccessory='Rifle',   
    --},
    shoot={
        sFilename='Spacewalk_Shoot.anim',
        sAccessory='Rifle',   
    },
    --idle={
        --sFilename='Citizen_EmergencyStance.anim',
        --sAccessory='Rifle',   
    --},
}
tAnimations['stance']['rifle'] = tRifleStance

return tAnimations
