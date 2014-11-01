local Gui = require('UI.Gui')

local AMBER = { Gui.AMBER[1], Gui.AMBER[2], Gui.AMBER[3], 0.95 }
local BRIGHT_AMBER = { Gui.AMBER[1], Gui.AMBER[2], Gui.AMBER[3], 1 }
local SELECTION_AMBER = { Gui.AMBER[1], Gui.AMBER[2], Gui.AMBER[3], 0.01 }

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
        {
            key = 'Button',
            type = 'onePixelButton',
            pos = { 0, 0 },
            scale = { 423, 100 },
            color = Gui.BLACK,
            onHoverOn =
            {
                { key = 'Button', color = Gui.AMBER },
				{ key = 'ButtonLabel', color = Gui.BLACK, },
				{ key = 'ButtonDescription', color = Gui.BLACK, },
				{ key = 'NumText', color = Gui.BLACK, },
            },
            onHoverOff =
            {
                { key = 'Button', color = Gui.BLACK, },
				{ key = 'ButtonLabel', color = Gui.AMBER, },
				{ key = 'ButtonDescription', color = Gui.AMBER, },
				{ key = 'NumText', color = Gui.WHITE, },
            },
			onSelectedOn =
			{
				{ key = 'Button', color = Gui.AMBER, },
				{ key = 'ButtonLabel', color = Gui.BLACK, },
				{ key = 'ButtonDescription', color = Gui.BLACK, },
				{ key = 'NumText', color = Gui.BLACK, },
			},
			onSelectedOff =
			{
				{ key = 'Button', color = Gui.BLACK, },
				{ key = 'ButtonLabel', color = Gui.AMBER, },
				{ key = 'ButtonDescription', color = Gui.AMBER, },
				{ key = 'NumText', color = Gui.WHITE, },
			},
            layerOverride = 'UIScrollLayerLeft',
        },
        {
            key = 'ButtonLabel',
            type = 'textBox',
            pos = { 0, -30 },
            text = "Airlock",
            style = 'dosissemibold26',
            rect = { 0, 0, 400, -140 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.RIGHT_JUSTIFY,
            color = Gui.AMBER,
            layerOverride = 'UIScrollLayerLeft',
        },
        {
            key = 'ButtonDescription',
            type = 'textBox',
            pos = { 20, -74 },
            text = "blah blah blah blah blah blah blah blah blah blah blah blah",
            style = 'dosissemibold18',
            rect = { 0, 0, 380, -70 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.RIGHT_JUSTIFY,
            color = Gui.AMBER,
            layerOverride = 'UIScrollLayerLeft',
        },
        {
            key = 'NumText',
            type = 'textBox',
            pos = { 325, 0 },
            text = "1",
            style = 'dosissemibold20',
            rect = { 0, 0, 100, -70 },
            hAlign = MOAITextBox.CENTER_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.WHITE,
            layerOverride = 'UIScrollLayerLeft',
        },        
        {
            key = 'ProgressBar',
            type = 'progressBar',
            pos = { 20, -92 },
            rect = { 0, 0, 300, 15 },
            layerOverride = 'UIScrollLayerLeft',
        },
    },
}
