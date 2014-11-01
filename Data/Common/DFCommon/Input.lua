-- Singleton object for input handling
--     Stores all current touch events in m_touches
--     Bind a function to input.onFinger to get touch events
--     Bind a function to input.onKeyboard to get keyboard events 

local DFMath = require "DFCommon.Math"

local input = {
    m_touches = {},
    -- Just for laziness' sake
    TOUCH_DOWN = MOAITouchSensor.TOUCH_DOWN,
    TOUCH_MOVE = MOAITouchSensor.TOUCH_MOVE,
    TOUCH_UP = MOAITouchSensor.TOUCH_UP,
    MOUSE_LEFT = 0,
    MOUSE_RIGHT = 1,
    MOUSE_MIDDLE = 2,
    MOUSE_SCROLL_UP = 3,
    MOUSE_SCROLL_DOWN = 4,
    -- Internal: mouse state, not used on iOS devices
    m_x = 0,
    m_y = 0,
    TAP_TIME = 0.6,
    TAP_MARGIN = 50.0,
}

-- ----------------------------------------------------------------------
-- Input and focus handling
-- ----------------------------------------------------------------------

function input:init()
    if MOAIInputMgr.device.pointer then
        -- called on button state _change_ (not continuously)
        local tapCount = 0
        local lastTapTime = 0
        local lastX, lastY = 0, 0
        local function mouseButtonCb(button, down)
            -- nb: self is an upvalue
            local evt = down and self.TOUCH_DOWN or self.TOUCH_UP

            -- add the the touch to the array on mouse down
            if down then
                self.m_touches[button + 1] = {
                    id = 1,
                    x = self.m_x,
                    y = self.m_y,
                    tapCount = 1,
                    button = button,
                }

                local tapTime = MOAISim.getDeviceTime()

                -- Check to see if this tap is close enough to the previous tap
                local dx, dy = self.m_x - lastX, self.m_y - lastY
                if math.abs(dx) < self.TAP_MARGIN and math.abs(dy) < self.TAP_MARGIN then
                
                    -- Check to see if this tap is recent enough to the previous tap
                    local tapDelay = tapTime - lastTapTime
                    if tapDelay < self.TAP_TIME then
                        self.m_touches[button + 1].tapCount = tapCount + 1
                    end
                end
                
                -- Always update the last tap time
                lastTapTime = tapTime
            else
                -- Safeguard against mouse up events that we didn't receive a
                -- corresponding mouse down event for (which happens in Windows
                -- when the title bar is double clicked to go fullscreen)
                if not self.m_touches[button + 1] then
                    return
                else
                    tapCount = self.m_touches[button + 1].tapCount
                    lastX, lastY = self.m_x, self.m_y
                end
                
            end
                        
            self.m_touches[button + 1].eventType = evt

            if self.onFinger ~= nil then
                self.onFinger(self.m_touches[button + 1])
            end
            
            -- remove after the callback to preserve
            -- state for callback handler.
            if not down then
                self.m_touches[button + 1] = nil
            end
        end
        
        local function mouseLeftCb(down)
            mouseButtonCb(self.MOUSE_LEFT, down)
        end
        
        local function mouseRightCb(down)
            mouseButtonCb(self.MOUSE_RIGHT, down)
        end
        
        local function mouseMiddleCb(down)
            mouseButtonCb(self.MOUSE_MIDDLE, down)
        end

        local function mouseScrollUpCb(down)
            mouseButtonCb(self.MOUSE_SCROLL_UP, down)
        end

        local function mouseScrollDownCb(down)
            mouseButtonCb(self.MOUSE_SCROLL_DOWN, down)
        end
		
        -- called on pointer position _change_ (not continuously)
        local function pointerCb(x,y)
            -- nb: self is an upvalue
            self.m_x, self.m_y = x, y
            
            local bMove = false
            for i=1,3 do
                if self.m_touches[i] ~= nil then
                    bMove = true
                    self.m_touches[i].eventType = self.TOUCH_MOVE
                    self.m_touches[i].x = x
                    self.m_touches[i].y = y
                    
                    if self.onFinger ~= nil then
                        self.onFinger(self.m_touches[i])
                    end
                end
            end
            if not bMove then
                if self.onHover ~= nil then
                    self.onHover( x, y )
                end
            end
        end

        MOAIInputMgr.device.pointer:setCallback( pointerCb )
        MOAIInputMgr.device.mouseLeft:setCallback( mouseLeftCb )        
		MOAIInputMgr.device.mouseRight:setCallback( mouseRightCb )
        MOAIInputMgr.device.mouseMiddle:setCallback( mouseMiddleCb )
        if MOAIInputMgr.device.mouseScrollUp then
            MOAIInputMgr.device.mouseScrollUp:setCallback( mouseScrollUpCb )
        end
        if MOAIInputMgr.device.mouseScrollDown then
            MOAIInputMgr.device.mouseScrollDown:setCallback( mouseScrollDownCb )
        end
    else
        local function touchCb(evt, idx, x,y, tapCount)
            -- nb: self is an upvalue
            
            idx = idx+1 -- uses 0 for single-touch; does multi-touch also start at 0?
            -- create a new touch on down
            if evt == self.TOUCH_DOWN then
               self.m_touches[idx] = { index = idx }         
            end
            
            self.m_touches[idx].eventType = evt
            self.m_touches[idx].x = x
            self.m_touches[idx].y = y
            self.m_touches[idx].tapCount = tapCount
            
            if (evt == self.TOUCH_DOWN or
                evt == self.TOUCH_MOVE or
                evt == self.TOUCH_UP) then
                if self.onFinger ~= nil then
                    self.onFinger(self.m_touches[idx])
                end
            end
            
            -- remove after the callback to preserve
            -- state for callback handler.
            if evt == self.TOUCH_UP then
                self.m_touches[idx] = nil          
            end
        end
        MOAIInputMgr.device.touch:setTapTime(self.TAP_TIME)
        MOAIInputMgr.device.touch:setTapMargin(self.TAP_MARGIN)
        MOAIInputMgr.device.touch:setCallback(touchCb)
    end

    -- KEYBOARD IS MAINLY FOR DEBUG
    local function keyboardCb(key, bDown)
        if self.onKeyboard then
            self.onKeyboard(key, bDown)
        end
    end

    if MOAIInputMgr.device.keyboard then
        MOAIInputMgr.device.keyboard:setCallback(keyboardCb)
    end
end

return input
