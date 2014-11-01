local Gui = require('UI.Gui')

local nButtonWidth, nButtonHeight  = 286, 98
local nHotkeyX, nHotkeyStartY = nButtonWidth - 110, -68

local nScrollAreaTopMargin = 160
local nRoomScrollerX = 400

local nZoneButtonX = 16
local nHeadingY = 110
local nHeadingHeight = 90
local nHeadingLineWidth = 4

local nZoneHeadingWidth = 402
local nProjectHeadingX = nZoneHeadingWidth + nZoneButtonX + 4
local nProjectHeadingWidth = 480

local nProjectTabY = 48
local nProjectTabScale = 1.25

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
            scale = { 'g_GuiManager.getUIViewportSizeX()', 'g_GuiManager.getUIViewportSizeY()' },
            color = Gui.SIDEBAR_BG,
        },
        {
            key = 'ZoneScrollPane',
            type = 'scrollPane',
            pos = { nRoomScrollerX, -nScrollAreaTopMargin },
			-- { upper left X, upper left Y, lower right X, lower right Y }
            rect = { 0, 0, 925, 'g_GuiManager.getUIViewportSizeY() - 192' },
            scissorLayerName='UIScrollLayerLeft',
        },
        {
            key = 'CancelButton',
            type = 'templateButton',
            layoutFile = 'UILayouts/ActionButtonLayout',
            replacements = {
                ActionLabel={linecode='INSPEC161TEXT'},
            },
            buttonName='ActionButtonTexture',
            pos = { nRoomScrollerX, -20 },
        },
        {
            key = 'SelectBedLabel',
            type = 'textBox',
            pos = { 380, -20 },
            linecode = 'INSPEC162TEXT',
            style = 'dosismedium44',
            rect = { 0, 300, 400, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
		-- zone select heading
        {
            key = 'ZoneHeadingShade',
            type = 'onePixel',
            pos = { nZoneButtonX, -nHeadingY },
            scale = { nZoneHeadingWidth, nHeadingHeight },
            color = Gui.AMBER_OPAQUE,
        },
        {
            key = 'ZoneHeadingDiv',
            type = 'onePixel',
            pos = { nZoneButtonX, -(nHeadingY + nHeadingHeight) },
            scale = { nZoneHeadingWidth, nHeadingLineWidth },
            color = Gui.AMBER,
        },
        {
            key = 'ZoneHeadingText',
            type = 'textBox',
            pos = { nZoneButtonX + 32, -nHeadingY - nHeadingHeight + 40 },
            linecode = 'RSCHUI003TEXT',
            style = 'dosissemibold26',
            rect = { 0, 300, 200, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
    },
}
