local Gui = require('UI.Gui')

local nButtonWidth, nButtonHeight  = 418, 98
local nTabWidth, nTabHeight = 83, 47
local nTabLineHeight = 3

local nControlButtonX, nControlButtonY = 32, -370
local nControlButtonSpacing = 36
local nControlButtonWidth, nControlButtonHeight = 160, 37
local labelX, labelY = -20, nControlButtonY - 5

return
{
    posInfo =
        {
        alignX = 'left',
        alignY = 'top',
        offsetX = 0,
        offsetY = 0,
    },
    tExtraInfo =
    {
		nTabWidth = nTabWidth,
		nTabHeight = nTabHeight,
		nTabLineHeight = nTabLineHeight,
    },
    tElements =
    {
        {
            key = 'PictureLargeBG',
            type = 'onePixel',
            pos = { 0, -163 },
            scale = { nButtonWidth, 106 },
            color = Gui.AMBER,
        },
		-- "editing name" BG
        {
            key = 'NameEditBG',
            type = 'onePixelButton',
            pos = { 0, -176 },
            scale = { nButtonWidth, 35 },
            color = Gui.AMBER,
        },
        -- Portrait
        {
            key = 'PictureBG',
            type = 'onePixel',
            pos = { 30, -144 },
            scale = { 110, 20 },
            color = Gui.AMBER,
        },
        {
            key = 'Picture',
            type = 'uiTexture',
            textureName = 'portrait_generic',
            sSpritesheetPath = 'UI/Portraits',
            pos = { 33, -145 },
            scale = { 0.84, 0.84 },
            color = Gui.AMBER,
        },
        -- Name
        {
            key = 'NameLabel',
            type = 'textBox',
            pos = { 150, -174 },
            text = "Reactor Zone Tao",
            style = 'dosissemibold26',
            rect = { 0, 300, 500, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = { 0, 0, 0 },
        },
        -- Name Edit Button
        {
            key = 'NameEditButton',
            type = 'onePixelButton',
            pos = { 0, -176 },
            scale = { nButtonWidth, 35 },
            color = { 1, 0, 0 },
            hidden = true,
			clickWhileHidden = true,
            onHoverOn =
            {
                { key = 'NameLabel', color = Gui.AMBER, },
                { key = 'NameEditBG', color = Gui.AMBER_OPAQUE, },
				{ key = 'NameEditTexture', hidden = false, },
            },
            onHoverOff =
            {
                { key = 'NameLabel', color = Gui.BLACK, },
                { key = 'NameEditBG', color = Gui.AMBER },
				{ key = 'NameEditTexture', hidden = true, },
            },
            onSelectedOn =
            {
                { key = 'NameLabel', color = Gui.AMBER, },
                { key = 'NameEditBG', color = Gui.BLACK, },
				{ key = 'NameEditTexture', hidden = true, },
            },
            onSelectedOff =
            {
                { key = 'NameLabel', color = Gui.BLACK, },
                { key = 'NameEditBG', color = Gui.AMBER },
				{ key = 'NameEditTexture', hidden = true, },
            },
        },
        {
            key = 'NameEditTexture',
            type = 'uiTexture',
            textureName = 'ui_inspector_buttonEdit',
            sSpritesheetPath = 'UI/Inspector',
            pos = { 380, -176 },
            color = Gui.AMBER,
			hidden = true,
        },
        -- Alert
        {
            key = 'AlertLabel',
            type = 'textBox',
            pos = { 150, -216 },
            text = "",
            style = 'dosisregular26',
            rect = { 0, 300, 500, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = { 0, 0, 0 },
        },
        -- stats
        {
            key = 'StatsBG',
            type = 'onePixel',
            pos = { 0, -268 },
            scale = { nButtonWidth, 152 },
            color = Gui.AMBER_OPAQUE,
        },
        -- description
        {
            key = 'DescriptionText',
            type = 'textBox',
            pos = { 20, -280 },
            text = "",
            style = 'dosissemibold26',
            rect = { 0, 300, 400, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        -- "behind tab" box
        {
            key = 'TabBGSpacer',
            type = 'onePixel',
            pos = { nTabWidth * 3, -420 },
            scale = { nTabWidth*2 + 3, nTabHeight },
            color = Gui.AMBER_OPAQUE,
        },
		-- line that completes the tab row
        {
            key = 'TabLineSpacer',
            type = 'onePixel',
            pos = { nTabWidth * 3, -420-nTabHeight },
            scale = { nTabWidth*2 + 3, nTabLineHeight },
            color = Gui.AMBER,
        },
        -- Tabbed Pane
        {
            key = 'TabbedPane',
            type = 'tabbedPane',
            pos = { 0, -428 },
            rect = { 0, 0, nButtonWidth-20, 655 }, 
        },
    },
}
