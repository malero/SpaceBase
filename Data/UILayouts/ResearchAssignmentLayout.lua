local Gui = require('UI.Gui')

local nButtonWidth, nButtonHeight  = 286, 98
local nHotkeyX, nHotkeyStartY = nButtonWidth - 110, -68

local nScrollAreaTopMargin = 160

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
            key = 'ProjectScrollPane',
            type = 'scrollPane',
            pos = { 1000, -nScrollAreaTopMargin },
            rect = { 0, 0, 970, '(g_GuiManager.getUIViewportSizeY() - 192)' },
            scissorLayerName='UIScrollLayerRight',
        },
        {
            key = 'ZoneScrollPane',
            type = 'scrollPane',
            pos = { 0, -nScrollAreaTopMargin },
			-- { upper left X, upper left Y, lower right X, lower right Y }
            rect = { 0, 0, 925, 'g_GuiManager.getUIViewportSizeY() - 192' },
            scissorLayerName='UIScrollLayerLeft',
        },
        {
            key = 'BackButton',
            type = 'onePixelButton',
            pos = { 0, 0 },
            scale = { nButtonWidth, nButtonHeight },
            color = Gui.BLACK,
            onPressed =
            {
                { key = 'BackButton', color = Gui.AMBER, },
            },
            onReleased =
            {
                { key = 'BackButton', color = Gui.AMBER, },
            },
            onHoverOn =
            {
                { key = 'BackButton', color = Gui.AMBER, },
                { key = 'BackLabel', color = Gui.BLACK },
                { key = 'BackHotkey', color = Gui.BLACK },
                { playSfx = 'hilight', },
            },
            onHoverOff =
            {
                { key = 'BackButton', color = Gui.BLACK, },
                { key = 'BackLabel', color = Gui.AMBER, },
                { key = 'BackHotkey', color = Gui.AMBER, },
            },
        },
		-- back button / research heading
        {
            key = 'BackLabel',
            type = 'textBox',
            pos = { 96, -20 },
            linecode = 'HUDHUD035TEXT',
            style = 'dosisregular40',
            rect = { 0, 300, 200, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'BackHotkey',
            type = 'textBox',
            pos = { nHotkeyX, -60 },
            text = 'ESC',
            style = 'dosissemibold22',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'ResearchLabel',
            type = 'textBox',
            pos = { 380, -20 },
            linecode = 'HUDHUD048TEXT',
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
		-- project select heading
        {
            key = 'ProjectHeadingShade',
            type = 'onePixel',
            pos = { nProjectHeadingX, -nHeadingY },
            scale = { nProjectHeadingWidth, nHeadingHeight },
            color = Gui.AMBER_OPAQUE,
        },
        {
            key = 'ProjectHeadingDiv',
            type = 'onePixel',
            pos = { nProjectHeadingX, -(nHeadingY + nHeadingHeight) },
            scale = { nProjectHeadingWidth, nHeadingLineWidth },
            color = Gui.AMBER,
        },
        {
            key = 'ProjectHeadingText',
            type = 'textBox',
            pos = { nProjectHeadingX + 32, -nHeadingY - nHeadingHeight + 40 },
            linecode = 'RSCHUI004TEXT',
            style = 'dosissemibold26',
            rect = { 0, 300, 200, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
		-- tech/disease project tabs
        {
            key = 'TechTabButton',
            type = 'templateButton',
            layoutFile = 'UILayouts/TabButtonLayout',
            replacements = {
                TabText={linecode='RSCHUI005TEXT'},
                ActiveTabTexture={scale = {nProjectTabScale, nProjectTabScale},},
                InactiveTabTexture={scale = {nProjectTabScale, nProjectTabScale},},
            },
            buttonName='ActiveTabTexture',
            pos = { 1000, -nProjectTabY },
        },
        {
            key = 'DiseaseTabButton',
            type = 'templateButton',
            layoutFile = 'UILayouts/TabButtonLayout',
            replacements = {
                TabText={linecode='RSCHUI006TEXT'},
                ActiveTabTexture={scale = {nProjectTabScale, nProjectTabScale},},
                InactiveTabTexture={scale = {nProjectTabScale, nProjectTabScale},},
            },
            buttonName='ActiveTabTexture',
            pos = { 1000 + 172 * nProjectTabScale - 5, -nProjectTabY },
        },
		{
            key = 'TabLine',
            type = 'onePixel',
            pos = { 1000 + (172 * nProjectTabScale * 2) - 5, -nProjectTabY - (42 * nProjectTabScale) + 3},
            scale = { 515, 4 },
            color = Gui.AMBER,
        },		
    },
}
