local Gui = require('UI.Gui')

local nWidth, nHeight = 200, 120
local nBorderThickness = 4
local nTextMargin = 18
local nTextWithTextureMargin = 42
local nTextStartY = -10
local nTextHeight = 30
local nTextureMargin = 16
local nTextureStartY = -16
local nTextureHeight = 30

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
    tExtraInfo =
    {
        texture1ShowOverride =
        {
            {
                key = 'TipText1',
                pos = { nTextWithTextureMargin, nTextStartY + 3 },
            },
            {
                key = 'TipTexture1',
                hidden = false,
            },
        },
        texture1HideOverride =
        {
            {
                key = 'TipText1',
                pos = { nTextMargin, nTextStartY + 3 },
            },
            {
                key = 'TipTexture1',
                hidden = true,
            },
        },
        texture2ShowOverride =
        {
            {
                key = 'TipText2',
                pos = { nTextWithTextureMargin, nTextStartY - nTextHeight },
            },
            {
                key = 'TipTexture2',
                hidden = false,
            },
        },
        texture2HideOverride =
        {
            {
                key = 'TipText2',
                pos = { nTextMargin, nTextStartY - nTextHeight },
            },
            {
                key = 'TipTexture2',
                hidden = true,
            },
        },
        texture3ShowOverride =
        {
            {
                key = 'TipText3',
                pos = { nTextWithTextureMargin, nTextStartY - (nTextHeight * 2) },
            },
            {
                key = 'TipTexture3',
                hidden = false,
            },
        },
        texture3HideOverride =
        {
            {
                key = 'TipText3',
                pos = { nTextMargin, nTextStartY - (nTextHeight * 2) },
            },
            {
                key = 'TipTexture3',
                hidden = true,
            },
        },
        texture4ShowOverride =
        {
            {
                key = 'TipText4',
                pos = { nTextWithTextureMargin, nTextStartY - (nTextHeight * 3) },
            },
            {
                key = 'TipTexture4',
                hidden = false,
            },
        },
        texture4HideOverride =
        {
            {
                key = 'TipText4',
                pos = { nTextMargin, nTextStartY - (nTextHeight * 3) },
            },
            {
                key = 'TipTexture4',
                hidden = true,
            },
        },
        texture5ShowOverride =
        {
            {
                key = 'TipText5',
                pos = { nTextWithTextureMargin, nTextStartY - (nTextHeight * 4) },
            },
            {
                key = 'TipTexture5',
                hidden = false,
            },
        },
        texture5HideOverride =
        {
            {
                key = 'TipText5',
                pos = { nTextMargin, nTextStartY - (nTextHeight * 4) },
            },
            {
                key = 'TipTexture5',
                hidden = true,
            },
        },
    },
    tElements =
    {
        -- BG
        {
            key = 'Background',
            type = 'onePixel',
            pos = { 0, 0 },
            scale = { nWidth, nHeight },
            color = { 0, 0, 0 },
        },
        {
            key = 'TopBorder',
            type = 'onePixel',
            pos = { 0, 0 },
            scale = { nWidth, nBorderThickness },
            color = Gui.AMBER,
        },
        {
            key = 'BottomBorder',
            type = 'onePixel',
            pos = { 0, -(nHeight - nBorderThickness) },
            scale = { nWidth, nBorderThickness },
            color = Gui.AMBER,
        },
        {
            key = 'LeftBorder',
            type = 'onePixel',
            pos = { 0, 0 },
            scale = { nBorderThickness, nHeight },
            color = Gui.AMBER,
        },
        {
            key = 'RightBorder',
            type = 'onePixel',
            pos = { nWidth, 0 },
            scale = { nBorderThickness, nHeight },
            color = Gui.AMBER,
        },
        -- text boxes
        {
            key = 'TipText1',
            type = 'textBox',
            pos = { nTextMargin, -15 },
            text = '',
            style = 'dosissemibold30',
            rect = { 0, 100, 1000, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'TipTexture1',
            type = 'uiTexture',
            textureName = 'ui_icon_health',
            sSpritesheetPath = 'UI/Inspector',
            color = Gui.AMBER,
            hidden = true,
            pos = { nTextureMargin - 7, nTextureStartY + 4 },
        },
        {
            key = 'TipText2',
            type = 'textBox',
            pos = { nTextMargin, nTextStartY - nTextHeight },
            text = '',
            style = 'dosissemibold26',
            rect = { 0, 100, 1000, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'TipTexture2',
            type = 'uiTexture',
            textureName = 'ui_icon_health',
            sSpritesheetPath = 'UI/Inspector',
            color = Gui.AMBER,
            hidden = true,
            pos = { nTextureMargin, nTextureStartY - nTextureHeight },
        },
        {
            key = 'TipText3',
            type = 'textBox',
            pos = { nTextMargin, nTextStartY - (nTextHeight * 2) },
            text = '',
            style = 'dosissemibold26',
            rect = { 0, 100, 1000, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'TipTexture3',
            type = 'uiTexture',
            textureName = 'ui_icon_health',
            sSpritesheetPath = 'UI/Inspector',
            color = Gui.AMBER,
            hidden = true,
            pos = { nTextureMargin, nTextureStartY - (nTextureHeight * 2) },
        },
        {
            key = 'TipText4',
            type = 'textBox',
            pos = { nTextMargin, nTextStartY - (nTextHeight * 3) },
            text = '',
            style = 'dosissemibold26',
            rect = { 0, 100, 1000, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'TipTexture4',
            type = 'uiTexture',
            textureName = 'ui_icon_health',
            sSpritesheetPath = 'UI/Inspector',
            color = Gui.AMBER,
            hidden = true,
            pos = { nTextureMargin, nTextureStartY - (nTextureHeight * 3) },
        },
        {
            key = 'TipText5',
            type = 'textBox',
            pos = { nTextMargin, nTextStartY - (nTextHeight * 4) },
            text = '',
            style = 'dosissemibold26',
            rect = { 0, 100, 1000, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'TipTexture5',
            type = 'uiTexture',
            textureName = 'ui_icon_health',
            sSpritesheetPath = 'UI/Inspector',
            color = Gui.AMBER,
            hidden = true,
            pos = { nTextureMargin, nTextureStartY - (nTextureHeight * 4) },
        },
       {
            key = 'TipText6',
            type = 'textBox',
            pos = { nTextMargin, nTextStartY - (nTextHeight * 5) },
            text = '',
            style = 'dosissemibold26',
            rect = { 0, 100, 1000, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'TipTexture6',
            type = 'uiTexture',
            textureName = 'ui_icon_health',
            sSpritesheetPath = 'UI/Inspector',
            color = Gui.AMBER,
            hidden = true,
            pos = { nTextureMargin, nTextureStartY - (nTextureHeight * 5) },
        },
        {
            key = 'TipText7',
            type = 'textBox',
            pos = { nTextMargin, nTextStartY - (nTextHeight * 6) },
            text = '',
            style = 'dosissemibold26',
            rect = { 0, 100, 1000, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'TipTexture7',
            type = 'uiTexture',
            textureName = 'ui_icon_health',
            sSpritesheetPath = 'UI/Inspector',
            color = Gui.AMBER,
            hidden = true,
            pos = { nTextureMargin, nTextureStartY - (nTextureHeight * 6) },
        },
        {
            key = 'TipText8',
            type = 'textBox',
            pos = { nTextMargin, nTextStartY - (nTextHeight * 7) },
            text = '',
            style = 'dosissemibold26',
            rect = { 0, 100, 1000, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'TipTexture8',
            type = 'uiTexture',
            textureName = 'ui_icon_health',
            sSpritesheetPath = 'UI/Inspector',
            color = Gui.AMBER,
            hidden = true,
            pos = { nTextureMargin, nTextureStartY - (nTextureHeight * 7) },
        },
    },
}