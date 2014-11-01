local Gui = require('UI.Gui')

local buttonWidth, buttonHeight, buttonSpacing = 120, 35, 10
local buttonX, buttonY = 18, -225
local labelY = -191

return
{
    posInfo =
	{
        alignX = 'left',
        alignY = 'top',
        offsetX = 0,
        offsetY = -30,
    },
    tElements =
    {
        {
            key = 'NormalButton',
            type = 'onePixelButton',
            pos = { buttonX, buttonY },
            scale = { buttonWidth, buttonHeight },
            color = Gui.BLACK_NO_ALPHA,
			hidden = true,
            clickWhileHidden=true,
            onHoverOn =
            {
                { key = 'NormalLabel', color = Gui.BLACK, },
                { key = 'NormalButtonTexture', hidden = true, },
                { key = 'NormalButtonTexturePressed', hidden = false, },
            },
            onHoverOff =
            {
                { key = 'NormalLabel', color = Gui.AMBER, },
                { key = 'NormalButtonTexture', hidden = false, },
                { key = 'NormalButtonTexturePressed', hidden = true, },
            },
			onDisabledOn =
            {
				{ key = 'NormalLabel', color = Gui.AMBER_OPAQUE, },
                { key = 'NormalButtonTexture', color = Gui.AMBER_OPAQUE, },
                { key = 'NormalButtonTexturePressed', color = Gui.AMBER_OPAQUE, },
			},
			onDisabledOff =
            {
				{ key = 'NormalLabel', color = Gui.AMBER, },
                { key = 'NormalButtonTexture', color = Gui.AMBER, },
                { key = 'NormalButtonTexturePressed', color = Gui.AMBER, },
			},
        },
		{
			key = 'NormalButtonTexture',
			type = 'uiTexture',
            textureName = 'buttontoggle3_left',
            sSpritesheetPath = 'UI/Shared',
			pos = { buttonX, buttonY },
			scale = { 1, 1 },
			color = Gui.AMBER,
		},
		{
			key = 'NormalButtonTexturePressed',
			type = 'uiTexture',
            textureName = 'buttontoggle3_left_pressed',
            sSpritesheetPath = 'UI/Shared',
			pos = { buttonX, buttonY },
			scale = { 1, 1 },
			color = Gui.AMBER,
			hidden = true,
		},
        {
            key = 'NormalLabel',
            type = 'textBox',
            pos = { 27, labelY },
			linecode = 'PROPSX037TEXT',
            style = 'dosissemibold22',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.CENTER_JUSTIFY,
            vAlign = MOAITextBox.CENTER_JUSTIFY,
            color = Gui.AMBER,
        },

        {
            key = 'LockedButton',
            type = 'onePixelButton',
            pos = { buttonX + buttonWidth + buttonSpacing, buttonY },
            scale = { buttonWidth, buttonHeight },
            color = Gui.BLACK_NO_ALPHA,
			hidden = true,
            clickWhileHidden=true,
            onHoverOn =
            {
                { key = 'LockedLabel', color = Gui.BLACK, },
				{ key = 'LockedButtonTexture', hidden = true, },
				{ key = 'LockedButtonTexturePressed', hidden = false, },
            },
            onHoverOff =
            {
                { key = 'LockedLabel', color = Gui.AMBER, },
				{ key = 'LockedButtonTexture', hidden = false, },
				{ key = 'LockedButtonTexturePressed', hidden = true, },
            },
			onDisabledOn =
            {
				{ key = 'LockedLabel', color = Gui.AMBER_OPAQUE, },
                { key = 'LockedButtonTexture', color = Gui.AMBER_OPAQUE, },
                { key = 'LockedButtonTexturePressed', color = Gui.AMBER_OPAQUE, },
			},
			onDisabledOff =
            {
				{ key = 'LockedLabel', color = Gui.AMBER, },
                { key = 'LockedButtonTexture', color = Gui.AMBER, },
                { key = 'LockedButtonTexturePressed', color = Gui.AMBER, },
			},
        },
		{
			key = 'LockedButtonTexture',
			type = 'uiTexture',
            textureName = 'buttontoggle3_mid',
            sSpritesheetPath = 'UI/Shared',
			pos = { buttonX + buttonWidth, buttonY },
			scale = { 1, 1 },
			color = Gui.AMBER,
		},
		{
			key = 'LockedButtonTexturePressed',
			type = 'uiTexture',
            textureName = 'buttontoggle3_mid_pressed',
            sSpritesheetPath = 'UI/Shared',
			pos = { buttonX + buttonWidth, buttonY },
			scale = { 1, 1 },
			color = Gui.AMBER,
			hidden = true,
		},
        {
            key = 'LockedLabel',
            type = 'textBox',
            pos = { 158, labelY },
			linecode = 'PROPSX038TEXT',
            style = 'dosissemibold22',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.CENTER_JUSTIFY,
            vAlign = MOAITextBox.CENTER_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'ForcedButton',
            type = 'onePixelButton',
            pos = { buttonX + (buttonWidth*2) + (buttonSpacing*2), buttonY },
            scale = { buttonWidth, buttonHeight },
            color = Gui.BLACK_NO_ALPHA,
			hidden = true,
            clickWhileHidden=true,
            onHoverOn =
            {
                { key = 'ForcedLabel', color = Gui.BLACK, },
				{ key = 'ForcedButtonTexture', hidden = true, },
				{ key = 'ForcedButtonTexturePressed', hidden = false, },
            },
            onHoverOff =
            {
                { key = 'ForcedLabel', color = Gui.AMBER, },
				{ key = 'ForcedButtonTexture', hidden = false, },
				{ key = 'ForcedButtonTexturePressed', hidden = true, },
            },
			onDisabledOn =
            {
				{ key = 'ForcedLabel', color = Gui.AMBER_OPAQUE, },
                { key = 'ForcedButtonTexture', color = Gui.AMBER_OPAQUE, },
                { key = 'ForcedButtonTexturePressed', color = Gui.AMBER_OPAQUE, },
			},
			onDisabledOff =
            {
				{ key = 'ForcedLabel', color = Gui.AMBER, },
                { key = 'ForcedButtonTexture', color = Gui.AMBER, },
                { key = 'ForcedButtonTexturePressed', color = Gui.AMBER, },
			},
        },
		{
			key = 'ForcedButtonTexture',
			type = 'uiTexture',
            textureName = 'buttontoggle3_right',
            sSpritesheetPath = 'UI/Shared',
			pos = { buttonX + (buttonWidth*2) + buttonSpacing+4, buttonY },
			scale = { 1, 1 },
			color = Gui.AMBER,
		},
		{
			key = 'ForcedButtonTexturePressed',
			type = 'uiTexture',
            textureName = 'buttontoggle3_right_pressed',
            sSpritesheetPath = 'UI/Shared',
			pos = { buttonX + (buttonWidth*2) + buttonSpacing+4, buttonY },
			scale = { 1, 1 },
			color = Gui.AMBER,
			hidden = true,
		},
        {
            key = 'ForcedLabel',
            type = 'textBox',
            pos = { 290, labelY },
			linecode = 'PROPSX039TEXT',
            style = 'dosissemibold22',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.CENTER_JUSTIFY,
            vAlign = MOAITextBox.CENTER_JUSTIFY,
            color = Gui.AMBER,
        },
    },
}
