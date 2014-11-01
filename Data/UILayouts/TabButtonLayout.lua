local Gui = require('UI.Gui')

local AMBER = { Gui.AMBER[1], Gui.AMBER[2], Gui.AMBER[3], 0.95 }
local BRIGHT_AMBER = { Gui.AMBER[1], Gui.AMBER[2], Gui.AMBER[3], 1 }
local SELECTION_AMBER = { Gui.AMBER[1], Gui.AMBER[2], Gui.AMBER[3], 0.01 }

local nButtonWidth, nButtonHeight  = 418, 98

return 
{
    posInfo =
    {
        alignX = 'left',
        alignY = 'top',
    },
    tExtraInfo =
    {
        tCallbacks =
        {
        },
    },    
    tElements =
    {       
        {
            key = 'ActiveTabTexture',
            type = 'uiTexture',
            textureName = 'ui_tabTopActive',
            sSpritesheetPath = 'UI/Shared',
            --pos = { 1000, -nProjectTabY },
            color = Gui.AMBER,
            onHoverOn =
            {
                {
                    key = 'TabText',
                    color = Gui.BLACK,
                },
                {
                    key = 'ActiveTabTexture',
                    hidden = false,
                }, 
                {
                    key = 'InactiveTabTexture',
                    hidden = true,
                }, 
            },
            onHoverOff =
            {
                {
                    key = 'TabText',
                    color = Gui.AMBER,
                },
                {
                    key = 'ActiveTabTexture',
                    hidden = true,
                }, 
                {
                    key = 'InactiveTabTexture',
                    hidden = false,
                }, 
            },
            onSelectedOn =
            {
                {
                    key = 'TabText',
                    color = Gui.BLACK,
                },
                {
                    key = 'ActiveTabTexture',
                    hidden = false,
                }, 
                {
                    key = 'InactiveTabTexture',
                    hidden = true,
                }, 
            },
            onSelectedOff =
            {
                {
                    key = 'TabText',
                    color = Gui.AMBER,
                },
                {
                    key = 'ActiveTabTexture',
                    hidden = true,
                }, 
                {
                    key = 'InactiveTabTexture',
                    hidden = false,
                }, 
            },
        },
        {
            key = 'InactiveTabTexture',
            type = 'uiTexture',
            textureName = 'ui_tabTopInactive',
            sSpritesheetPath = 'UI/Shared',
            --pos = { 1000, -nProjectTabY },
            color = Gui.AMBER,
        },
        {
            key = 'TabText',
            type = 'textBox',
            pos = {32,-8},
            --pos = { 1000 + 32, -nProjectTabY - 8 },
            linecode = 'RSCHUI005TEXT',
            style = 'dosissemibold30',
            rect = { 0, 300, 200, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.BLACK,
        },
    },
}

