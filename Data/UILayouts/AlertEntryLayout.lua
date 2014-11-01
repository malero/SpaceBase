local Gui = require('UI.Gui')

local tLayout =
{
    posInfo =
        {
--        alignX = 'right',
        alignY = 'top',
        offsetX = 0,
        offsetY = 0,
        scale = { 1, 1 },
    },
    tElements =
    {
    --[[
        {
            key = 'ButtonBG',
            type = 'onePixel',
            pos = { 0, 0 },
            scale = { 40, 100 },
            color = Gui.ALERTLOG_BG,
        },
        ]]--
        {
            key = 'Button',
            type = 'onePixelButton',
            pos = { 0, 0 },
            scale = { 440, 100 },
            color = Gui.ALERTLOG_BG,
            onHoverOn =
            {
                {
                    key = 'Button',
                    color = Gui.AMBER,
                },
            --[[
                {
                    key = 'ButtonBG',
                    color = Gui.AMBER,
                },
                ]]--
            },
            onHoverOff =
            {
                {
                    key = 'Button',
                    color = Gui.ALERTLOG_BG,
                },
                --[[
                {
                    key = 'ButtonBG',
                    color = Gui.ALERTLOG_BG,
                },
                ]]--
            },
        },
        {
            key = 'AlertText',
            type = 'textBox',
            pos = { 10, -10 },
            text = "Log goes here.  Let's make sure the length is correct.",
            style = 'dosissemibold22',
            rect = { 0, 300, 430, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.BLACK,
        },   
        {
            key = 'TimeText',
            type = 'textBox',
            pos = { 10, -50 },
            text = "0 minutes ago",
            style = 'dosissemibold20',
            rect = { 0, 300, 450, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.BLACK,
        },       
    },
}

return tLayout