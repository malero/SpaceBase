local Gui = require('UI.Gui')

-- training text + shaded area beneath
local nTutorialX = 0
local nTutorialY = -720
local nTutorialTextXOffset = 480
local nTutorialTextYOffset = 45
local nTutorialHeight = 96
local nTutorialOpacity = 0.65

return 
{
    posInfo =
        {
        alignX = 'left',
        alignY = 'top',
        offsetX = 0,
        offsetY = 0,
        scale = { 1, 1 },
    },
    tElements =
    {
		-- shaded area behind training text
        {
            key = 'TutorialTextBGFadeTop',
            type = 'uiTexture',
            textureName = 'grad64',
            sSpritesheetPath = 'UI/Shared',
            pos = { nTutorialX, nTutorialY },
            scale = { 2568/64, 1 },
            color = {0, 0, 0, nTutorialOpacity},
			--color = Gui.AMBER,
            hidden = true,
        },
        {
            key = 'TutorialTextBG',
            type = 'onePixel',
            pos = { nTutorialX, nTutorialY-64 },
            scale = { 2568, nTutorialHeight },
            color = {0, 0, 0, nTutorialOpacity},
            hidden = true,
        },
        {
            key = 'TutorialTextBGFadeBottom',
            type = 'uiTexture',
            textureName = 'grad64',
            sSpritesheetPath = 'UI/Shared',
            pos = { nTutorialX, nTutorialY-64-nTutorialHeight-64 },
            scale = { 2568/64, -1 },
            color = {0, 0, 0, nTutorialOpacity},
            hidden = true,
        },
		{
            key = 'TutorialText',
            type = 'textBox',
            pos = { nTutorialX+nTutorialTextXOffset, nTutorialY+nTutorialTextYOffset },
            text = 'Hi, this is a training message. Press the BLUH key to frobnabulate the wizard. Use the foot pedal to scroll through Z-levels and the dwarf toe to rectify all breakfast cereals. Sure, another sentence to test text overflow.',
            style = 'dosissemibold42',
            rect = { 0, 300, 1500, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.CENTER_JUSTIFY,
            color = Gui.AMBER,
            hidden = true,
        },
        {
            key = 'TutorialBlip',
            type = 'uiTexture',
            textureName = 'ui_hud_speed0',
            sSpritesheetPath = 'UI/HUD',
            pos = { 1790, -170 },
            scale = {2, 2},
            color = Gui.RED,
			hidden = true,
        },
	},
}
