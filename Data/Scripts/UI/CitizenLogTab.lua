local m = {}

local DFUtil = require("DFCommon.Util")
local DFInput = require('DFCommon.Input')
local CitizenLogEntry = require('UI.CitizenLogEntry')
local UIElement = require('UI.UIElement')

local sUILayoutFileName = 'UILayouts/CitizenLogLayout'

local kMAX_ENTRIES = 20 -- for now

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())
    Ob.rCitizen = nil
    Ob.tLogEntries = {}
    Ob.bDoRolloverCheck = true

    function Ob:init()
        self:processUIInfo(sUILayoutFileName)
        Ob.Parent.init(self)

        for i = 1, kMAX_ENTRIES do
            local rLogEntry = CitizenLogEntry.new()
            self:addElement(rLogEntry)
            rLogEntry:setIndex(i)
            table.insert(self.tLogEntries, rLogEntry)
        end
    end

    function Ob:onTick(dt)
        self.uiHeight=0
        if self.rCitizen then
            if self.rCitizen.tLog then
                local y=0
                for i, rLog in ipairs(self.tLogEntries) do
                    local rEntry = self.rCitizen.tLog[#self.rCitizen.tLog-(i - 1)]
                    if rEntry then
                        rLog:setLogEntry(rEntry)
                    else
                        rLog:setLogEntry(nil)
                    end
                    local w,h = rLog:getDims()
                    rLog:setLoc(0,y)
                    y=y+h
                end
                self:_calcDimsFromElements()
                self.rParentUIElement.rParentUIElement:_updateContentSize()
                self.rParentUIElement.rParentUIElement:refresh()
            end
        end
    end

    function Ob:setCitizen(rCitizen)
        self.rCitizen = rCitizen        
    end

    function Ob:setHostileMode(bSet)
        self.bHostileMode = bSet
        if bSet then
            local tOverrides = self:getExtraTemplateInfo('tHostileMode')
            if tOverrides then
                self:applyTemplateInfos(tOverrides)
            end
        else
            local tOverrides = self:getExtraTemplateInfo('tCitizenMode')
            if tOverrides then
                self:applyTemplateInfos(tOverrides)
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
