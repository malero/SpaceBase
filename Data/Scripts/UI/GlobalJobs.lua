local Gui = require('UI.Gui')
local DFUtil = require("DFCommon.Util")
local DFInput = require('DFCommon.Input')
local DFMath = require("DFCommon.Math")
local UIElement = require('UI.UIElement')
local Renderer = require('Renderer')
local Character = require('Character')
local GameRules = require('GameRules')
local CharacterManager = require('CharacterManager')
local SoundManager = require('SoundManager')

local m = {}

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())
    
    function Ob:init(w)
        Ob.Parent.init(self)

        self.width = w
        self.color={0,0,0}
        self.colColor = {0/255,115/255,186/255}
        self.outlineColor = {0/255,0/255,0/255}
        self.highlightColor = {0/255,80/255,135/255}
        self.uiBG = self:addRect(w,1,unpack(self.color))
        local y = -30

        self.columns = {}
        local len = #Character.JOB_NAMES_CAPS
        self.cw = 330
        self.ch = 1300
        self.cm = 10
        self.xm = 5
        local i = 0
        self.columnHash = {}
        
        for i,nJob in ipairs(Character.DISPLAY_JOBS) do
            self.columns[nJob] = {}
            local x = self.cm+(self.cw+self.cm)*i
            local t = self.columns[nJob]
            t.x0 = x
            t.y0 = y
            t.bg = self:addRect(self.cw,self.ch,unpack(self.colColor))
            t.bg:setLoc(x, y)
            t.heading = self:addTextBox(g_LM.line(Character.JOB_NAMES_CAPS[nJob]), "gothicTitleWhite",0,0,self.cw,80,x,y-80, MOAITextBox.CENTER_JUSTIFY)
            t.entries = {}
            self.columnHash[t.bg] = i
            i=i+1
        end
        y=y-self.ch-30

        self.quitButton = self:addRect(self.cw, 100,unpack(self.colColor))
        self.quitButton:setLoc(kVirtualScreenWidth*.5-self.cw*.5,y)
        self.quitText = self:addTextToTexture("DONE", self.quitButton, "gothicTitleWhite")

        self.uiBG:setScl(self.width,math.abs(y))
    end

    function Ob:inside(wx,wy)
        return true
    end

    function Ob:onFinger(touch, x, y, props)
        if touch.eventType == DFInput.TOUCH_UP then
            for i,v in ipairs(props) do
                
                if v == self.quitButton then
                    GameRules.currentMode = GameRules.MODE_INSPECT
                    g_GuiManager.refresh()
                    SoundManager.playSfx("done")
                    g_GameRules.timeStandard()
                    return
                end
                
                if self.buttonHash[v] then
                    local entry = self.buttonHash[v]
                    
                    entry.selected = not entry.selected
                    if entry.selected then 
                        if self.selected then
                            self.selected.selected = false
                            self.selected.highlight:setVisible(false)
                        end
                        self.selected = entry 
                    end
                    entry.highlight:setVisible(entry.selected)
                    return true
                end
            end
        end
        for i,v in ipairs(props) do
            if self.columnHash[v] then
                local newJob = self.columnHash[v]
                if self.selected then
                    self.selected.char:setJob(newJob)
                    self.selected = nil
                    self:refresh()
                end
            end
        end
    end
    
    function Ob:onTick(dt)
    end

    function Ob:assignJob()
    end

    function Ob:refresh()
        local t = CharacterManager.getTeamCharacters(Character.TEAM_ID_PLAYER)

        self.buttonHash = {}

        for k,v in ipairs(self.columns) do
            for _,entry in ipairs(v.entries) do
                self:removeElement(entry.outline)
                self:removeElement(entry.rect)
                self:removeElement(entry.name)
                self:removeElement(entry.skills)
                self:removeElement(entry.highlight)
            end
            v.entries = {}
        end

        local margin = 5
        local thickness = 5
        local boxHeight = 100
        for i,v in ipairs(t) do
            local j = v:getJob()
            local col = self.columns[j]
            local x0,y0,x1,y1 = col.x0,col.y0
            local entries = self.columns[j].entries
            local entry = {}
            local y = -(margin + 100 + (boxHeight+margin)*#entries)
            table.insert(entries, entry)
            entry.outline = self:addRect(self.cw-2*margin, boxHeight, unpack(self.outlineColor))
            entry.outline:setLoc(x0+margin,y0+y)
            entry.rect = self:addRect(self.cw-2*margin-2*thickness, boxHeight-2*thickness, unpack(self.colColor))
            entry.rect:setLoc(x0+margin+thickness,y0+y-thickness)
            entry.highlight = self:addRect(self.cw-2*margin-2*thickness, boxHeight-2*thickness, unpack(self.highlightColor))
            entry.highlight:setLoc(x0+margin+thickness,y0+y-thickness)
            entry.highlight:setVisible(false)
            entry.name = self:addTextBox(v.tStats.sName, "gothicTitleWhite",0,0,self.cw-margin*2,80,x0+margin*4,y0+y-boxHeight*.8)
            local skills = "B:"..v:getJobCompetency(Character.BUILDER).." T:"..v:getJobCompetency(Character.TECHNICIAN).." M:"..v:getJobCompetency(Character.MINER).." E:"..v:getJobCompetency(Character.EMERGENCY).." R:"..v:getJobCompetency(Character.BARTENDER).." G:"..v:getJobCompetency(Character.BOTANIST)
            entry.skills = self:addTextBox(skills, "nevisBodyWhite",0,0,self.cw-margin*2,40,x0+margin*4,y0+y-boxHeight)

            self.buttonHash[entry.rect] = entry
            entry.char = v
            entry.col = col
        end
    end

    function Ob:show(basePri)
        local pri = Ob.Parent.show(self,basePri)
        SoundManager.playSfx("jobs")
        self:refresh()
        
        local uiX,uiY,uiW,uiH = Renderer.getUIViewportRect()
        
        local w,h = 1860,1600
        local x,y = (uiW - w) / 2, 16
        
        g_GuiManager.createEffectMaskBox(x,y,w,h,0.3) -- rect for wiggle and time
        
        g_GameRules.timePause()

        return pri
    end

    return Ob
end

function m.new(...)
    local Ob = m.create()
    Ob:init(...)

    return Ob
end

return m

