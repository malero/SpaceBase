local Gui = require('UI.Gui')

local nLabelX, nLabelY = 16, -170

return
{
    posInfo =
    {
        alignX = 'left',
        alignY = 'top',
        offsetX = 0,
        offsetY = 20,
    },
    tExtraInfo =
    {
    },
    tElements =
    {
		{
            key = 'CustomControlsLabel',
            type = 'textBox',
            pos = { nLabelX, nLabelY },
			linecode = 'PROPSX089TEXT',
            style = 'dosissemibold26',
            rect = { 0, 100, 400, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.CENTER_JUSTIFY,
            color = Gui.AMBER,
        },
    },
}
