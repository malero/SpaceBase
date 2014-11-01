local Gui = require('UI.Gui')
local DFUtil = require("DFCommon.Util")
local DFInput = require('DFCommon.Input')
local UIElement = require('UI.UIElement')
local Renderer = require('Renderer')
local ObjectList = require('ObjectList')
local GameRules = require('GameRules')

-- MTF TODO
-- DELETE THIS CLASS
-- AlertPane can just pull from Base's list of ongoing events, and be more like hints.

local m = {
}

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())
    
    Ob.nNextID = 5
    Ob.entries = {}

    function Ob:init(w)
        Ob.Parent.init(self)
        
        self.logfilename = m._getLogDir() .. "testlog.json"
        local testlog = io.open( self.logfilename , "w")
        assertdev(testlog)
        if testlog then
            testlog:close()        
        end
    end

    function Ob:addEntityLogEntry(str, ent, nVisibleDuration, nPrevID)
        assertdev(ent and ent.tag)
        if not ent or not ent.tag then return end

        self:_addLogEntry(str, nil, nil, ent, nVisibleDuration, nPrevID)
    end

    function Ob:addLogEntry(str, x, y, nVisibleDuration, nPrevID)
        return self:_addLogEntry(str, x, y, nil, nVisibleDuration, nPrevID)
    end

    function Ob:_addLogEntry(str, x, y, ent, nVisibleDuration, nPrevID)
        local entry = {}
        local bReused = false

        if nPrevID then
            for i,v in ipairs(self.entries) do
                if v.nLogID == nPrevID then
                    entry = v
                    bReused = true
                    break
                end
            end
        end

        entry.starDate = GameRules.sStarDate
        entry.nStartTime = GameRules.elapsedTime
        local nDefaultTime = self.DEFAULT_LOG_VISIBLE_TIME
        entry.nEndVisibleTime = entry.nStartTime + (nVisibleDuration or nDefaultTime)
        entry.x = x
        entry.y = y
        if ent then entry.objTag = ent.tag end
        entry.str = str
        if not bReused then
            entry.nLogID = Ob.nNextID
            Ob.nNextID = Ob.nNextID+1
        end

        if not bReused then
            table.insert(self.entries, entry)
            local testlog = io.open (self.logfilename , "a")
    
            local sEntryX=x or 'nil'
            local sEntryY=y or 'nil'
            if ent and not x then
                x,y = ent:getLoc()
            end
    
            local externalentry = "{".."["..sEntryX..","..sEntryY.."]"..",".."\""..entry.starDate.."\""..",".."\""..entry.str.."\"".."}"
            assertdev(testlog)
            if testlog then
                testlog:write(externalentry .. ",\n")
                testlog:close()        
            end
        end

        return entry
    end

    function Ob:getLogEntries()
        return self.entries
    end
    
    function Ob:clearLogEntries()
        -- need to clear out the file?
        self.entries = {}
    end

    function Ob:onTick()
        local i = #self.entries
        while i > 0 do
            local rEntry = self.entries[i]
            if rEntry.nEndVisibleTime < GameRules.elapsedTime then
                table.remove(self.entries,i)
            end
            i = i-1
        end
    end

    return Ob
end

function m.new(...)
    local Ob = m.create()
    Ob:init(...)

    return Ob
end

function m._getLogDir()
    local logDir = MOAIEnvironment.documentDirectory .. "/Logs/"
     MOAIFileSystem.affirmPath(logDir)
    return logDir
end

return m
