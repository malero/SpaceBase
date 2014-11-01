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
local numButtons = 4
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
            key = 'ClearBeaconButton',
            type = 'onePixelButton',
            pos = { 0, nButtonStartY },
            scale = { nButtonWidth, nButtonHeight },
            color = Gui.BLACK,
            onHoverOn =
            {
                { key = 'ClearBeaconButton', color = Gui.AMBER, },
                { key = 'ClearBeaconLabel', color = Gui.BLACK, },
                { key = 'ClearBeaconIcon', color = Gui.BLACK, },
                { key = 'ClearBeaconHotkey', color = Gui.BLACK, },
                { playSfx = 'hilight', },
            },
            onHoverOff =
            {
                { key = 'ClearBeaconButton', color = Gui.BLACK, },
                { key = 'ClearBeaconLabel', color = Gui.AMBER, },
                { key = 'ClearBeaconIcon', color = Gui.AMBER, },
                { key = 'ClearBeaconHotkey', color = Gui.AMBER, },
            },
        },
        {
            key = 'ClearBeaconIcon',
            type = 'uiTexture',
            textureName = 'ui_iconIso_erase',
            sSpritesheetPath = 'UI/Shared',
            pos = { nIconX, nIconStartY },
            color = Gui.AMBER,
            scale = { nIconScale, nIconScale }
        },
        {
            key = 'ClearBeaconLabel',
            type = 'textBox',
            pos = { nLabelX, nLabelStartY },
            linecode = 'HUDHUD037TEXT',
            style = 'dosisregular40',
            rect = { 0, 300, 280, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'ViolenceLowButton',
            type = 'templateButton',
            layoutFile = 'UILayouts/SidebarButtonLayout',
            replacements = {
                SidebarLabel={linecode='HUDHUD051TEXT', pos={nLabelNoIconX, nLabelButtonStartY}, color=Gui.GREEN},
                SidebarIcon={hidden=true, },
            },
            buttonName='SidebarButton',
            pos = { 0, nButtonStartY-nButtonHeight },
        },
        {
            key = 'ViolenceDefaultButton',
            type = 'templateButton',
            layoutFile = 'UILayouts/SidebarButtonLayout',
            replacements = {
                SidebarLabel={linecode='HUDHUD049TEXT', pos={nLabelNoIconX, nLabelButtonStartY} },
                SidebarIcon={hidden=true, },
            },
            buttonName='SidebarButton',
            pos = { 0, nButtonStartY-nButtonHeight*2 },
        },
        {
            key = 'ViolenceHighButton',
            type = 'templateButton',
            layoutFile = 'UILayouts/SidebarButtonLayout',
            replacements = {
                SidebarLabel={linecode='HUDHUD050TEXT', pos={nLabelNoIconX, nLabelButtonStartY}, color=Gui.RED},
                SidebarIcon={ hidden=true, },
            },
            buttonName='SidebarButton',
            pos = { 0, nButtonStartY-nButtonHeight*3 },
        },
        {
            key = 'MenuSublabel',
            type = 'textBox',
            pos = { 40, -90 },
            linecode = "HUDHUD036TEXT",
            style = 'dosissemibold22',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.GREY,
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
            key = 'ClearBeaconHotkey',
            type = 'textBox',
            pos = { nHotkeyX, nHotkeyStartY },
            text = 'X',
            style = 'dosissemibold22',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
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
