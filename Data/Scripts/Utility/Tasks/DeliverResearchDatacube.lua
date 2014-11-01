local Task=require('Utility.Task')
local Class=require('Class')
local Character=require('CharacterConstants')
local Log=require('Log')
local EnvObject = require('EnvObjects.EnvObject')
local Pickup = require('Pickups.Pickup')
local ResearchData = require('ResearchData')
local Base = require('Base')

local DeliverResearchDatacube = Class.create(Task)

DeliverResearchDatacube.DELIVER_ANIM = 'maintain'
DeliverResearchDatacube.DELIVER_ANIM_DURATION = 10

DeliverResearchDatacube.RESEARCH_AMOUNT = 800

function DeliverResearchDatacube:init(rChar,tPromisedNeeds,rActivityOption)
    Task.init(self,rChar,tPromisedNeeds,rActivityOption)
    self.rTarget = rActivityOption.tData.rTargetObject
        
	if not rActivityOption.tBlackboard.tPath then
		self:interrupt('Could not find the desk.')
		return
	end	
    self:setPath(rActivityOption.tBlackboard.tPath)
end

function DeliverResearchDatacube:onUpdate(dt)
    if self:interacting() then
        if self:tickInteraction(dt) then
            local tItem = self.rChar:getInventoryItemOfTemplate('ResearchDatacube')
            assertdev(tItem)
            if tItem then
                assertdev(tItem.sTemplate == 'ResearchDatacube')
                assertdev(tItem.sResearchData)
                tItem = self.rChar:destroyItem(tItem.sName)
                assertdev(tItem)
            end
            
            if not tItem or tItem.sTemplate ~= 'ResearchDatacube' or not tItem.sResearchData then
                self:interrupt('Character was not holding a research datacube.')
                return
            end

			-- redeem for research credit
			Base.addResearch(tItem.sResearchData, DeliverResearchDatacube.RESEARCH_AMOUNT)
			self.rChar:alterMorale(Character.MORALE_MINE_ASTEROID, 'DeliverResearchData')
			local sResearchLC = ResearchData[tItem.sResearchData].sName
			local tLogData = { sResearchData = g_LM.line(sResearchLC) }
			Log.add(Log.tTypes.DUTY_SCIENTIST_DELIVER_RESEARCH, self.rChar, tLogData)
            return true
        end
    elseif self.tPath then
        self:tickWalk(dt)
    else
        local tx,ty = g_World._getTileFromWorld(self.rTarget:getLoc())
        if self:attemptInteractWithTile(DeliverResearchDatacube.DELIVER_ANIM,tx,ty,DeliverResearchDatacube.DELIVER_ANIM_DURATION) then
            -- wait until completion
        else
            self:interrupt('Unable to reach dropoff point.')
        end
    end
end

return DeliverResearchDatacube
