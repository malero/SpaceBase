local Gui = require('UI.Gui')

local AMBER = { Gui.AMBER[1], Gui.AMBER[2], Gui.AMBER[3], 0.95 }
local BRIGHT_AMBER = { Gui.AMBER[1], Gui.AMBER[2], Gui.AMBER[3], 1 }
local SELECTION_AMBER = { Gui.AMBER[1], Gui.AMBER[2], Gui.AMBER[3], 0.01 }

local CONSTRUCT_CANCEL = Gui.RED
local CONSTRUCT_CONFIRM = Gui.GREEN

local nButtonWidth, nButtonHeight  = 430, 81
local nTextHeight = nButtonHeight + 20
local nButtonStartY = 278
local nIconX, nIconStartY = 20, -280
local nLabelX, nLabelStartY =  105, -288
local nHotkeyX, nHotkeyStartY = nButtonWidth - 112, -330
local nIconScale = .6
local numButtons = 7
local nCancelIconStartY = -82
local nCancelLabelStartY = -90
local nCancelHotkeyY = -130
local nBGWidth = 160

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
        onShowMatterCost =
        {
            { key = 'CostBackground', hidden = false, },
            { key = 'CostBackgroundEndCap', hidden = false, },
            { key = 'CostVerticalRule', hidden = false, },
            { key = 'CostIconMatter', hidden = false, },
            { key = 'CostText', hidden = false, },
        },
        onHideMatterCost =
        {
            { key = 'CostBackground', hidden = true, },
            { key = 'CostBackgroundEndCap', hidden = true, },
            { key = 'CostVerticalRule', hidden = true, },
            { key = 'CostIconMatter', hidden = true, },
            { key = 'CostText', hidden = true, },
        },
    },
    tElements =
    {
        {
            key = 'LargeBar',
            type = 'onePixel',
            pos = { 0, 0 },
            scale = { nButtonWidth, (nButtonStartY + 3*nButtonHeight) },
            color = Gui.SIDEBAR_BG,
        },
        {
            key = 'BackButton',
            type = 'onePixelButton',
            pos = { 0, 0 },
            scale = { nButtonWidth, nButtonHeight },
            color = AMBER,
            hidden = true,
            onPressed =
            {
                { key = 'BackButton', color = BRIGHT_AMBER, },
            },
            onReleased =
            {
                { key = 'BackButton', color = AMBER, },
            },
            onHoverOn =
            {
                { key = 'BackButton', hidden = false, },
                { key = 'BackLabel', color = Gui.BLACK, },
                { key = 'BackHotkey', color = Gui.BLACK, },
                { playSfx = 'hilight', },
            },
            onHoverOff =
            {
                { key = 'BackButton', hidden = true, },
                { key = 'BackLabel', color = Gui.AMBER, },
                { key = 'BackHotkey', color = Gui.AMBER, },
            },
        },
        {
            key = 'BackLabel',
            type = 'textBox',
            pos = { nLabelX, -10 },
            linecode = 'HUDHUD009TEXT',
            style = 'dosisregular40',
            rect = { 0, 300, 400, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'BackHotkey',
            type = 'textBox',
            pos = { nHotkeyX - 4, -50 },
            text = 'ESC',
            style = 'dosissemibold22',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'MenuSublabel',
            type = 'textBox',
            pos = { 40, -244 },
            linecode = "HUDHUD026TEXT",
            style = 'dosissemibold22',
            rect = { 0, 100, 400, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.GREY,
        },
        {
            key = 'CancelButton',
            type = 'onePixelButton',
            pos = { 0, -nButtonHeight },
            scale = { nButtonWidth, nButtonHeight },
            color = CONSTRUCT_CANCEL,
            hidden = true,
            onHoverOn =
            {
                { key = 'CancelButton', hidden = false, },
                { key = 'CancelIcon', color = Gui.BLACK, },
                { key = 'CancelLabel', color = Gui.BLACK, },
                { key = 'CancelHotkey', color = Gui.BLACK, },
                { playSfx = 'hilight', },
            },
            onHoverOff =
            {
                { key = 'CancelButton', hidden = true, },
                { key = 'CancelIcon', color = CONSTRUCT_CANCEL, },
                { key = 'CancelLabel', color = CONSTRUCT_CANCEL, },
                { key = 'CancelHotkey', color = CONSTRUCT_CANCEL, },
            },
        },
        {
            key = 'ConfirmButton',
            type = 'onePixelButton',
            pos = { 0, -nButtonHeight * 2 },
            scale = { nButtonWidth, nButtonHeight },
            color = CONSTRUCT_CONFIRM,
            hidden = true,
            onPressed =
            {
                { key = 'ConfirmButton', color = BRIGHT_AMBER, },
            },
            onReleased =
            {
                { key = 'ConfirmButton', color = AMBER, },
            },
            onHoverOn =
            {
                { key = 'ConfirmButton', hidden = false, },
                { key = 'ConfirmLabel', color = Gui.BLACK, },
                { key = 'ConfirmIcon', color = Gui.BLACK, },
                { key = 'ConfirmHotkey', color = Gui.BLACK, },
                { key = 'CostBackground', color = CONSTRUCT_CONFIRM, },
                { key = 'CostBackgroundEndCap', color = CONSTRUCT_CONFIRM, },
                { key = 'CostVerticalRule', color = Gui.BLACK, },
                { key = 'CostIconMatter', color = Gui.BLACK, },
                { key = 'CostText', color = Gui.BLACK, },
                { playSfx = 'hilight', },
            },
            onHoverOff =
            {
                { key = 'ConfirmButton', hidden = true, },
                { key = 'ConfirmLabel', color = CONSTRUCT_CONFIRM, },
                { key = 'ConfirmIcon', color = CONSTRUCT_CONFIRM, },
                { key = 'ConfirmHotkey', color = CONSTRUCT_CONFIRM, },
                { key = 'CostBackground', color = Gui.BLACK, },
                { key = 'CostBackgroundEndCap', color = Gui.BLACK, },
                { key = 'CostVerticalRule', color = CONSTRUCT_CONFIRM, },
                { key = 'CostIconMatter', color = CONSTRUCT_CONFIRM, },
                { key = 'CostText', color = CONSTRUCT_CONFIRM, },
            },
        },
        {
            key = 'DoorButton',
            type = 'onePixelButton',
            pos = { 0, -nButtonStartY },
            scale = { nButtonWidth, nButtonHeight },
            color = AMBER,
            hidden = true,
            onPressed =
            {
                { key = 'DoorButton', color = BRIGHT_AMBER, },
            },
            onReleased =
            {
                { key = 'DoorButton', color = AMBER, },
            },
            onHoverOn =
            {
                { key = 'DoorButton', hidden = false, },
                { key = 'DoorLabel', color = Gui.BLACK, },
                { key = 'DoorIcon', color = Gui.BLACK, },
                { key = 'DoorHotkey', color = Gui.BLACK, },
                { playSfx = 'hilight', },
            },
            onHoverOff =
            {
                { key = 'DoorButton', hidden = true, },
                { key = 'DoorLabel', color = Gui.AMBER, },
                { key = 'DoorIcon', color = Gui.AMBER, },
                { key = 'DoorHotkey', color = Gui.AMBER, },
            },
        },
        {
            key = 'AirlockButton',
            type = 'onePixelButton',
            pos = { 0, -(nButtonStartY + nButtonHeight) },
            scale = { nButtonWidth, nButtonHeight },
            color = AMBER,
            hidden = true,
            onPressed =
            {
                { key = 'AirlockButton', color = BRIGHT_AMBER, },
            },
            onReleased =
            {
                { key = 'AirlockButton', color = AMBER, },
            },
            onHoverOn =
            {
                { key = 'AirlockButton', hidden = false, },
                { key = 'AirlockLabel', color = Gui.BLACK, },
                { key = 'AirlockIcon', color = Gui.BLACK, },
                { key = 'AirlockHotkey', color = Gui.BLACK, },
                { playSfx = 'hilight', },
            },
            onHoverOff =
            {
                { key = 'AirlockButton', hidden = true, },
                { key = 'AirlockLabel', color = Gui.AMBER, },
                { key = 'AirlockIcon', color = Gui.AMBER, },
                { key = 'AirlockHotkey', color = Gui.AMBER, },
            },
        },
        {
            key = 'HeavyDoorButton',
            type = 'onePixelButton',
            pos = { 0, -(nButtonStartY + nButtonHeight*2) },
            scale = { nButtonWidth, nButtonHeight },
            color = AMBER,
            hidden = true,
            onPressed =
            {
                { key = 'HeavyDoorButton', color = BRIGHT_AMBER, },
            },
            onReleased =
            {
                { key = 'HeavyDoorButton', color = AMBER, },
            },
            onHoverOn =
            {
                { key = 'HeavyDoorButton', hidden = false, },
                { key = 'HeavyDoorLabel', color = Gui.BLACK, },
                { key = 'HeavyDoorIcon', color = Gui.BLACK, },
                { key = 'HeavyDoorHotkey', color = Gui.BLACK, },
                { playSfx = 'hilight', },
            },
            onHoverOff =
            {
                { key = 'HeavyDoorButton', hidden = true, },
                { key = 'HeavyDoorLabel', color = Gui.AMBER, },
                { key = 'HeavyDoorIcon', color = Gui.AMBER, },
                { key = 'HeavyDoorHotkey', color = Gui.AMBER, },
            },
        },
        {
            key = 'CancelIcon',
            type = 'uiTexture',
            textureName = 'ui_iconIso_decline',
            sSpritesheetPath = 'UI/Shared',
            pos = { nIconX, nCancelIconStartY },
            color = CONSTRUCT_CANCEL,
            scale = { nIconScale, nIconScale }
        },
        {
            key = 'ConfirmIcon',
            type = 'uiTexture',
            textureName = 'ui_iconIso_confirm',
            sSpritesheetPath = 'UI/Shared',
            pos = { nIconX, nCancelIconStartY - nButtonHeight },
            color = CONSTRUCT_CONFIRM,
            scale = { nIconScale, nIconScale }
        },
        {
            key = 'DoorIcon',
            type = 'uiTexture',
            textureName = 'icon_door',
            sSpritesheetPath = 'UI/Shared',
            pos = { nIconX, nIconStartY },
            color = Gui.AMBER,
            scale = { nIconScale, nIconScale }
        },
        {
            key = 'AirlockIcon',
            type = 'uiTexture',
            textureName = 'icon_airlock_door',
            sSpritesheetPath = 'UI/Shared',
            pos = { nIconX, nIconStartY - nButtonHeight },
            color = Gui.AMBER,
            scale = { nIconScale, nIconScale }
        },
        {
            key = 'HeavyDoorIcon',
            type = 'uiTexture',
            textureName = 'icon_heavydoor',
            sSpritesheetPath = 'UI/Shared',
            pos = { nIconX, nIconStartY - nButtonHeight*2 },
            color = Gui.AMBER,
            scale = { nIconScale, nIconScale }
        },
        {
            key = 'CancelLabel',
            type = 'textBox',
            pos = { nLabelX, nCancelLabelStartY },
            linecode = 'HUDHUD034TEXT',
            style = 'dosisregular40',
            rect = { 0, 300, 200, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = CONSTRUCT_CANCEL,
        },
        {
            key = 'ConfirmLabel',
            type = 'textBox',
            pos = { nLabelX, nCancelLabelStartY - nButtonHeight },
            linecode = 'HUDHUD019TEXT',
            style = 'dosisregular40',
            rect = { 0, 300, 280, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = CONSTRUCT_CONFIRM,
        },
        {
            key = 'DoorLabel',
            type = 'textBox',
            pos = { nLabelX, nLabelStartY },
            linecode = 'HUDHUD015TEXT',
            style = 'dosisregular40',
            rect = { 0, 300, nTextHeight, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'AirlockLabel',
            type = 'textBox',
            pos = { nLabelX, nLabelStartY - nButtonHeight },
            linecode = 'HUDHUD016TEXT',
            style = 'dosisregular40',
            rect = { 0, 300, 280, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'HeavyDoorLabel',
            type = 'textBox',
            pos = { nLabelX, nLabelStartY - nButtonHeight*2 },
            linecode = 'HUDHUD044TEXT',
            style = 'dosisregular40',
            rect = { 0, 300, 280, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'CancelHotkey',
            type = 'textBox',
            pos = { nHotkeyX, nCancelHotkeyY },
            text = 'X',
            style = 'dosissemibold22',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = CONSTRUCT_CANCEL,
        },
        {
            key = 'ConfirmHotkey',
            type = 'textBox',
            pos = { nHotkeyX, nCancelHotkeyY - nButtonHeight },
            text = 'C',
            style = 'dosissemibold22',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = CONSTRUCT_CONFIRM
        },
        {
            key = 'DoorHotkey',
            type = 'textBox',
            pos = { nHotkeyX, nHotkeyStartY },
            text = '1',
            style = 'dosissemibold22',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'AirlockHotkey', --now AIRLOCK DOOR
            type = 'textBox',
            pos = { nHotkeyX, nHotkeyStartY - nButtonHeight },
            text = '2',
            style = 'dosissemibold22',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'HeavyDoorHotkey',
            type = 'textBox',
            pos = { nHotkeyX, nHotkeyStartY - nButtonHeight*2 },
            text = '3',
            style = 'dosissemibold22',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'NoFundsLabel',
			hidden = true,
            type = 'textBox',
            pos = { nButtonWidth + 30, -810 },
			linecode = 'BUILDM016TEXT',
            style = 'dosisregular40',
            rect = { 0, 300, 500, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.RED,
        },
        {
            key = 'SelectionHighlight',
            type = 'onePixel',
            pos = { 0, 0 },
            scale = { nButtonWidth, nButtonHeight },
            color = SELECTION_AMBER,
        },
        {
            key = 'DoorCostLabel',
            type = 'textBox',
            pos = { nLabelX, nLabelStartY - 42 },
			linecode = 'BUILDM023TEXT',
            style = 'dosissemibold22',
            rect = { 0, 300, nButtonWidth, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'AirlockDoorCostLabel',
            type = 'textBox',
            pos = { nLabelX, nLabelStartY - nButtonHeight - 42 },
			linecode = 'BUILDM023TEXT',
            style = 'dosissemibold22',
            rect = { 0, 300, nButtonWidth, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'HeavyDoorCostLabel',
            type = 'textBox',
            pos = { nLabelX, nLabelStartY - nButtonHeight*2 - 42 },
			linecode = 'BUILDM023TEXT',
            style = 'dosissemibold22',
            rect = { 0, 300, nButtonWidth, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        -- cost submenu
        {
            key = 'CostBackground',
            type = 'onePixel',
            pos = { nButtonWidth, -nButtonHeight * 2 },
            scale = { nBGWidth, nButtonHeight },
            color = CONSTRUCT_CONFIRM,
        },
        {
            key = 'CostBackgroundEndCap',
            type = 'uiTexture',
            textureName = 'ui_confirm_endcap',
            sSpritesheetPath = 'UI/Shared',
            pos = { nButtonWidth + nBGWidth - 1, -nButtonHeight * 2 },
            color = CONSTRUCT_CONFIRM,
        },
        {
            key = 'CostVerticalRule',
            type = 'uiTexture',
            textureName = 'ui_confirm_verticalrule',
            sSpritesheetPath = 'UI/Shared',
            pos = { nButtonWidth, -(nButtonHeight * 2) - 4 },
            color = { 0, 0, 0 },
        },
        {
            key = 'CostIconMatter',
            type = 'uiTexture',
            textureName = 'ui_confirm_iconmatter',
            sSpritesheetPath = 'UI/Shared',
            pos = { nButtonWidth + 10, -(nButtonHeight * 2) - 10 },
            color = { 0, 0, 0 },
        },
        {
            key = 'CostText',
            type = 'textBox',
            pos = { nButtonWidth + 34, -(nButtonHeight * 2) - 4 },
            text = "-450 Build\n+75 Demolish\n+36 Undo",
            style = 'dosissemibold18',
            rect = { 0, 100, 500, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = { 0, 0, 0 },
        },
        {
            key = 'SidebarBottomEndcapExpanded',
            type = 'uiTexture',
            textureName = 'ui_hud_anglebottom',
            sSpritesheetPath = 'UI/HUD',
            pos = { 0, -(nButtonStartY + 3*nButtonHeight) },
            scale = { 1.68, 1.68 },
            color = Gui.SIDEBAR_BG,
        },
    }
}