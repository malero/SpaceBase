local Gui = require('UI.Gui')

return 
{
    posInfo =
    {
        alignX = 'right',
        alignY = 'top',
        offsetX = -480,
        offsetY = 0,
    },
    tExtraInfo =
    {
        minimizedOverride =
        {
            {
                key = 'Button',
                pos = { 400, 0 },
            },
            {
                key = 'ButtonLabel',
                pos = { 415, 0 },
            },
        },
        maximizedOverride =
        {
            {
                key = 'Button',
                pos = { -50, 0 },
            },
            {
                key = 'ButtonLabel',
                pos = { -30, 0 },
            },
        },
    },    
    tElements =
    {   
        {
            key = 'Button',
            type = 'onePixelButton',
            pos = { -50, 0 },
            scale = { 50, 50 },
            color = Gui.AMBER,
        },    
        {
            key = 'ButtonLabel',
            type = 'textBox',
            pos = { -30, 0 },
            text = "!",
            style = 'dosissemibold38',
            rect = { 0, 300, 450, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = { 0, 0, 0 },
        },   
   },
}