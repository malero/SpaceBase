local Gui = require('UI.Gui')
local DFUtil = require("DFCommon.Util")
local UIElement = require('UI.UIElement')
local Renderer = require('Renderer')
local Character = require('Character')
local CharacterManager = require('CharacterManager')

local m = {}

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())

    --[[
    Ob.jobs=
    {
        {name="UNEMPLOYED",desc="Occasionally pitches in.", enum=Character.UNEMPLOYED},
        {name="ENGINEER",desc="Engineers stuff.", enum=Character.ENGINEER},
        {name="DOCTOR",desc="Doctors stuff.", enum=Character.DOCTOR},
        {name="BARTENDER",desc="Bartends stuff.", enum=Character.BARTENDER},
        {name="MAINTENANCE",desc="Maintains stuff.", enum=Character.MAINTENANCE},
        {name="SCIENTIST",desc="Sciences stuff.", enum=Character.SCIENTIST},
    }
    ]]--
    
    function Ob:init(width, tOptions, user, testFn, callbackFn, bHideSelected)
        Ob.Parent.init(self)

        self.width = width
        self.height = 40
        self.color = {0/255,115/255,186/255}
        self.darkColor = {0/255,0/255,0/255}
        self.highlightColor = {0/255,80/255,135/255}
        self.bg = self:addRect(width,1,unpack(self.color))
        self.buttonHash = {}
        local margin=5
        local marginInner=7
        local boxh=150
        local y=-margin
        self.tOptions = tOptions
        self.testFn = testFn
        self.callbackFn = callbackFn
        self.user = user
        self.bHideSelected = bHideSelected
        for i,j in ipairs(self.tOptions) do
            local r = self:addRect(width-2*margin,boxh,unpack(self.darkColor))
            r:setLoc(margin,y)
            self.buttonHash[r] = i

            r = self:addRect(width-2*marginInner,boxh-4,unpack(self.color))
            self.buttonHash[r] = i
            j.unselectedRect = r
            r:setLoc(marginInner,y-2)

            r = self:addRect(width-2*marginInner,boxh-4,unpack(self.highlightColor))
            self.buttonHash[r] = i
            j.highlightRect = r
            r:setLoc(marginInner,y-2)

            local text = self:addTextBox(j.name, "gothicTitleWhite",0,0,width-marginInner*2,boxh*.5,margin*2,y-boxh*.5)
            text = self:addTextBox(j.desc, "nevisBodyWhite",0,0,width-marginInner*2,boxh*.5,margin*2,y-boxh)

            j.skillText = self:addTextBox("", "nevisBodyWhite",0,0,width-marginInner*2-10,boxh*.45,margin*2,y-boxh*.5, MOAITextBox.RIGHT_JUSTIFY, MOAITextBox.LEFT_JUSTIFY)
            j.currentText = self:addTextBox("", "nevisBodyWhite",0,0,width-marginInner*2-10,boxh*.45,margin*2,y-boxh*.4, MOAITextBox.RIGHT_JUSTIFY, MOAITextBox.RIGHT_JUSTIFY)

            y=y-boxh-margin
        end
        self.bg:setScl(width,-y)
    end

    function Ob:updateSelected()
        self.target = g_GuiManager.rSelected
        if not self.target then
            self:hide()
        else
            for i,j in ipairs(self.tOptions) do
                if self.testFn(self.user, j) then
                    j.highlightRect:setVisible(true)
                    j.unselectedRect:setVisible(false)
                else
                    j.highlightRect:setVisible(false)
                    j.unselectedRect:setVisible(true)
                end
            end
        end
    end

    function Ob:inside(wx,wy)
        return self.bg:inside(wx,wy)
    end

    function Ob:show(basePri)
        local pri = Ob.Parent.show(self,basePri)
        self:refresh()
        return pri
    end

    function Ob:refresh()
        self:updateSelected()
    end

    function Ob:onFinger(touch, x, y, props)
        for _,v in ipairs(props) do
            local idx = self.buttonHash[v]
            if idx then
                self.callbackFn(self.user, self.tOptions[idx])
                return true
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
