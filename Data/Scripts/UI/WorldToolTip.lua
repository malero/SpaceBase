local m = {}

local DFUtil = require('DFCommon.Util')
local UIElement = require('UI.UIElement')
local Gui = require('UI.Gui')

local sUILayoutFileName = 'UILayouts/WorldToolTipLayout'
local kHEIGHT_PER_LINE = 32
local kMARGIN = 14
local kYMARGIN = 10
local kWIDTH_PER_CHAR = 14
local kTEXTURE_MARGIN = 30

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())
    Ob.rCurTarget = nil
    Ob.nOffsetX = 68
    Ob.nOffsetY = -30
    Ob.tTipTexts = {}
    Ob.tTipTextures = {}

    function Ob:init()
        self:processUIInfo(sUILayoutFileName)
        Ob.Parent.init(self)

        local nIndex = 1
        while true do
            local rTipText = self:getTemplateElement('TipText'..nIndex)
            if rTipText then
                self.tTipTexts[nIndex] = rTipText
                nIndex = nIndex + 1
            else
                break
            end
        end
        nIndex = 1
        while true do
            local rTipTexture = self:getTemplateElement('TipTexture'..nIndex)
            if rTipTexture then
                self.tTipTextures[nIndex] = rTipTexture
                nIndex = nIndex + 1
            else
                break
            end
        end

        self.rBackground = self:getTemplateElement('Background')
        self.rTopBorder = self:getTemplateElement('TopBorder')
        self.rBottomBorder = self:getTemplateElement('BottomBorder')
        self.rLeftBorder = self:getTemplateElement('LeftBorder')
        self.rRightBorder = self:getTemplateElement('RightBorder')

        local _, y = self.rTopBorder:getScl()
        self.nBorderThickness = y
    end

    function Ob:getCursorOffset()
        return self.nOffsetX, self.nOffsetY
    end

    function Ob:setTarget(rTarget)
        self.rCurTarget = rTarget
    end

    function Ob:_adjustTooltipSize(nNumEntries, nTextWidth, bAddedTexture)
        local nHeight = kHEIGHT_PER_LINE * nNumEntries + kYMARGIN * 2
        local nWidth = nTextWidth + kMARGIN * 2
        if bAddedTexture then
            nWidth = nWidth + kTEXTURE_MARGIN
        end

        self.rBackground:setScl(nWidth, nHeight)        
        self.rTopBorder:setScl(nWidth, self.nBorderThickness)
        self.rBottomBorder:setScl(nWidth, self.nBorderThickness)
        self.rBottomBorder:setLoc(0, -(nHeight - self.nBorderThickness))
        self.rLeftBorder:setScl(self.nBorderThickness, nHeight)
        self.rRightBorder:setScl(self.nBorderThickness, nHeight)
        self.rRightBorder:setLoc(nWidth, 0)
    end

    function Ob:onTick(dt)
        if self.rCurTarget and self.rCurTarget.getToolTipTextInfos then
            local nNumEntries = 1
            local nMaxWidth = 0
            local bAddedTexture = false
            local tStringInfosToShow = self.rCurTarget:getToolTipTextInfos()
            -- reset the textures
            for i, rTipTexture in ipairs(self.tTipTextures) do
                local rHideTextureOverride = self:getExtraTemplateInfo('texture'..i..'HideOverride')
                if rHideTextureOverride then
                    self:applyTemplateInfos(rHideTextureOverride)
                    rTipTexture:setColor(unpack(Gui.AMBER))
                end
            end
            for i, rTipText in ipairs(self.tTipTexts) do
                local rInfo = tStringInfosToShow[nNumEntries]
                if rInfo and rInfo.sString and rInfo.sString ~= "" then
                    nNumEntries = nNumEntries + 1
                    rTipText:setString(rInfo.sString)
                    local x0, y0, x1, y1 = rTipText:getStringBounds(1, string.len(rInfo.sString))
                    local nWidth = math.abs(x1 - x0)
                    if nWidth > nMaxWidth then
                        nMaxWidth = nWidth
                    end
                    if rInfo.tColor then
                        rTipText:setColor(unpack(rInfo.tColor))
                    else
                        rTipText:setColor(unpack(Gui.AMBER))
                    end
                    if rInfo.sTexture and rInfo.sTextureSpriteSheet then
                        if self.tTipTextures[i] then
                            if self:setTemplateUITexture(self.tTipTextures[i].sKey, rInfo.sTexture, rInfo.sTextureSpriteSheet) then
                                local rShowTextureOverride = self:getExtraTemplateInfo('texture'..i..'ShowOverride')
                                if rShowTextureOverride then
                                    self:applyTemplateInfos(rShowTextureOverride)
                                end
                                if rInfo.tTextureColor then
                                    self.tTipTextures[i]:setColor(unpack(rInfo.tTextureColor))
                                end
                                bAddedTexture = true
                            end                            
                        end
                    end
                else
                    rTipText:setString("")
                end
            end
            nNumEntries = nNumEntries - 1 -- off by one.
            
            self:_adjustTooltipSize(nNumEntries, nMaxWidth, bAddedTexture)
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