local m = {}

local DFUtil = require("DFCommon.Util")
local DFInput = require('DFCommon.Input')
local UIElement = require('UI.UIElement')
local Renderer = require('Renderer')
local GameRules = require('GameRules')
local SoundManager = require('SoundManager')

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())

    Ob.height = 120

    function Ob:jobs()
        GameRules.setUIMode(GameRules.MODE_GLOBAL_JOB)
        g_GuiManager.refresh()
    end

    function Ob:menu()
        g_GuiManager.showStartMenu()
    end

    Ob.controls=
    {
        {fn=Ob.jobs,label="JOBS", width=100},
        {fn=Ob.menu,label="MENU", width=100},
        {fn=GameRules.timeSlower,label="<"},
        {fn=GameRules.timePause,label="||"},
        {color={0,0,0}, readout=true, width=65},
        {fn=GameRules.timeStandard,label=">"},
        {fn=GameRules.timeFaster,label=">>"},
        {fn=SoundManager.incrementTrack,label="Next",color={.6,.3,.3}},
    }

    function Ob:init()
        Ob.Parent.init(self)

        self.width=630
        self.height=45

        self.bg = self:addRect(630,self.height,0,0,0)
        --self.text = self:addTextToTexture("1x",self.bg,"nevisSmallTitle")
        self.color = {.3,.3,.3}
        self.buttonHash = {}
        local x,y = 5,-5
        self.buttonWidth=47
        self.buttonHeight=40
        for i,v in ipairs(self.controls) do
            if v.newLine then
                x = 5
                y = y-self.buttonHeight-5
            end

            local r = self:addRect(v.width or self.buttonWidth,self.buttonHeight,unpack(v.color or self.color))
            r:setLoc(x,y)
            if v.label then
                self:addTextToTexture(v.label, r, "nevisSmallTitle")
            elseif v.readout then
                self.text = self:addTextToTexture("1x", r, "nevisSmallTitle")
            end
            if v.fn then self.buttonHash[r] = v.fn end
            x = x+(v.width or self.buttonWidth)+5
        end
        
        -- "EDIT MODE" indicator (updated in GameRules)
        local editTextBox = self:addRect(200, self.buttonHeight, unpack(self.color))
        editTextBox:setLoc(5, y - self.buttonHeight)
        editTextBox:setVisible(false)
        self.editText = self:addTextToTexture('', editTextBox, "nevisSmallTitle")
    end

    function Ob:inside(wx,wy)
        return self.bg:inside(wx,wy)
    end

    function Ob:refresh()
        self.text:setString(tostring(GameRules.playerTimeScale).."x")
    end
    
    function Ob:onFinger(touch, x, y, props)
        if touch.eventType == DFInput.TOUCH_UP then
            for _,v in ipairs(props) do
                local fn = self.buttonHash[v]
                if fn then
                    print("calling on",v)
                    fn(self)
                    --return true
                end
            end
        end
    end

    return Ob
end

function m.new(...)
    local Ob = m.create()
    Ob:init(...)

    return Ob
end

return m
