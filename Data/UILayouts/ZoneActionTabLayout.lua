local Gui = require('UI.Gui')

local nButtonWidth, nButtonHeight  = 418, 90
local buttonX = 200

local nLabelX = 8
local nCustomControlLabelY = -120

local nScrollAreaTopMargin = 210

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
            pos = { nLabelX, nCustomControlLabelY },
			linecode = 'PROPSX098TEXT',
            style = 'dosissemibold26',
            rect = { 0, 100, 500, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.CENTER_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'AssignmentButtonScrollPane',
            type = 'scrollPane',
            pos = { 60, -nScrollAreaTopMargin },
            rect = { 0, 0, 330, '(g_GuiManager.getUIViewportSizeY()- 720)' },
            scissorLayerName='UIScrollLayerLeft',
        },
    },
}
