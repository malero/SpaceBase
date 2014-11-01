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
            pos = { 20, 0 },
            scale = { 250, 60 },
            color = { 1, 0, 0 },
            hidden = true,
            clickWhileHidden = true,
            onHoverOn =
            {
                {
                    key = 'SelectedTexture',
                    hidden = false,
                },
                {
                    key = 'DeselectedTexture',
                    hidden = true,
                },
                {
                    key = 'ButtonLabel',
                    color = { 0, 0, 0 },
                },          
                {
                    key = 'ButtonDescription',
                    color = { 0, 0, 0 },                    
                },
                
                {
                    playSfx = 'hilight',
                },
            },
            onHoverOff =
            {
                {
                    key = 'SelectedTexture',
                    hidden = true,
                },
                {
                    key = 'DeselectedTexture',
                    hidden = false,
                },
                {
                    key = 'ButtonLabel',
                    color = Gui.AMBER,
                },          
                {
                    key = 'ButtonDescription',
                    color = Gui.AMBER,
                },
            },
        },
        {
            key = 'SelectedTexture',
            type = 'uiTexture',
            textureName = 'ui_inspector_rezoneActive',
            sSpritesheetPath = 'UI/Inspector',
            pos = { 20, 0 },
            scale = { 1, 1 },
            color = Gui.AMBER,
            hidden = true,
            layerOverride = 'UIScrollLayerLeft',
        },
        {
            key = 'DeselectedTexture',
            type = 'uiTexture',
            textureName = 'ui_inspector_rezoneInactive',
            sSpritesheetPath = 'UI/Inspector',
            pos = { 20, 0 },
            scale = { 1, 1 },
            color = Gui.AMBER,
            layerOverride = 'UIScrollLayerLeft',
        },
        {
            key = 'ButtonLabel',
            type = 'textBox',
            pos = { -100, 0 },
            text = "Airlock",
            style = 'dosissemibold32',
            rect = { 0, 100, 300, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
            layerOverride = 'UIScrollLayerLeft',
        },
        {
            key = 'ButtonDescription',
            type = 'textBox',
            pos = { -200, -34 },
            text = "Exit the base.",
            style = 'dosissemibold16',
            rect = { 0, 300, 400, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.GREY,
            layerOverride = 'UIScrollLayerLeft',
        },
        -- num rooms
        {
            key = 'NumText',
            type = 'textBox',
            pos = { -14, 0 },
            text = "1",
            style = 'dosissemibold38',
            rect = { 0, 300, 500, 0 },
            hAlign = MOAITextBox.CENTER_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = { 0, 0, 0 },
            layerOverride = 'UIScrollLayerLeft',
        },        
        -- prop labels
        {
            key = 'PropDescription',
            type = 'textBox',
            pos = { 274, -12 },
            text = "",
            style = 'dosissemibold24',
            rect = { 0, 300, 400, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
            layerOverride = 'UIScrollLayerLeft',
        },
    },
}