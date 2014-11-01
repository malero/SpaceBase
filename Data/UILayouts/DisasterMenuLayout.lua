local Gui = require('UI.Gui')

local nButtonWidth, nButtonHeight  = 330, 81
local nTextHeight = nButtonHeight + 20
local nButtonStartY = -134
local nIconX, nIconStartY = 10, -136
local nDoneIconStartY = -2
local nLabelX, nLabelStartY = 94, -144
local nLabelNoIconX, nLabelButtonStartY = 10, -10
local nDoneLabelStartY = -10
local nHotkeyX, nHotkeyStartY = nButtonWidth - 112, -180
local nDoneHotkeyY = -46
local nIconScale = .6
local numButtons = 8
local nBGWidth = 160

return
{
    posInfo =
        {
        alignX = 'left',
        alignY = 'top',
        offsetX = 0,
        offsetY = 0,
        scale = { 1, 1 },
    },
    tElements =
    {
        {
            key = 'LargeBar',
            type = 'onePixel',
            pos = { 0, 0 },
            scale = { nButtonWidth, -nButtonStartY + (nButtonHeight * numButtons) },
            color = Gui.SIDEBAR_BG,
        },
        {
            key = 'DoneButton',
            type = 'onePixelButton',
            pos = { 0, 0 },
            scale = { nButtonWidth, nButtonHeight },
            color = Gui.BLACK,
            onHoverOn =
            {
                { key = 'DoneButton', color = Gui.AMBER, },
                { key = 'DoneLabel', color = Gui.BLACK, },
                { key = 'DoneHotkey', color = Gui.BLACK, },
                { playSfx = 'hilight', },
            },
            onHoverOff =
            {
                { key = 'DoneButton', color = Gui.BLACK, },
                { key = 'DoneLabel', color = Gui.AMBER, },
                { key = 'DoneHotkey', color = Gui.AMBER, },
            },
        },
        {
            key = 'DoneLabel',
            type = 'textBox',
            pos = { nLabelX, nDoneLabelStartY },
            linecode = 'HUDHUD035TEXT',
            style = 'dosisregular40',
            rect = { 0, 300, 200, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'DoneHotkey',
            type = 'textBox',
            pos = { nHotkeyX, nDoneHotkeyY },
            text = 'ESC',
            style = 'dosissemibold22',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'MenuSublabel',
            type = 'textBox',
            pos = { 40, -90 },
            linecode = "HUDHUD053TEXT",
            style = 'dosissemibold22',
            rect = { 0, 100, 200, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.GREY,
        },
        --
        -- fire
        --
        --raider breach, raider attack, raider dock, hostile derelict, killbot cube, parasite
        {
            key = 'FireButton',
            type = 'templateButton',
            layoutFile = 'UILayouts/SidebarButtonLayout',
            replacements = {
                SidebarLabel={linecode='HUDHUD054TEXT', pos={nLabelNoIconX, nLabelButtonStartY}},
                SidebarIcon={hidden=true, },
            },
            buttonName='SidebarButton',
            pos = { 0, nButtonStartY },
        },
        {
            key = 'MeteorButton',
            type = 'templateButton',
            layoutFile = 'UILayouts/SidebarButtonLayout',
            replacements = {
                SidebarLabel={linecode='HUDHUD055TEXT', pos={nLabelNoIconX, nLabelButtonStartY}},
                SidebarIcon={hidden=true, },
            },
            buttonName='SidebarButton',
            pos = { 0, nButtonStartY-nButtonHeight },
        },
        {
            key = 'KillbotButton',
            type = 'templateButton',
            layoutFile = 'UILayouts/SidebarButtonLayout',
            replacements = {
                SidebarLabel={linecode='HUDHUD056TEXT', pos={nLabelNoIconX, nLabelButtonStartY}},
                SidebarIcon={hidden=true, },
            },
            buttonName='SidebarButton',
            pos = { 0, nButtonStartY-nButtonHeight*2 },
        },
        {
            key = 'RaiderButton',
            type = 'templateButton',
            layoutFile = 'UILayouts/SidebarButtonLayout',
            replacements = {
                SidebarLabel={linecode='HUDHUD057TEXT', pos={nLabelNoIconX, nLabelButtonStartY}},
                SidebarIcon={hidden=true, },
            },
            buttonName='SidebarButton',
            pos = { 0, nButtonStartY-nButtonHeight*3 },
        },
        {
            key = 'BreachButton',
            type = 'templateButton',
            layoutFile = 'UILayouts/SidebarButtonLayout',
            replacements = {
                SidebarLabel={linecode='HUDHUD058TEXT', pos={nLabelNoIconX, nLabelButtonStartY}},
                SidebarIcon={hidden=true, },
            },
            buttonName='SidebarButton',
            pos = { 0, nButtonStartY-nButtonHeight*4 },
        },
        {
            key = 'ParasiteButton',
            type = 'templateButton',
            layoutFile = 'UILayouts/SidebarButtonLayout',
            replacements = {
                SidebarLabel={linecode='HUDHUD059TEXT', pos={nLabelNoIconX, nLabelButtonStartY}},
                SidebarIcon={hidden=true, },
            },
            buttonName='SidebarButton',
            pos = { 0, nButtonStartY-nButtonHeight*5 },
        },
        {
            key = 'DerelictButton',
            type = 'templateButton',
            layoutFile = 'UILayouts/SidebarButtonLayout',
            replacements = {
                SidebarLabel={linecode='HUDHUD060TEXT', pos={nLabelNoIconX, nLabelButtonStartY}},
                SidebarIcon={hidden=true, },
            },
            buttonName='SidebarButton',
            pos = { 0, nButtonStartY-nButtonHeight*6 },
        },
        {
            key = 'DockButton',
            type = 'templateButton',
            layoutFile = 'UILayouts/SidebarButtonLayout',
            replacements = {
                SidebarLabel={linecode='HUDHUD061TEXT', pos={nLabelNoIconX, nLabelButtonStartY}},
                SidebarIcon={hidden=true, },
            },
            buttonName='SidebarButton',
            pos = { 0, nButtonStartY-nButtonHeight*7 },
        },
        {
            key = 'SidebarBottomEndcapExpanded',
            type = 'uiTexture',
            textureName = 'ui_hud_anglebottom',
            sSpritesheetPath = 'UI/HUD',
            pos = { 0, nButtonStartY - numButtons*nButtonHeight },
            scale = { 1.28, 1.28 },
            color = Gui.SIDEBAR_BG,
        },
    },
}
