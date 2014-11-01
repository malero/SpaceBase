local Gui = require('UI.Gui')

return 
{
    posInfo =
    {
        alignX = 'right',
        alignY = 'top',
        offsetX = -480,
        offsetY = -240,
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
                pos = { -35, 0 },
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
            color = Gui.HINTLOG_HIGHLIGHT,
        },    
        {
            key = 'ButtonLabel',
            type = 'textBox',
            pos = { -35, 0 },
            text = "?",
            style = 'dosissemibold38',
            rect = { 0, 300, 450, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = { 0, 0, 0 },
        },
        --[[
        {
            key = 'ScrollPane',
            type = 'scrollPane',
            pos = { 10, 0 },
            scissorLayerName = 'UIScrollLayerRight',
            rect = { 0, 764, 570, 1152 },
        },  
  ]]--      
    },
}