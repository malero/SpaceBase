local Gui = require('UI.Gui')

local AMBER = { Gui.AMBER[1], Gui.AMBER[2], Gui.AMBER[3], 0.95 }
local BRIGHT_AMBER = { Gui.AMBER[1], Gui.AMBER[2], Gui.AMBER[3], 1 }
local SELECTION_AMBER = { Gui.AMBER[1], Gui.AMBER[2], Gui.AMBER[3], 0.01 }

local nButtonWidth, nButtonHeight  = 418, 90
local nTabWidth, nTabHeight = 83, 47
local nTabLineHeight = 3

local nLabelX, nTextStartY = 40, -276
local nLineHeight = 36

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
		nTabWidth = nTabWidth,
		nTabHeight = nTabHeight,
		nTabLineHeight = nTabLineHeight,
        tHostileMode =
        {
            {
                key = 'StatsBG',
                --scale = { nButtonWidth, 212 },
            },
            {
                key = 'FolderTop',
                pos = { 0, -420 },
            },
            {
                key = 'NameEditTexture',
                hidden = true,
            },
        },
        tCitizenMode =
        {
            {
                key = 'StatsBG',
                --scale = { nButtonWidth, 152 },
            },
            {
                key = 'FolderTop',
                pos = { 0, -420 },
            },
            {
                key = 'NameEditTexture',
                hidden = false,
            },
        },
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
            key = 'PictureBGImage',
            type = 'uiTexture',
            textureName = 'Background_01',
            sSpritesheetPath = 'UI/Portraits',
            pos = { 33, -145 },
            scale = { 0.84, 0.84 },
        },
        {
            key = 'Picture',
            type = 'uiTexture',
            textureName = 'portrait_generic',
            sSpritesheetPath = 'UI/Portraits',
            pos = { 33, -145 },
            scale = { 0.84, 0.84 },
        },
        {
            key = 'PictureFacialHair',
            type = 'uiTexture',
            textureName = 'NoHair',
            sSpritesheetPath = 'UI/Portraits',
            pos = { 33, -145 },
            scale = { 0.84, 0.84 },
        },
        {
            key = 'PictureHair',
            type = 'uiTexture',
            textureName = 'NoHair',
            sSpritesheetPath = 'UI/Portraits',
            pos = { 33, -145 },
            scale = { 0.84, 0.84 },
        },
        {
            key = 'CamCenterButton',
            type = 'onePixelButton',
            pos = { 30, -144 },
            scale = { 110, 124 },
            color = { 1, 0, 0 },
            hidden = true,
            clickWhileHidden = true,
        },
        -- Name
        {
            key = 'NameLabel',
            type = 'textBox',
            pos = { 150, -174 },
            text = "Joan Q. Citizen",
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
        -- Job Title
        {
            key = 'TitleLabel',
            type = 'textBox',
            pos = { 150, -216 },
            text = "Expert Technician",
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
        -- clickable buttons shortcut to tabs/room
        {
            key = 'HealthStatButton',
            type = 'onePixelButton',
            pos = { 0, nTextStartY },
            scale = { nButtonWidth, nLineHeight },
            color = Gui.AMBER_OPAQUE,
            onHoverOn =
            {
                { key = 'HealthStatButton', color = Gui.AMBER_DIM }
            },
            onHoverOff =
            {
                { key = 'HealthStatButton', color = Gui.AMBER_OPAQUE }
            },
        },
        {
            key = 'MoraleButton',
            type = 'onePixelButton',
            pos = { 0, nTextStartY - nLineHeight },
            scale = { nButtonWidth, nLineHeight },
            color = Gui.AMBER_OPAQUE,
            onHoverOn =
            {
                { key = 'MoraleButton', color = Gui.AMBER_DIM }
            },
            onHoverOff =
            {
                { key = 'MoraleButton', color = Gui.AMBER_OPAQUE }
            },
        },
        {
            key = 'RoomButton',
            type = 'onePixelButton',
            pos = { 0, nTextStartY - nLineHeight*2 },
            scale = { nButtonWidth, nLineHeight },
            color = Gui.AMBER_OPAQUE,
            onHoverOn =
            {
                { key = 'RoomButton', color = Gui.AMBER_DIM }
            },
            onHoverOff =
            {
                { key = 'RoomButton', color = Gui.AMBER_OPAQUE }
            },
        },
        {
            key = 'ActivityButton',
            type = 'onePixelButton',
            pos = { 0, nTextStartY - nLineHeight*3 },
            scale = { nButtonWidth, nLineHeight },
            color = Gui.AMBER_OPAQUE,
            onHoverOn =
            {
                { key = 'ActivityButton', color = Gui.AMBER_DIM }
            },
            onHoverOff =
            {
                { key = 'ActivityButton', color = Gui.AMBER_OPAQUE }
            },
        },
        -- health stat
        {
            key = 'HealthIcon',
            type = 'uiTexture',
            textureName = 'ui_icon_health',
            sSpritesheetPath = 'UI/Inspector',
            pos = { nLabelX - 30, nTextStartY - 4 },
            color = Gui.AMBER,
        },
        {
            key = 'HealthLabel',
            type = 'textBox',
            pos = { nLabelX, nTextStartY },
            linecode = "INSPEC011TEXT",
            style = 'dosisregular26',
            rect = { 0, 300, 500, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = { 0, 0, 0 },
            color = Gui.AMBER,
        },
        {
            key = 'HealthText',
            type = 'textBox',
            pos = { 140, nTextStartY },
            text = "Healthy",
            style = 'dosissemibold26',
            rect = { 0, 300, 500, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        -- morale stat
        {
            key = 'MoraleIcon',
            type = 'uiTexture',
            textureName = 'ui_icon_morale',
            sSpritesheetPath = 'UI/Inspector',
            pos = { nLabelX - 30, nTextStartY - nLineHeight - 4 },
            color = Gui.AMBER,
        },
        {
            key = 'MoraleLabel',
            type = 'textBox',
            pos = { nLabelX, nTextStartY - nLineHeight },
            linecode = "INSPEC012TEXT",
            style = 'dosisregular26',
            rect = { 0, 300, 500, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = { 0, 0, 0 },
            color = Gui.AMBER,
        },
        {
            key = 'MoraleText',
            type = 'textBox',
            pos = { 114, nTextStartY - nLineHeight },
            text = "Happy",
            style = 'dosissemibold26',
            rect = { 0, 300, 500, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        -- cause of death
        {
            key = 'DeathIcon',
            type = 'uiTexture',
            textureName = 'ui_icon_enemy',
            sSpritesheetPath = 'UI/Inspector',
            pos = { nLabelX - 30, nTextStartY - nLineHeight - 4 },
            color = Gui.RED,
        },
        {
            key = 'DeathLabel',
            type = 'textBox',
            pos = { nLabelX, nTextStartY - nLineHeight },
            linecode = "INSPEC106TEXT",
            style = 'dosisregular26',
            rect = { 0, 300, 500, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = { 0, 0, 0 },
            color = Gui.AMBER,
        },
        {
            key = 'DeathText',
            type = 'textBox',
            pos = { 200, nTextStartY - nLineHeight },
            text = "UNKNOWN",
            style = 'dosissemibold26',
            rect = { 0, 300, 500, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        -- location stat
        {
            key = 'LocationIcon',
            type = 'uiTexture',
            textureName = 'ui_icon_location',
            sSpritesheetPath = 'UI/Inspector',
            pos = { nLabelX - 30, nTextStartY - (nLineHeight*2) - 4 },
            color = Gui.AMBER,
        },
        {
            key = 'LocationLabel',
            type = 'textBox',
            pos = { nLabelX, nTextStartY - (nLineHeight*2) },
            linecode = "INSPEC013TEXT",
            style = 'dosisregular26',
            rect = { 0, 300, 500, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = { 0, 0, 0 },
            color = Gui.AMBER,
        },
        {
            key = 'LocationText',
            type = 'textBox',
            pos = { 132, nTextStartY - (nLineHeight*2) },
            text = "Sector C Test Labs",
            style = 'dosissemibold26',
            rect = { 0, 300, 500, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        -- activity stat
        {
            key = 'ActivityIcon',
            type = 'uiTexture',
            textureName = 'ui_icon_bulletpoint',
            sSpritesheetPath = 'UI/Inspector',
            pos = { nLabelX - 30, nTextStartY - (nLineHeight*3) - 4 },
            color = Gui.AMBER,
        },
        {
            key = 'ActivityLabel',
            type = 'textBox',
            pos = { nLabelX, nTextStartY - (nLineHeight*3) },
            linecode = "INSPEC014TEXT",
            style = 'dosisregular26',
            rect = { 0, 300, 500, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = { 0, 0, 0 },
            color = Gui.AMBER,
        },
        {
            key = 'ActivityText',
            type = 'textBox',
            pos = { 120, nTextStartY - (nLineHeight*3) },
            text = "Eating lunch",
            style = 'dosissemibold26',
            rect = { 0, 300, 500, 0 },
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