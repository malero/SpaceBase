local Class=require('Class')
--[[
local DFMath=require('DFCommon.Math')
local OptionData = require('Utility.OptionData')
local Needs = require('Utility.Needs')
local World=require('World')
]]--

local ActivityOptionList = Class.create()

function ActivityOptionList:init(rOwner)
    self.tList = {}
    self.rOwner = rOwner
end

function ActivityOptionList:addOption(ao, bTestExisting)
    if bTestExisting then
        for oldOption, _ in pairs(self.tList) do
            if self:_compare(ao,oldOption) then
                return
            end
        end
    end
    self.tList[ao] = true
end

function ActivityOptionList:removeOption(ao)
    assert(self.tList[ao])
    if ao:reserved() then
        -- MTF TODO: fix why this occurs when building an object.
        print('removing reserved activity',ao.name)
    end
    self.tList[ao] = nil
end

function ActivityOptionList:_compare(a,b)
    if a.name ~= b.name then return false end
    for k,v in pairs(a.tData) do
        if v ~= b.tData[k] and type(v) ~= 'function' then 
            --print('1. options differ',k,v,b.tData[k])
            return false 
        end
    end
    for k,v in pairs(b.tData) do
        if v ~= a.tData[k] and type(v) ~= 'function' then 
            --print('2. options differ',k,v,a.tData[k])
            return false 
        end
    end
    return true
end

function ActivityOptionList:set(tNewList)
    local tAdd = {}
    local tRemove = {}

    for oldOption, _ in pairs(self.tList) do
        tRemove[oldOption] = true
    end

    for newIdx, newOption in ipairs(tNewList) do
        local foundAs = nil
        for oldOption, _ in pairs(self.tList) do
            if self:_compare(newOption,oldOption) then
                foundAs = oldOption
                break
            end
        end
        if not foundAs then
            tAdd[newOption] = true
        else
            tRemove[foundAs] = nil
        end
    end

    for removeOption,_ in pairs(tRemove) do
        self:removeOption(removeOption)
    end
    for addOption,_ in pairs(tAdd) do
        self:addOption(addOption)
    end
end

function ActivityOptionList:getListAsUtilityOptions()
    local t = { rObject = self.rOwner, tUtilityOptions={} }
    for option,_ in pairs(self.tList) do
        table.insert(t.tUtilityOptions, option)
    end
    return t
end

function ActivityOptionList:getList()
    return self.tList
end

return ActivityOptionList
