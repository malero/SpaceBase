local Gui = require('UI.Gui')
local LOG_DATE_COLOR = { 0/255, 0/255, 0/255, 0.5 }
local LOG_TEXT_COLOR = { 0/255, 0/255, 0/255, 1 }

local nButtonWidth, nButtonHeight  = 381, 98

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
        oddIndex =
        {
            {
                key = 'BGButton',
                color = Gui.SPACEFACE_BG,
            },
        },
        evenIndex =
        {
            {
                key = 'BGButton',
                color = Gui.SPACEFACE_FG,
            },
        },
    },
    tElements =
    { 
        {
            key = 'BGButton',
            type = 'onePixelButton',
            pos = { 0, 0 },
            scale = { nButtonWidth, 100 },
            color = Gui.SPACEFACE_FG,
--			color = {0.15, 0.15, 0.15, 0.05},
--            color = Gui.BLACK_NO_ALPHA,
            layerOverride = 'UIScrollLayerLeft',
        },
        {
            key = 'Date',
            type = 'textBox',
            pos = { 10, -6 },
            text = "94109.07",
            style = 'dosissemibold20',
            rect = { 0, 300, 500, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = LOG_DATE_COLOR,
            layerOverride = 'UIScrollLayerLeft',
        },
        {
            key = 'LogText',
            type = 'textBox',
            pos = { 100, -6 },
            text = "Log goes here.  Let's make sure the length is correct.",
            style = 'dosissemibold22',
            rect = { 0, 300, 280, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = LOG_TEXT_COLOR,
            layerOverride = 'UIScrollLayerLeft',
        },
    },
}
