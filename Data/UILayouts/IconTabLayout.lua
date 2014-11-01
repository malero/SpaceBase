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
                { key = 'TabActive', color = Gui.AMBER, hidden = false, },
                { key = 'Tab', hidden = true, },
                { key = 'Icon', color = Gui.BLACK, },
            },
            onDeselected =
            {
                { key = 'TabActive', hidden = true, },
                { key = 'Tab', hidden = false, },
                { key = 'Icon', color = Gui.AMBER, },
            },
        },
    },
    tElements =
    {
        {
            key = 'TabBackground',
            type = 'uiTexture',
			textureName = 'ui_inspector_folderTop_5wide',
            sSpritesheetPath = 'UI/Inspector',
            pos = { 0, 8 },
            scale = { 1, 1 },
            color = Gui.AMBER_OPAQUE,
        },
        {
            key = 'TabActive',
            type = 'uiTexture',
            textureName = 'ui_inspector_folderActive_5wide',
            sSpritesheetPath = 'UI/Inspector',
            pos = { 0, 0 },
            scale = { 1, 1 },
            hidden = true,
            color = Gui.AMBER,
        },
        {
            key = 'Tab',
            type = 'uiTexture',
            textureName = 'ui_inspector_folderInactive_5wide',
            sSpritesheetPath = 'UI/Inspector',
            pos = { 0, 0 },
            scale = { 1, 1 },
            color = Gui.AMBER,
        },
        {
            key = 'TabButton',
            type = 'onePixel',
            pos = { 12, 0 },
            scale = { 83, 42 },
            color = Gui.RED,
            hidden = true,
            onHoverOn =
            {
                { key = 'TabActive', color = Gui.GREY, hidden = false, },
                { key = 'Tab', hidden = true, },
                { key = 'Icon', color = Gui.BLACK, },
                { playSfx = 'hilight', },
            },
            onHoverOff =
            {
                { key = 'TabActive', hidden = true, },
                { key = 'Tab', hidden = false, },
                { key = 'Icon', color = Gui.AMBER, },
            },
        },
        -- Icon
        {
            key = 'Icon',
            type = 'uiTexture',
            color = Gui.AMBER,
            textureName = 'ui_iconIso_confirm',
            sSpritesheetPath = 'UI/Inspector',
            pos = { 26, -8 },
        },
    },
}

