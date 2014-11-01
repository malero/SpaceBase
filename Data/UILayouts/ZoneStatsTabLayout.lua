local Gui = require('UI.Gui')

local nInspectorWidth = 418

local nStatLabelMargin = 35

local nStatsStartY = 0
local nLineSize = 40

return 
{
    posInfo =
        {
        alignX = 'left',
        alignY = 'top',
        offsetX = 0,
        offsetY = -6,
    },
    tExtraInfo =
    {
        tCallbacks =
        {
            onSelected =
            {
				{ key = 'SurfaceAreaIcon', hidden = false, },
				{ key = 'SurfaceAreaLabel', hidden = false, },
				{ key = 'SurfaceAreaText', hidden = false, },
				{ key = 'OxygenIcon', hidden = false, },
				{ key = 'OxygenLabel', hidden = false, },
				{ key = 'OxygenText', hidden = false, },
				{ key = 'OccupantsIcon', hidden = false, },
				{ key = 'OccupantsLabel', hidden = false, },
				{ key = 'OccupantsText', hidden = false, },
				{ key = 'RoomContentsIcon', hidden = false, },
				{ key = 'RoomContentsLabel', hidden = false, },
				{ key = 'RoomContentsText', hidden = false, },
				{ key = 'PowerDrawIcon', hidden = false, },
				{ key = 'PowerDrawLabel', hidden = false, },
				{ key = 'PowerDrawText', hidden = false, },
            },
            onDeselected =
            {
				{ key = 'SurfaceAreaIcon', hidden = true, },
				{ key = 'SurfaceAreaLabel', hidden = true, },
				{ key = 'SurfaceAreaText', hidden = true, },
				{ key = 'OxygenIcon', hidden = true, },
				{ key = 'OxygenLabel', hidden = true, },
				{ key = 'OxygenText', hidden = true, },
				{ key = 'OccupantsIcon', hidden = true, },
				{ key = 'OccupantsLabel', hidden = true, },
				{ key = 'OccupantsText', hidden = true, },
				{ key = 'RoomContentsIcon', hidden = true, },
				{ key = 'RoomContentsLabel', hidden = true, },
				{ key = 'RoomContentsText', hidden = true, },
				{ key = 'PowerDrawIcon', hidden = true, },
				{ key = 'PowerDrawLabel', hidden = true, },
				{ key = 'PowerDrawText', hidden = true, },
            },
        },
    },
    tElements =
    {
		-- alternating tinted backgrounds for every other item
        {
            key = 'OxygenBG',
            type = 'onePixel',
            pos = { 0, nStatsStartY - nLineSize },
            scale = { nInspectorWidth, nLineSize },
            color = Gui.AMBER_OPAQUE_DIM,
        },
        {
            key = 'RoomContentsBG',
            type = 'onePixel',
            pos = { 0, nStatsStartY - nLineSize * 3 },
            scale = { nInspectorWidth, nLineSize },
            color = Gui.AMBER_OPAQUE_DIM,
        },
        -- surface area
        {
            key = 'SurfaceAreaIcon',
            type = 'uiTexture',
            textureName = 'ui_icon_bulletpoint',
            sSpritesheetPath = 'UI/Inspector',
            pos = { nStatLabelMargin - 30, nStatsStartY - 5 },
            color = Gui.AMBER,
        },
        {
            key = 'SurfaceAreaLabel',
            type = 'textBox',
            pos = { nStatLabelMargin, nStatsStartY },
            linecode = "INSPEC055TEXT",
            style = 'dosissemibold26',
            rect = { 0, 300, 500, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'SurfaceAreaText',
            type = 'textBox',
            pos = { nStatLabelMargin + 150, nStatsStartY - 2 },
            text = "1",
            style = 'dosissemibold24',
            rect = { 0, 300, 500, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
		-- oxygen
        {
            key = 'OxygenIcon',
            type = 'uiTexture',
            textureName = 'ui_icon_bulletpoint',
            sSpritesheetPath = 'UI/Inspector',
            pos = { nStatLabelMargin - 30, nStatsStartY - nLineSize - 5 },
            color = Gui.AMBER,
        },
		{
            key = 'OxygenLabel',
            type = 'textBox',
            pos = { nStatLabelMargin, nStatsStartY - nLineSize },
            linecode = "INSPEC062TEXT",
            style = 'dosissemibold26',
            rect = { 0, 300, 500, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'OxygenText',
            type = 'textBox',
            pos = { nStatLabelMargin + 150, nStatsStartY - nLineSize - 2 },
            text = "1",
            style = 'dosissemibold24',
            rect = { 0, 300, 500, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        -- power draw
        {
            key = 'PowerDrawIcon',
            type = 'uiTexture',
            textureName = 'ui_icon_bulletpoint',
            sSpritesheetPath = 'UI/Inspector',
            pos = { nStatLabelMargin - 30, (nStatsStartY - nLineSize * 2) - 5 },
            color = Gui.AMBER,
        },
        {
            key = 'PowerDrawLabel',
            type = 'textBox',
            pos = { nStatLabelMargin, nStatsStartY - nLineSize * 2 },
            linecode = "INSPEC163TEXT",
            style = 'dosissemibold26',
            rect = { 0, 300, 500, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'PowerDrawText',
            type = 'textBox',
            pos = { nStatLabelMargin + 215, (nStatsStartY - nLineSize * 2) - 2 },
            text = "0",
            style = 'dosissemibold24',
            rect = { 0, 800, 500, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
		-- occupants
        {
            key = 'OccupantsIcon',
            type = 'uiTexture',
            textureName = 'ui_icon_bulletpoint',
            sSpritesheetPath = 'UI/Inspector',
            pos = { nStatLabelMargin - 30, (nStatsStartY - nLineSize * 3) - 5 },
            color = Gui.AMBER,
        },
		{
            key = 'OccupantsLabel',
            type = 'textBox',
            pos = { nStatLabelMargin, nStatsStartY - nLineSize * 3 },
            linecode = "INSPEC060TEXT",
            style = 'dosissemibold26',
            rect = { 0, 300, 500, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'OccupantsText',
            type = 'textBox',
            pos = { nStatLabelMargin + 210, (nStatsStartY - nLineSize * 3) - 2 },
            text = "1",
            style = 'dosissemibold24',
            rect = { 0, 300, 500, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        -- room contents
        {
            key = 'RoomContentsIcon',
            type = 'uiTexture',
            textureName = 'ui_icon_bulletpoint',
            sSpritesheetPath = 'UI/Inspector',
            pos = { nStatLabelMargin - 30, (nStatsStartY - nLineSize * 4) - 5 },
            color = Gui.AMBER,
        },
        {
            key = 'RoomContentsLabel',
            type = 'textBox',
            pos = { nStatLabelMargin, nStatsStartY - nLineSize * 4 },
            linecode = "INSPEC056TEXT",
            style = 'dosissemibold26',
            rect = { 0, 300, 500, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'RoomContentsText',
            type = 'textBox',
            pos = { nStatLabelMargin + 30, nStatsStartY - nLineSize * 5 - 2 },
            text = "1",
            style = 'dosissemibold24',
            rect = { 0, 800, 500, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
    },
}
