local Gui = require('UI.Gui')

local nButtonX = 16
local nZoneNameX = 48
local nProjectNameX = 450
local nTextY = 6
local nZoneButtonWidth,nZoneButtonHeight = 370, 64
local nProjectButtonWidth = 450
local nBubbleThickness = 2

return
{
    posInfo =
    {
        alignX = 'left',
        alignY = 'top',
        offsetX = 0,
        offsetY = 0,
    },
    tElements =
    {
        -- zone name + solid bubble
        {
            key = 'ZoneNameBubbleLeft',
            type = 'uiTexture',
            textureName = 'ui_circlefilled',
            sSpritesheetPath = 'UI/Shared',
            pos = { nButtonX, 0 },
            scale = {1, 1},
            color = Gui.AMBER,
        },
        {
            key = 'ZoneNameBubbleMid',
            type = 'uiTexture',
            textureName = 'ui_circlestraightfilled',
            sSpritesheetPath = 'UI/Shared',
            pos = { nButtonX + 32, 0 },
            scale = {(nZoneButtonWidth / 32), 1},
            color = Gui.AMBER,
        },
        -- draw BG beneath right of bubble
        {
            key = 'ProjectNameBubbleLeft',
            type = 'uiTexture',
            textureName = 'ui_circleinverse_inset_inv',
            sSpritesheetPath = 'UI/Shared',
            pos = { nButtonX + 32 + nZoneButtonWidth, 0 },
            scale = {1, 1},
            color = Gui.BLACK,
        },
        {
            key = 'ZoneNameBubbleRight',
            type = 'uiTexture',
            textureName = 'ui_circleinverse_inset',
            sSpritesheetPath = 'UI/Shared',
            pos = { nButtonX + 32 + nZoneButtonWidth, 0 },
            scale = {1, 1},
            color = Gui.AMBER,
        },
    	{
            key = 'ZoneName',
            type = 'textBox',
            pos = { nZoneNameX, -nTextY },
            text = "Zone Name",
            style = 'dosissemibold35',
            rect = { 0, 100, 600, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.BLACK,
		},
        -- project name + hollow bubble
        {
            key = 'ProjectNameBubbleMid',
            type = 'uiTexture',
            textureName = 'ui_circlestraight',
            sSpritesheetPath = 'UI/Shared',
            pos = { nProjectButtonWidth, 0 },
            scale = {(nProjectButtonWidth - 32) / 32, 1},
            color = Gui.AMBER,
        },
        {
            key = 'ProjectNameBubbleMidHole',
            type = 'uiTexture',
            textureName = 'ui_circlestraight_inv',
            sSpritesheetPath = 'UI/Shared',
            pos = { nButtonX + nZoneButtonWidth + 64, 0 },
            scale = {(nProjectButtonWidth - 32) / 32, 1},
            color = Gui.BLACK,
        },
        {
            key = 'ProjectNameBubbleRightHole',
            type = 'uiTexture',
            textureName = 'ui_circlefilled',
            sSpritesheetPath = 'UI/Shared',
            pos = { nButtonX + nZoneButtonWidth + 64 + nProjectButtonWidth, 0 },
            scale = {-1, 1},
            color = Gui.BLACK,
        },
        {
            key = 'ProjectNameBubbleRight',
            type = 'uiTexture',
            textureName = 'ui_circleempty',
            sSpritesheetPath = 'UI/Shared',
            pos = { nButtonX + nZoneButtonWidth + 64 + nProjectButtonWidth, 0 },
            scale = {-1, 1},
            color = Gui.AMBER,
        },
		{
            key = 'ProjectName',
            type = 'textBox',
            pos = { nProjectNameX, -nTextY },
            text = "Project Name",
            style = 'dosissemibold35',
            rect = { 0, 100, 600, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
		},
        {
            key = 'Button',
            type = 'onePixelButton',
            pos = { 64, 0 },
            scale = { 825, 50 },
            color = Gui.RED,
            hidden = true,
            onHoverOn =
            {
                { key = 'Button', color = Gui.GREEN, },
                { key = 'ProjectNameBubbleLeft', color = Gui.BROWN, },
                { key = 'ProjectNameBubbleMidHole', color = Gui.BROWN, },
                { key = 'ProjectNameBubbleRightHole', color = Gui.BROWN, },
                { key = 'ProjectName', color = Gui.BLACK, },
                { playSfx = 'hilight', },
            },
            onHoverOff =
            {
                { key = 'Button', color = Gui.RED, },
                { key = 'ProjectNameBubbleLeft', color = Gui.BLACK, },
                { key = 'ProjectNameBubbleMidHole', color = Gui.BLACK, },
                { key = 'ProjectNameBubbleRightHole', color = Gui.BLACK, },
                { key = 'ProjectName', color = Gui.AMBER, },
            },
			onSelectedOn =
			{
                { key = 'Button', color = Gui.AMBER, },
			},
			onSelectedOff =
			{
                { key = 'Button', color = Gui.RED, },
			},
			onDisabledOn =
			{
				{ key = 'Button', color = Gui.AMBER_OPAQUE, },
			},
			onDisabledOff =
			{
				{ key = 'Button', color = Gui.RED, },
			},
        },
    },
}
