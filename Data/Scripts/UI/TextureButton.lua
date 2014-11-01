local UIElement = require('UI.UIElement')
local DFUtil = require("DFCommon.Util")
local Gui = require('UI.Gui')
local DFInput = require('DFCommon.Input')
local Button = require('UI.Button')

local m = {}

local PRESSED_SCALE_PCT = 0.7

function m.create()
    local Ob = DFUtil.createSubclass(Button.create())

    Ob.rTexture = nil
    Ob.tStates={'active','selected','hover','normal'}
    Ob.tTextures={}
    Ob.tColors={}

    function Ob:init(sRenderLayerName,sLayoutFileName)
        Ob.Parent.init(self,sRenderLayerName,sLayoutFileName)
    end

    function Ob:setTextures(tElementInfo)
        for i,v in ipairs(self.tStates) do
            if tElementInfo[v..'Texture'] then
                self:addToUISpriteSheets(tElementInfo[v..'Texture'], tElementInfo.sSpritesheetPath)
	            self.tTextures[v] = self:addTexture(tElementInfo[v..'Texture'])
            end
            if tElementInfo[v..'Color'] then
                self.tColors[v] = tElementInfo[v..'Color']
            end
        end
        self:_updateVisuals()
    end

    function Ob:_updateVisuals()
        self.sVisualState = 'normal'
        if self.bSelected then 
            self.sVisualState = 'selected'
        end

        if self.hideOverride then return end
        if self.sVisualState == self.sLastVisualState then return end

        local tColor = nil
        local sActiveTextureKey = nil
        local sActiveColorKey = nil

        local bUse = false
        for k,v in ipairs(self.tStates) do
            if v == self.sVisualState then bUse = true end
            if bUse and self.tTextures[v] then 
                sActiveTextureKey = v
                break
            end
        end

        bUse = false
        for k,v in ipairs(self.tStates) do
            if v == self.sVisualState then bUse = true end
            if bUse and self.tColors[v] then
                sActiveColorKey = v
                break
            end
        end

        for k,v in ipairs(self.tStates) do
            if self.tTextures[v] then
                self:setElementHidden(self.tTextures[v], v ~= sActiveTextureKey)
            end
        end
        if sActiveTextureKey and sActiveColorKey then
            self.tTextures[sActiveTextureKey]:setColor(unpack(self.tColors[sActiveColorKey]))
        end

        self.sLastVisualState = self.sVisualState
        self.sActiveTextureKey = sActiveTextureKey
        self.sActiveColorKey = sActiveColorKey
    end

    function Ob:inside(wx, wy)
        local bInside = false
        if self.sActiveTextureKey and self.tTextures[self.sActiveTextureKey]:inside(wx,wy) then
            bInside = true
        end

        if self.bLocked then
            self.bWasInside = bInside
            return false
        end

        if bInside ~= self.bWasInside then
            self:onHover(bInside)
            self:callHoverCallback(bInside)
        end

        self.bWasInside = bInside

        self:_updateVisuals()

        return bInside
    end
    
    function Ob:getDims()
        if self.sActiveTextureKey then 
            local w,h = self.tTextures[self.sActiveTextureKey]:getDims()
            local sx,sy = self:getScl()
            return sx*w,-h*sy
        else
            return Ob.Parent.getDims(self)
        end
    end
--[[
    function Ob:_inBounds(wx,wy)
        if not self.sActiveTextureKey or not self.tTextures[self.sActiveTextureKey]:_inBounds(wx,wy) then
            return false
        end
        return true
    end
]]--
    return Ob
end

function m.new(...)
    local Ob = m.create()
    Ob:init(...)

    return Ob
end

return m
