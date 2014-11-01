local Class=require('Class')
local ObjectList=require('ObjectList')
local EnvObject=require('EnvObjects.EnvObject')
local Pickup=require('Pickups.Pickup')
local CharacterManager = require('CharacterManager')
local Character = require('CharacterConstants')
local Base = require('Base')

local Corpse = Class.create(Pickup, MOAIProp.new)

Corpse.TYPE_FRIENDLY = 1
Corpse.TYPE_RAIDER = 2
Corpse.TYPE_MONSTER = 3

function Corpse:init(sName, wx, wy, bFlipX, bFlipY, bForce, tSaveData)
    Pickup.init(self, sName, wx, wy, bFlipX, bFlipY, bForce, tSaveData)

    self.tCorpseItem = self.tInventory[ next(self.tInventory) ]
    local sName
    if self.tCorpseItem then 
        sName = self.tCorpseItem.sOccupantName 
    end
    if not sName then sName = '' end

    -- always hide sprite
	self:setVisible(false)
    -- show name as eg "Body Bag (Joe Deadguy)"
    self.sFriendlyName = g_LM.line('PROPSX082TEXT')..' ('..sName..')'
end

function Corpse:hideBodybag()
	self.rGroundRig:deactivate()
    self.bNoSelect = true
end

function Corpse:remove()
    if self.bDestroyed then return end
    EnvObject.remove(self)
	if self.rGroundRig then 
        self.rGroundRig:deactivate()
        self.rGroundRig = nil
    end
    
    local rOccupant = self.tCorpseItem and self.tCorpseItem.tOccupant and ObjectList.getObject(self.tCorpseItem.tOccupant)
	-- destroy character if still contained in bag
	if rOccupant and not rOccupant.bDestroyed then
        CharacterManager.deleteCharacter( rOccupant )
	end
end

return Corpse
