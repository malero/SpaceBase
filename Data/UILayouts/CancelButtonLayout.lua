local Gui = require('UI.Gui')

local nButtonWidth,nButtonHeight = 31, 31

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
            key = 'CancelButton',
            type = 'onePixelButton',
            pos = { 0, 0 },
            scale = { nButtonWidth, nButtonHeight },
            color = Gui.RED,
			hidden = true,
            onHoverOn =
            {
				{ key = 'CancelButtonTexture', hidden = true, },
				{ key = 'CancelButtonTexturePressed', hidden = false, },
                { playSfx = 'hilight', },
            },
            onHoverOff =
            {
				{ key = 'CancelButtonTexture', hidden = false, },
				{ key = 'CancelButtonTexturePressed', hidden = true, },
            },
			onDisabledOn =
            {
				{ key = 'CancelButtonTexture', color = Gui.AMBER_OPAQUE },
            },
			onDisabledOff =
            {
				{ key = 'CancelButtonTexture', color = Gui.AMBER },
            },
        },
 		{
			key = 'CancelButtonTexture',
			type = 'uiTexture',
            textureName = 'checkbox_xed',
            sSpritesheetPath = 'UI/Shared',
			pos = { 0, 0 },
			scale = { 1, 1 },
			color = Gui.AMBER,
		},
		{
			key = 'CancelButtonTexturePressed',
			type = 'uiTexture',
            textureName = 'checkbox_xed_inverse',
            sSpritesheetPath = 'UI/Shared',
			pos = { 0, 0 },
			scale = { 1, 1 },
			color = Gui.AMBER,
			hidden = true,
		},
    },
}
