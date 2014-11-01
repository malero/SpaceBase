local DFUtil = require('DFCommon.Util')
local Class = require('Class')
local SeqCommand = require('SeqCommand')
local ScMovePosition = Class.create(SeqCommand)

local EntityManager = require('EntityManager')

-- ATTRIBUTES --
ScMovePosition.ActorName = ""
ScMovePosition.CinematicDisplay = false

local DFSchema = require('DFCommon.DFSchema')
local tFields = DFUtil.deepCopy(SeqCommand.rSchema.tFieldSchemas)
tFields['ActorName'] = DFSchema.entityName(nil, "Name of the actor whose position we're changing", "ControllingActor")
tFields['AbsolutePosition'] = DFSchema.vec3({ 0, 0, 0 }, "(optional) Absolute position for where the actor should end up")
tFields['LocatorName'] = DFSchema.entityName(nil, "(optional) Name of the locator or entity from which to offset the Actor's position")
tFields['Offset'] = DFSchema.vec3({ 0, 0, 0 }, "(optional) Offset from the Position or Locator")
tFields['MoveByWalking'] = DFSchema.bool(false, "Whether to move the actor using their CoNavigation")
tFields['Scale'] = DFSchema.number(1, "(optional) The scale to make the actor")

ScMovePosition.rSchema = DFSchema.object(
    tFields,
    "Moves the actor to the specified position"
)
SeqCommand.addEditorSchema('ScMovePosition', ScMovePosition.rSchema)
-- VIRTUAL FUNCTIONS --

function ScMovePosition:onCreated()
    if not self.AbsolutePosition then
        self.AbsolutePosition = { 0, 0, 0 }
    end
    
    if not self.Offset then
        self.Offset = { 0, 0, 0 }
    end
end

function ScMovePosition:onExecute()    
    -- determine the position
    self.x, self.y = self.AbsolutePosition[1], self.AbsolutePosition[2]
    -- locator used below, so declare it outside the branch
    local rLocator = nil
    if self.LocatorName then
        rLocator = EntityManager.getEntityNamed( self.LocatorName )
        if rLocator then
            -- hitbox takes precedence, followed by usepoint
            if rLocator.CoExitHitbox and rLocator.CoExitHitbox.getWalkToPoint then
                self.x, self.y = rLocator.CoExitHitbox:getWalkToPoint()            
            elseif rLocator.CoUsePoint then 
                self.x, self.y = rLocator.CoUsePoint:getWorldLoc()
                self.sDirection = rLocator.CoUsePoint:getDirection()                
                -- TODO: set the scene layer appropriately
            else
                self.x, self.y = rLocator:getProp():modelToWorld()
                -- grab the entity's scene layer
                self.rSceneLayer = rLocator:getSceneLayer()
            end
        else
            Trace( TT_Error, "Locator "..self.LocatorName.." could not be found." )
        end        
    end
    
    -- apply the offset
    self.x = self.x + self.Offset[1]
    self.y = self.y + self.Offset[2]
    
    if self.bSkip then        
        return
    end
    
    local rActor = EntityManager.getEntityNamed( self.ActorName )    
    
    -- if there's scale, set the scale
    if self.Scale then
        rActor:getProp():setScl( self.Scale )
    end
    
    -- move there if we need to do it over time or simply jump to that position
    local coNavigator = rActor:getComponent( "CoNavigator" )			                
    if self.MoveByWalking then                        
        
        if coNavigator then                                      
            coNavigator:moveToPoint( self.x, self.y, rLocator )
            if self.Blocking then                
                while coNavigator:isMoving()do
                    coroutine.yield()
                end                
                if self.sDirection then
                    rActor.CoAnimation:setAnimationState( self.sDirection, true )
                end
            end
        else
            Trace( TT_Error, "You say you want to move the actor "..self.ActorName.." by walking, but it doesn't have a CoNavigator :(" )
        end
    else
        if coNavigator then
            coNavigator:cancelNavigation()
        end        
        rActor:getProp():setLoc( self.x, self.y )
        -- set the scene layer if there is one
        if self.rSceneLayer then
            rActor:setSceneLayer( self.rSceneLayer )
        end
    end

end

function ScMovePosition:onCleanup()
    local rActor = EntityManager.getEntityNamed( self.ActorName )
    if rActor then
        rActor:getProp():setLoc( self.x, self.y )
        rActor:getProp():forceUpdate()
        if self.rSceneLayer then
            rActor:setSceneLayer( self.rSceneLayer )
        end
    end
end

-- PUBLIC FUNCTIONS --

return ScMovePosition
