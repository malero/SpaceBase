local Gui = require('UI.Gui')

local nControlButtonX, nControlButtonY = 0,0
local nControlButtonWidth, nControlButtonHeight = 205, 37
local labelX, labelY = 0, nControlButtonY - 5

return
{
    posInfo =
    {
        alignX = 'left',
        alignY = 'top',
        offsetX = 0,
        offsetY = 0,
    },
    tExtraInfo =
    {
    },
    tElements =
    {
        {
            key = 'ActionButton',
            type = 'onePixelButton',
            pos = { nControlButtonX, nControlButtonY },
            scale = { nControlButtonWidth, nControlButtonHeight },
            color = Gui.RED,
			hidden = true,
            onHoverOn =
            {
                { key = 'ActionLabel', color = Gui.BLACK, },
				{ key = 'ActionButtonTexture', hidden = true, },
				{ key = 'ActionButtonTexturePressed', hidden = false, },
                { playSfx = 'hilight', },
            },
            onHoverOff =
            {
                { key = 'ActionLabel', color = Gui.AMBER, },
				{ key = 'ActionButtonTexture', hidden = false, },
				{ key = 'ActionButtonTexturePressed', hidden = true, },
            },
			onSelectedOn =
			{
				{ key = 'ActionLabel', color = Gui.BLACK, },
				{ key = 'ActionButtonTexture', hidden = true, },
				{ key = 'ActionButtonTexturePressed', hidden = false, },
                { playSfx = 'hilight', },
			},
            onSelectedOff =
            {
                { key = 'ActionLabel', color = Gui.AMBER, },
				{ key = 'ActionButtonTexture', hidden = false, },
				{ key = 'ActionButtonTexturePressed', hidden = true, },
            },
			onDisabledOn =
            {
                { key = 'ActionLabel', color = Gui.AMBER_OPAQUE, },
				{ key = 'ActionButtonTexture', color = Gui.AMBER_OPAQUE },
            },
			onDisabledOff =
            {
                { key = 'ActionLabel', color = Gui.AMBER, },
				{ key = 'ActionButtonTexture', color = Gui.AMBER },
            },
        },
 		{
			key = 'ActionButtonTexture',
			type = 'uiTexture',
            textureName = 'buttonbig',
            sSpritesheetPath = 'UI/Shared',
			pos = { nControlButtonX, nControlButtonY },
			scale = { 1, 1 },
			color = Gui.AMBER,
		},
		{
			key = 'ActionButtonTexturePressed',
			type = 'uiTexture',
            textureName = 'buttonbig_pressed',
            sSpritesheetPath = 'UI/Shared',
			pos = { nControlButtonX, nControlButtonY },
			scale = { 1, 1 },
			color = Gui.AMBER,
			hidden = true,
		},
        {
            key = 'ActionLabel',
            type = 'textBox',
            pos = { nControlButtonX + labelX, labelY },
			linecode = 'ZONEUI072TEXT',
            style = 'dosissemibold20',
            rect = { 0, 100, nControlButtonWidth, 0 },
            hAlign = MOAITextBox.CENTER_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
    },
}
