local Gui = require('UI.Gui')

local nButtonWidth, nButtonHeight  = 418, 98
local nStatLabelMargin, nStatTextMargin  = 35, 210
local nStatsStartY = 0
local nLineSize = 40
local nInspectorWidth = 418

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
		nLineSize = nLineSize,
    },
    tElements =
    {
		-- flavor text, eg manual excerpts, customer reviews, etc
        {
            key = 'FlavorText',
            type = 'textBox',
            pos = { 8, nStatsStartY - 2 },
			linecode = 'OBFLAV007TEXT',
            style = 'dosissemibold20',
            rect = { 0, 800, 400, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
    },
}
