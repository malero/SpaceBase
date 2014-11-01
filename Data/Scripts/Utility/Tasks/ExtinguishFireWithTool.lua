local Task=require('Utility.Task')
local Class=require('Class')
local World=require('World')
local CharacterConstants=require('CharacterConstants')
local ExtinguishFireBareHanded=require('Utility.Tasks.ExtinguishFireBareHanded')

local ExtinguishFireWithTool = Class.create(ExtinguishFireBareHanded)

ExtinguishFireWithTool.MIN_DOUSE_AMOUNT = 2
ExtinguishFireWithTool.MAX_DOUSE_AMOUNT = 2.75
--ExtinguishFireWithTool.emoticon = 'alert'
ExtinguishFireWithTool.animation = 'fight_fire_armed'

function ExtinguishFireWithTool:init(rChar,tPromisedNeeds,rActivityOption)
    ExtinguishFireBareHanded.init(self,rChar,tPromisedNeeds,rActivityOption)
    self.nDouseAmount = self:getDuration(ExtinguishFireWithTool.MIN_DOUSE_AMOUNT, ExtinguishFireWithTool.MAX_DOUSE_AMOUNT, CharacterConstants.EMERGENCY)
    self.extinguishAnim = ExtinguishFireWithTool.animation
    self.HELMET_REQUIRED = false
    if self.rChar.tStats.nJob == CharacterConstants.EMERGENCY then        
        self.HELMET_REQUIRED = true
        self.rChar:showHelmet()
    end
    --self.super.init(self,rChar,tPromisedNeeds,rActivityOption)
end

return ExtinguishFireWithTool

