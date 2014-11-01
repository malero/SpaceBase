local ScreenManager = {
    profilerName='ScreenManager',
    tCachedPointerEvent={},
}

local DFInput = require("DFCommon.Input")
local Renderer = require('Renderer')     
local Screen = require('UI.Screen')
local Profile = require('Profile')

local kMaxDeltaTime = 1.0 / 30.0

function ScreenManager:initialize(bFullscreen)
    if nil == bFullscreen then bFullscreen = false end

    ScreenManager.tScreens = {}
    ScreenManager.tDeadScreens = {}
    ScreenManager.tInputScreens = {}
    ScreenManager.tRenderLayers = {}
    ScreenManager.bFullScreen = bFullscreen

	-- Bind input handlers
    DFInput.onFinger = function(touch)
		ScreenManager:onFinger(touch)
	end
	DFInput.onHover = function(x,y)
        ScreenManager:onHover( x, y )
    end
    DFInput.onKeyboard = function(key, down)
		ScreenManager:onKeyboard(key, down)
	end
    
    if ScreenManager.bFullScreen then
        MOAISim.enterFullscreenMode()
    end
end

function ScreenManager:toggleFullscreen()
    if not ScreenManager.bFullScreen then
        MOAISim.enterFullscreenMode()
        ScreenManager.bFullScreen = true
    else
        MOAISim.exitFullscreenMode()
        ScreenManager.bFullScreen = false
    end
end

function ScreenManager:setFullscreen(bFullscreen)
    if ScreenManager.bFullScreen ~= bFullscreen then
        ScreenManager.bFullScreen = bFullscreen
        
        DFSpace.setFullscreenState(bFullscreen)
    end
end

-------------------------------------------------------------
-- input functions
-------------------------------------------------------------

function ScreenManager:_onPointer(pointer)
    local bDoubleTap=pointer.bDoubleTap
    local numScreens = #ScreenManager.tInputScreens
    for i=1,numScreens do

        local rScreen = ScreenManager.tInputScreens[i]
        if rScreen:inputPointer(pointer, bDoubleTap) then
            break
        end
    end
end

-- Send the cached event when we get a new event of type:
-- TOUCH_DOWN
-- TOUCH_UP
-- Or when 

function ScreenManager:_sendCachedPointerEvent()
    local tC = self.tCachedPointerEvent
    if tC.bHover then
        self:_onHover(tC.x,tC.y)
    else
        self:_onPointer(tC)
    end
    tC.bFresh=false
end

function ScreenManager:_cachePointerEvent(pointer)
    local tC = self.tCachedPointerEvent
    local bNewType = not tC.bFresh or tC.bHover or tC.id ~= pointer.id or tC.eventType ~= pointer.eventType or tC.eventType ~= MOAITouchSensor.TOUCH_MOVE or tC.button ~= pointer.button
    if bNewType then
        if tC.bFresh then self:_sendCachedPointerEvent() end
        tC.bHover=false
        tC.eventType=pointer.eventType
        tC.button=pointer.button
        tC.bDoubleTap = pointer.tapCount > 1
        tC.tapCount=pointer.tapCount
        tC.id = pointer.id
    end
    tC.bFresh=true
    tC.x=pointer.x
    tC.y=pointer.y
end

function ScreenManager:_cacheHoverEvent(x,y)
    local tC = self.tCachedPointerEvent
    local bNewType = not tC.bFresh or not tC.bHover
    if bNewType then
        if tC.bFresh then self:_sendCachedPointerEvent() end
        tC.bHover=true
        tC.eventType=nil
    end
    tC.bFresh=true
    tC.x = x
    tC.y = y
end

function ScreenManager:onFinger(pointer)
    self:_cachePointerEvent(pointer)
	--ScreenManager:_onPointer(pointer, pointer.tapCount > 1)
end

function ScreenManager:onKeyboard(key, down)
    -- Look for "system keys"
    
    if down then
		if MOAIEnvironment.osBrand == "OSX" then
			if key == string.byte("f") and MOAIInputMgr.device.keyboard:keyIsDown(MOAIKeyboardSensor.CONTROL) then
				self:toggleFullscreen()
			end
		elseif key == 13 and MOAIInputMgr.device.keyboard:keyIsDown(MOAIKeyboardSensor.ALT) then
			self:toggleFullscreen()
		end
	end

    local numScreens = #ScreenManager.tInputScreens
    for i=1,numScreens do

        local rScreen = ScreenManager.tInputScreens[i]
        if rScreen:inputKeyboard(key, down) then
            break
        end
    end
end

