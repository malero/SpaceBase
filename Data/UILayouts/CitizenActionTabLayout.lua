local Gui = require('UI.Gui')

local AMBER = { Gui.AMBER[1], Gui.AMBER[2], Gui.AMBER[3], 0.95 }
local BRIGHT_AMBER = { Gui.AMBER[1], Gui.AMBER[2], Gui.AMBER[3], 1 }
local SELECTION_AMBER = { Gui.AMBER[1], Gui.AMBER[2], Gui.AMBER[3], 0.01 }

local nButtonWidth, nButtonHeight  = 418, 90
local buttonX = 50

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
            key = 'BedLabel',
            type = 'textBox',
            pos = { 20, -35 },
            linecode = 'INSPEC159TEXT',
            style = 'dosismedium32',
            rect = { 0, 300, 150, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'SecurityArrowL1',
            type = 'uiTexture',
            textureName = 'button_alert_flag',
            sSpritesheetPath = 'UI/Shared',
            pos = { 30, -108 },
            scale = {1, 1},
            color = Gui.AMBER_OPAQUE,
        },
        {
            key = 'SecurityArrowL2',
            type = 'uiTexture',
            textureName = 'button_alert_flag',
            sSpritesheetPath = 'UI/Shared',
            pos = { 50, -108 },
            scale = {1, 1},
            color = Gui.AMBER_OPAQUE,
        },
        {
            key = 'SecurityArrowL3',
            type = 'uiTexture',
            textureName = 'button_alert_flag',
            sSpritesheetPath = 'UI/Shared',
            pos = { 70, -108 },
            scale = {1, 1},
            color = Gui.AMBER_OPAQUE,
        },
        {
            key = 'SecurityArrowR1',
            type = 'uiTexture',
            textureName = 'button_alert_flag',
            sSpritesheetPath = 'UI/Shared',
            pos = { 350, -108 },
            scale = {-1, 1},
            color = Gui.AMBER_OPAQUE,
        },
        {
            key = 'SecurityArrowR2',
            type = 'uiTexture',
            textureName = 'button_alert_flag',
            sSpritesheetPath = 'UI/Shared',
            pos = { 370, -108 },
            scale = {-1, 1},
            color = Gui.AMBER_OPAQUE,
        },
        {
            key = 'SecurityArrowR3',
            type = 'uiTexture',
            textureName = 'button_alert_flag',
            sSpritesheetPath = 'UI/Shared',
            pos = { 390, -108 },
            scale = {-1, 1},
            color = Gui.AMBER_OPAQUE,
        },
        {
            key = 'SecurityLabel',
            type = 'textBox',
            pos = { 0, -100 },
            linecode = 'INSPEC196TEXT',
            style = 'dosismedium32',
            rect = { 0, 300, nButtonWidth, 0 },
            hAlign = MOAITextBox.CENTER_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
			hidden = false,
        },
        {
            key = 'SecurityWarningLabel',
            type = 'textBox',
            pos = { 0, -145 },
            linecode = 'INSPEC197TEXT',
            style = 'dosissemibold20',
            rect = { 0, 300, nButtonWidth, 0 },
            hAlign = MOAITextBox.CENTER_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.RED,
			hidden = false,
        },
        {
            key = 'BrigLabel',
            type = 'textBox',
            pos = { 20, -350 },
            linecode = 'INSPEC188TEXT',
            style = 'dosismedium32',
            rect = { 0, 300, 150, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
    },
}
