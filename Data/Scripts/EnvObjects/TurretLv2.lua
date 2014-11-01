local Class=require('Class')
local EnvObject=require('EnvObjects.EnvObject')
local Turret=require('EnvObjects.Turret')

local TurretLv2 = Class.create(Turret, MOAIProp.new)

Turret.FIRE_COOLDOWN = 3
-- beefier
Turret.HIT_POINTS = 500
Turret.FIRE_DAMAGE = 75

Turret.tFrames = {
	{ nMin = 0, sSprite = 'turret_lv2_frames0001' },
	{ nMin = 45, sSprite = 'turret_lv2_frames0002' },
	{ nMin = 75, sSprite = 'turret_lv2_frames0003' },
	{ nMin = 105, sSprite = 'turret_lv2_frames0004' },
	{ nMin = 135, sSprite = 'turret_lv2_frames0005' },
}

return TurretLv2
