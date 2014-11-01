local Task=require('Utility.Task')
local Class=require('Class')
local World=require('World')
local Malady=require('Malady')
local CommandObject=require('Utility.CommandObject')
local Log=require('Log')
local Room=require('Room')
local EnvObject = require('EnvObjects.EnvObject')
local CharacterConstants=require('CharacterConstants')

local BuildEnvObject = Class.create(Task)

--BuildEnvObject.emoticon = 'work'
BuildEnvObject.HELMET_REQUIRED = true

function BuildEnvObject:init(rChar,tPromisedNeeds,rActivityOption)
    self.super.init(self,rChar,tPromisedNeeds,rActivityOption)
    self.duration = 6
    self.propName = rActivityOption.tData.propName
    self.rTarget = rActivityOption.tData.rTargetObject
    self.targetX,self.targetY = rActivityOption.tData.pathX,rActivityOption.tData.pathY
    self.bFlipX = rActivityOption.tData.bFlipX
	self.bFlipY = rActivityOption.tData.bFlipY
    self:setPath(rActivityOption.tBlackboard.tPath)    
end

function BuildEnvObject:_tryToBuild()
    if self.rChar:isElevated() then return false end
    local cx,cy = self.rChar:getLoc()
    local bCanBuild = World.areWorldCoordsAdjacent(cx,cy,self.targetX,self.targetY,true,true)

    if bCanBuild then
        if self.tCommand then
            local cmdObj = CommandObject.getCommandAtWorld(self.targetX,self.targetY) 
            bCanBuild = cmdObj and cmdObj.commandAction == CommandObject.COMMAND_BUILD_ENVOBJECT
        else
            local tx,ty = g_World._getTileFromWorld(self.targetX,self.targetY)
            local rRoom,addr,tData = Room.getGhostAtTile(tx,ty)
            if tData and tData.sName == self.propName and tData.tx == tx and tData.ty == ty then
            else
                bCanBuild=false
            end
        end
    end
    if bCanBuild then
        self.bBuilding = true
        self.rChar:playAnim('build')
        self.rChar:faceWorld(self.targetX,self.targetY)
        self.duration = 3
        return true
    end
end

function BuildEnvObject:onUpdate(dt)
    if self.bBuilding then
        self.duration = self.duration - dt
        if self.duration < 0 then
            local bBuilt = false
            local tx,ty = g_World._getTileFromWorld(self.targetX,self.targetY)
            if self.tCommand then
                local cmdObj = CommandObject.getCommandAtWorld(self.targetX,self.targetY)
                if cmdObj and cmdObj.commandAction == CommandObject.COMMAND_BUILD_ENVOBJECT then
                    CommandObject._performCommand(cmdObj)
                    bBuilt = true
                end
            else
                local rRoom,addr,tData = Room.getGhostAtTile(tx,ty)
                if tData and tData.sName == self.propName and tData.tx == tx and tData.ty == ty then
                    local rProp = EnvObject.createEnvObject(self.propName, self.targetX,self.targetY, self.bFlipX, self.bFlipY)
                    if rProp then
                        bBuilt = true
                        -- We get refunded the amount of matter from clearing the ghost.
                        -- And then re-charge it to create the real object.
                        if rProp.tData and rProp.tData.matterCost then
                            g_GameRules.expendMatter(rProp.tData.matterCost)
                        end
                        self.sFriendlyName = rProp.sFriendlyName
                        self.sUniqueName = rProp.sUniqueName
					    -- builder name & time
					    rProp.sBuilderName = self.rChar.tStats.sUniqueID
					    rProp.sBuildTime = require('GameRules').sStarDate
                        Malady.interactedWith(self.rChar,rProp)

                        if self.rChar:getInventoryItemOfTemplate('SuperBuilder') and rProp.preventDecayFor then
                            rProp:preventDecayFor(60*5)
                            rProp.nDecayMult = .5
                        end
                    end
                end
            end
            if bBuilt then
                --if self.buildGhost then
                    --EnvObject.destroyBuildGhost(self.buildGhost)
                --end
				self.rChar:alterMorale(CharacterConstants.MORALE_BUILD_BASE, 'BuildObject')
				-- spaceface log
                local tLogData = {
                    sDutyTarget = self.sFriendlyName,
                    sLinkTarget = self.sUniqueName,
                    sLinkType = 'EnvObject',
                }
                -- generic "stuff" if name unknown
                if not self.sFriendlyName then
                    tLogData.sDutyTarget = g_LM.line('SFDTBD008CITZ')
                end
                Log.add(Log.tTypes.DUTY_BUILD, self.rChar, tLogData)
                return true
            else
                -- HACK: Let's manually tell the room to retest the tile because something went wrong.
                local addr = g_World.pathGrid:getCellAddr(tx,ty)
                Room.tileContentsChanged(tx,ty,addr)
                CommandObject.tileChanged(tx,ty,addr)
                self:interrupt("failed to build object.")
            end
        end
    elseif self.tPath then
        self:tickWalk(dt)
    else
        if not self:_tryToBuild() then
            self:interrupt('Unable to reach target location.')
        end
    end
end

return BuildEnvObject
