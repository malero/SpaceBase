local Gui = require('UI.Gui')
local DFUtil = require("DFCommon.Util")
local DFInput = require('DFCommon.Input')
local DFMath = require("DFCommon.Math")
local UIElement = require('UI.UIElement')
local Renderer = require('Renderer')
local ObjectList = require('ObjectList')
local SoundManager = require('SoundManager')

local m = {}

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())
    
    function Ob:init(w, color)
        Ob.Parent.init(self)

        self.buttonHash = {}
        self.width = w
        self.uiBG = self:addRect(w,1,unpack(color))

        local y=-35
        self.baseMargin = 10
        self.yMargin = 10

        self.uiNameRect = self:addRect(self.width-2*self.baseMargin,70,0,0,0)
        self.uiNameRect:setLoc(self.baseMargin,y)
        self.uiNameText = self:addTextToTexture("SPACEDOOR", self.uiNameRect, "inspectName")
        y=y-90

        local r = self:addRect(self.width-2*self.baseMargin,70,0,0,0)
        r:setLoc(self.baseMargin,y)
        self.buttonHash[r] = self.cycleDoor
        self.uiOperation = self:addTextToTexture("UNEMPLOYED", r, "inspectName", MOAITextBox.CENTER_JUSTIFY)
        self.buttonHash[self.uiOperation] = self.cycleDoor
        y=y-70
        r = self:addRect(self.width-2*self.baseMargin,50,1/255,116/255,197/255)
        self.buttonHash[r] = self.cycleDoor
        r:setLoc(self.baseMargin,y)
        self.uiChangeDoorState = self:addTextToTexture("CHANGE DOOR STATE", r, "inspectLabelWhite", MOAITextBox.CENTER_JUSTIFY)
        self.uiChangeDoorStateRect = r
        self.buttonHash[self.uiChangeDoorState] = self.cycleDoor
        self.buttonHash[r] = self.cycleDoor
        y=y-50-self.yMargin

        r = self:addRect(self.width-2*self.baseMargin,70,0,0,0)
        r:setLoc(self.baseMargin,y)
        --self.buttonHash[r] = self.cycleDoor
        self.uiStatus = self:addTextToTexture("UNEMPLOYED", r, "inspectName", MOAITextBox.CENTER_JUSTIFY)
        self.buttonHash[self.uiOperation] = self.cycleDoor
        y=y-70

        self.uiBG:setScl(self.width,math.abs(y))
    end

    function Ob:updateSelected()
        local Door = require('EnvObjects.Door')
        self.currentDoor = g_GuiManager.getSelected('EnvObject')

        if self.currentDoor then
            if not self.currentDoor.tData or self.currentDoor.tData.customInspector ~= 'Door' then
                self.currentDoor = nil
            end
        end

        if not self.currentDoor then return end

        local operation = self.currentDoor:getOperation()
        if operation == Door.operations.NORMAL then
            self.uiOperation:setString("UNLOCKED")
        elseif operation == Door.operations.LOCKED then
            self.uiOperation:setString("LOCKED")
        elseif operation == Door.operations.FORCED_OPEN then
            self.uiOperation:setString("FORCED OPEN")
        end
        local status = self.currentDoor:getStatusString()
        self.uiStatus:setString(status)

        local objType,objSubtype = ObjectList.getObjType(self.currentDoor)
        local bAirlock = objSubtype == 'Airlock'
        --self:setElementHidden(self.uiChangeDoorState, bAirlock)
        --self:setElementHidden(self.uiChangeDoorStateRect, bAirlock)
        self.uiNameText:setString((bAirlock and 'AIRLOCK DOOR') or 'DOOR')
    end

    function Ob:inside(wx,wy)
        return self.uiBG:inside(wx,wy)
    end

    function Ob:onTick()
        if not self.currentDoor then return end

        local objType,objSubtype = ObjectList.getObjType(self.currentDoor)
        local bAirlock = objSubtype == 'Airlock'
        if bAirlock and self.currentDoor:getScriptController() then
            self.uiChangeDoorState:setString("PROCESSING")
            self:setElementHidden(self.uiChangeDoorStateRect, true)
        else
            self.uiChangeDoorState:setString("CHANGE DOOR STATE")
            self:setElementHidden(self.uiChangeDoorStateRect, false)
        end
    end

    function Ob:onFinger(touch, x, y, props)
        if touch.eventType == DFInput.TOUCH_UP then
            for _,v in ipairs(props) do
                local fn = self.buttonHash[v]
                if fn then
                    fn(self)
                    return true
                end
            end
        end
    end

    function Ob:cycleDoor()
        local objType,objSubtype = ObjectList.getObjType(self.currentDoor)
        if self.currentDoor and (objSubtype ~= 'Airlock' or not self.currentDoor:getScriptController()) then
            self.currentDoor:cycle()
            if self.currentDoor.operation == 1 then
                SoundManager.playSfx("doorforcedopen")
            elseif self.currentDoor.operation == 2 then
                SoundManager.playSfx("doorlocked")
            else
                SoundManager.playSfx("doornormal")
            end
        end
        self:refresh()
    end

    function Ob:refresh()
        self:updateSelected()
    end

    return Ob
end

function m.new(...)
    local Ob = m.create()
    Ob:init(...)

    return Ob
end

return m