function ScreenManager:onHover(x,y)
    self:_cacheHoverEvent(x,y)
end

function ScreenManager:_onHover(x,y)
    local numScreens = #ScreenManager.tInputScreens
    for i=1,numScreens do

        local rScreen = ScreenManager.tInputScreens[i]
        if rScreen:inputHover(x,y) then
            break
        end
    end
end

-------------------------------------------------------------
-- protected functions
-------------------------------------------------------------
function ScreenManager:onTick(deltaTime)
    if self.tCachedPointerEvent.bFresh then
        self:_sendCachedPointerEvent()
    end


	--Profile.enterScope( "ScreenManager:onTick" )
    
    -- Update the status of all screens
    local numScreens = #ScreenManager.tScreens
    for i=1,numScreens do
    
        local rScreen = ScreenManager.tScreens[i]
        rScreen:updateStatus(deltaTime)
        
        if rScreen.bRemove == true then
            table.insert(ScreenManager.tDeadScreens, rScreen)
        end
    end
    
    -- Remove the inactive screens
    local numDeadScreens = #ScreenManager.tDeadScreens
    if numDeadScreens > 0 then
        for i=1,numDeadScreens do
            ScreenManager:removeScreen(ScreenManager.tDeadScreens[i])
        end
        ScreenManager.tDeadScreens = {}
        numScreens = #ScreenManager.tScreens
    end

        
    -- ToDo: Sort the screens, so that top-most screens always render last
    
    -- Find the first opaque screen in the stack
    local idxFirstScreen = 1
    for i=1,numScreens do
    
        local idx = numScreens - i + 1
        local rScreen = ScreenManager.tScreens[idx]
        if rScreen.bIsOpaque then
            idxFirstScreen = idx
            break
        end
    end
    
    -- Find all screens that accept input
    ScreenManager.tInputScreens = {}
    for i=1,numScreens do
    
        local idx = numScreens - i + 1
        local rScreen = ScreenManager.tScreens[idx]
        if rScreen.inputMode >= Screen.INPUTMODE_NORMAL then
            table.insert(ScreenManager.tInputScreens, rScreen)
        end
        if rScreen.inputMode == Screen.INPUTMODE_EXCLUSIVE then
            break
        end
    end

    
    -- Update all visible screens
    ScreenManager.tRenderLayers = {}
    for i=idxFirstScreen,numScreens do
    
        local rScreen = ScreenManager.tScreens[i]
        
        -- Update the layers
        if rScreen.onTick then
            rScreen:onTick(deltaTime)
        end
        
        -- Accumulate all visible render-layers
        rScreen:addLayers(ScreenManager.tRenderLayers)
    end
    
    -- Tell the renderer what to do
    MOAIRenderMgr.setRenderTable(ScreenManager.tRenderLayers)
    
    -- Update the renderer
	Renderer.onTick(deltaTime)
    
	--Profile.leaveScope( "ScreenManager:onTick" )
end

-------------------------------------------------------------
-- public interface for others
-------------------------------------------------------------
function ScreenManager:pushScreen(rScreen, bIsTopMost)

    -- Set the (static) top-most flag
    if bIsTopMost == true then
        rScreen.bIsTopMost = true
    else
        rScreen.bIsTopMost = false
    end

    if not rScreen.bIsTopMost then
    
        -- Insert the new screen under all top-most screen
        local numScreens = #ScreenManager.tScreens
        local idxTop = numScreens
        if numScreens > 0 then
            for i=1,numScreens do
            
                local idx = numScreens - i + 1
                local rScreen = ScreenManager.tScreens[idx]
                if not rScreen.bIsTopMost then
                    idxTop = idx
                end
            end
        else
            -- First screen
            idxTop = 1
        end
        
        table.insert(self.tScreens, idxTop, rScreen)
    else
        table.insert(self.tScreens, rScreen)
    end
    
    rScreen:added()
end

function ScreenManager:removeScreen(rScreen)

	if rScreen ~= nil then

		-- Find and remove the given screen
		local numScreens = #ScreenManager.tScreens
		for i=1,numScreens do
		
			local rScr = ScreenManager.tScreens[i]
			if rScr == rScreen then
				table.remove(self.tScreens, i)
				rScreen:removed()
				return
			end
		end
		
		Trace(TT_Error, "Couldn't find screen")
	end
end

function ScreenManager:getScreen(sScreenName)

    local numScreens = #ScreenManager.tScreens
    for i=1,numScreens do
    
        local rScreen = ScreenManager.tScreens[i]
        if rScreen.sName == sScreenName then
            return rScreen
        end
    end
    
    return nil
end

return ScreenManager
