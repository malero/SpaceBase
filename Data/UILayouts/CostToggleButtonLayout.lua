local Gui = require('UI.Gui')

local nButtonX, nButtonY = 0, 0
local nButtonWidth, nButtonHeight  = 160, 37
local nCostWidth, nCostHeight = 200, 33
local nCostWidthSelected = 220
local nTextY = 33

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
            key = 'CostButton',
            type = 'onePixelButton',
            pos = { nButtonX, nButtonY },
            scale = { nButtonWidth, nButtonHeight },
            color = Gui.RED,
            hidden = true,
            clickWhileHidden=true,
            onHoverOn =
            {
                { key = 'ButtonLabel', color = Gui.BLACK, },
                { key = 'ButtonTexture', hidden = true },
                { key = 'ButtonTexturePressed', hidden = false },
				{ key = 'CostButton', color = Gui.GREEN, }, -- debug
                { playSfx = 'hilight', },
            },
            onHoverOff =
            {
                { key = 'ButtonLabel', color = Gui.AMBER, },
                { key = 'ButtonTexture', hidden = false },
                { key = 'ButtonTexturePressed', hidden = true },
				{ key = 'CostButton', color = Gui.RED, }, -- debug
            },
			onSelectedOn =
			{
                { key = 'ButtonLabel', color = Gui.BLACK, },
                { key = 'ButtonTexture', hidden = true },
                { key = 'ButtonTexturePressed', hidden = false },
                { playSfx = 'hilight', },
				{ key = 'CheckBoxTexture', hidden = true, },
				{ key = 'CheckBoxTexturePressed', hidden = false, },
				{ key = 'CostBox', color = Gui.GREEN, scale = { nCostWidthSelected, nCostHeight }, },
				{ key = 'CostBoxEndTexture', color = Gui.GREEN, pos = { nButtonX + nButtonWidth + nCostWidthSelected, nButtonY - 2 }, },
				{ key = 'CostLabel', color = Gui.BLACK, },
				{ key = 'CostIcon', color = Gui.BLACK, },
				{ key = 'CostText', color = Gui.BLACK, },
			},
			onSelectedOff =
			{
                { key = 'ButtonLabel', color = Gui.AMBER, },
                { key = 'ButtonTexture', hidden = false },
                { key = 'ButtonTexturePressed', hidden = true },
				{ key = 'CheckBoxTexture', hidden = false, },
				{ key = 'CheckBoxTexturePressed', hidden = true, },
				{ key = 'CostBox', color = Gui.BLACK, scale = { nCostWidth, nCostHeight }, },
				{ key = 'CostBoxEndTexture', color = Gui.BLACK, pos = { nButtonX + nButtonWidth + nCostWidth, nButtonY - 2 }, },
				{ key = 'CostLabel', color = Gui.AMBER, },
				{ key = 'CostIcon', color = Gui.AMBER, },
				{ key = 'CostText', color = Gui.AMBER, },
			},
			onDisabledOn =
			{
				{ key = 'ButtonLabel', color = Gui.AMBER_OPAQUE, },
                { key = 'ButtonTexture', color = Gui.AMBER_OPAQUE },
				{ key = 'CheckBoxTexture', color = Gui.AMBER_OPAQUE, },
				{ key = 'CostBox', color = Gui.AMBER_OPAQUE, },
				{ key = 'CostBoxEndTexture', color = Gui.AMBER_OPAQUE },
				{ key = 'CostLabel', color = Gui.BLACK, },
				{ key = 'CostIcon', color = Gui.BLACK, },
				{ key = 'CostText', color = Gui.BLACK, },
			},
			onDisabledOff =
			{
				{ key = 'ButtonLabel', color = Gui.AMBER, },
                { key = 'ButtonTexture', color = Gui.AMBER },
				{ key = 'CheckBoxTexture', color = Gui.AMBER, },
				{ key = 'CostBox', color = Gui.BLACK, },
				{ key = 'CostBoxEndTexture', color = Gui.BLACK },
				{ key = 'CostLabel', color = Gui.AMBER, },
				{ key = 'CostIcon', color = Gui.AMBER, },
				{ key = 'CostText', color = Gui.AMBER, },
			},
        },
		{
			key = 'ButtonTexture',
			type = 'uiTexture',
            textureName = 'button_medium',
            sSpritesheetPath = 'UI/Shared',
			pos = { nButtonX, nButtonY },
			scale = { 1, 1 },
			color = Gui.AMBER,
		},
		{
			key = 'ButtonTexturePressed',
			type = 'uiTexture',
            textureName = 'button_medium_pressed',
            sSpritesheetPath = 'UI/Shared',
			pos = { nButtonX, nButtonY },
			scale = { 1, 1 },
			color = Gui.AMBER,
			hidden = true,
		},
		{
			key = 'CheckBoxTexture',
			type = 'uiTexture',
            textureName = 'checkbox_empty',
            sSpritesheetPath = 'UI/Shared',
			pos = { nButtonX + 5, nButtonY - 5 },
			scale = { 0.85, 0.85 },
			color = Gui.AMBER,
		},
		{
			key = 'CheckBoxTexturePressed',
			type = 'uiTexture',
            textureName = 'checkbox_checked_inverse',
            sSpritesheetPath = 'UI/Shared',
			pos = { nButtonX + 5, nButtonY - 5 },
			scale = { 0.85, 0.85 },
			color = Gui.AMBER,
			hidden = true,
		},
        {
            key = 'ButtonLabel',
            type = 'textBox',
            pos = { nButtonX + 19, nButtonY + nTextY },
			linecode = 'INSPEC086TEXT',
            style = 'dosissemibold22',
            rect = { 0, 100, 150, 0 },
            hAlign = MOAITextBox.CENTER_JUSTIFY,
            vAlign = MOAITextBox.CENTER_JUSTIFY,
            color = Gui.AMBER,
        },
		{
            key = 'CostBox',
            type = 'onePixelButton',
            pos = { nButtonX + nButtonWidth, nButtonY - 2 },
            scale = { nCostWidth, nCostHeight },
            color = Gui.BLACK,
		},
		{
			key = 'CostBoxEndTexture',
			type = 'uiTexture',
            textureName = 'button_cost_flag',
            sSpritesheetPath = 'UI/Shared',
			pos = { nButtonX + nButtonWidth + nCostWidth - 1, nButtonY - 2 },
			scale = { 1, 1 },
			color = Gui.BLACK,
		},
        {
            key = 'CostLabel',
            type = 'textBox',
            pos = { nButtonX + nButtonWidth + 4, nButtonY + nTextY },
			linecode = 'INSPEC118TEXT',
            style = 'dosissemibold22',
            rect = { 0, 100, 175, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.CENTER_JUSTIFY,
            color = Gui.AMBER,
        },
		{
			key = 'CostIcon',
			type = 'uiTexture',
            textureName = 'ui_confirm_iconmatter',
            sSpritesheetPath = 'UI/Shared',
			pos = { nButtonX + nButtonWidth + 112, nButtonY - 10 },
			scale = { 1, 1 },
			color = Gui.AMBER,
		},
		{
            key = 'CostText',
            type = 'textBox',
            pos = { nButtonX + nButtonWidth + 102, nButtonY + nTextY },
			text = '11400',
            style = 'dosissemibold22',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.CENTER_JUSTIFY,
            vAlign = MOAITextBox.CENTER_JUSTIFY,
            color = Gui.AMBER,
        },
    },
}
