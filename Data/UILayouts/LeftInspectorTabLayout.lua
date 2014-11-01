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
            onSelected =
            {
                {
                    key = 'FolderTopActive',
                    color = Gui.AMBER,
                    hidden = false,
                },
                {
                    key = 'FolderTopInactive',
                    hidden = true,
                }, 
                {
                    key = 'ActiveTabBG',
                    color = Gui.AMBER,
                    hidden = false,
                }, 
                {
                    key = 'Label',
                    color = { 0, 0, 0 },
                },         
            },
            onDeselected =
            {
                {
                    key = 'FolderTopActive',
                    hidden = true,
                },
                {
                    key = 'FolderTopInactive',
                    hidden = false,
                },
                {
                    key = 'ActiveTabBG',
                    hidden = true,
                }, 
                {
                    key = 'Label',
                    color = Gui.AMBER,
                },
            },
        },
    },    
    tElements =
    {       
        {
            key = 'FolderTopActive',
            type = 'uiTexture',
            textureName = 'ui_inspector_folderActive',
            sSpritesheetPath = 'UI/Inspector',
            pos = { 0, 0 },
            scale = { 1, 1 },
            color = Gui.AMBER,
        },
        {
            key = 'FolderTopInactive',
            type = 'uiTexture',
            textureName = 'ui_inspector_folderInactive',
            sSpritesheetPath = 'UI/Inspector',
            pos = { 0, 0 },
            scale = { 1, 1 },
            color = Gui.AMBER,
        },
        {
            key = 'TabButton',
            type = 'onePixelButton',
            pos = { 12, 0 },
            scale = { 150, 44 },
            color = { 1, 0, 0 },
            hidden = true,
            onHoverOn =
            {
                {
                    key = 'FolderTopActive',
                    color = Gui.GREY,
                    hidden = false,
                },
                {
                    key = 'FolderTopInactive',
                    hidden = true,
                }, 
                {
                    key = 'ActiveTabBG',
                    color = Gui.GREY,
                    hidden = false,
                }, 
                {
                    key = 'Label',
                    color = { 0, 0, 0 },
                }, 
                
                {
                    playSfx = 'hilight',
                },
            },
            onHoverOff =
            {
                {
                    key = 'FolderTopActive',
                    hidden = true,
                },
                {
                    key = 'FolderTopInactive',
                    hidden = false,
                },
                {
                    key = 'ActiveTabBG',
                    hidden = true,
                }, 
                {
                    key = 'Label',
                    color = Gui.AMBER,
                },
            },
        },
        {
            key = 'ActiveTabBG',
            type = 'onePixel',
            pos = { 0, -40 },
            scale = { nButtonWidth, 20 },
            color = Gui.AMBER,
        },
        -- Label
        {
            key = 'Label',
            type = 'textBox',
            pos = { 24, 2 },
            linecode = "INSPEC030TEXT",
            style = 'dosissemibold32',
            rect = { 0, 300, 500, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        -- hint text
        {
            key = 'HintText',
            type = 'textBox',
            pos = { 166, -12 },
            linecode = "INSPEC031TEXT",
            style = 'dosissemibold20',
            rect = { 0, 300, 600, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = { 0, 0, 0 },
            color = Gui.AMBER,
        },
    },
}

