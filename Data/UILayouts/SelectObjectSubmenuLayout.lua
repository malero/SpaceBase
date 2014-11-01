local Gui = require('UI.Gui')

local AMBER = { Gui.AMBER[1], Gui.AMBER[2], Gui.AMBER[3], 0.95 }
local BRIGHT_AMBER = { Gui.AMBER[1], Gui.AMBER[2], Gui.AMBER[3], 1 }
local SELECTION_AMBER = { Gui.AMBER[1], Gui.AMBER[2], Gui.AMBER[3], 0.01 }

local CONSTRUCT_CANCEL = Gui.RED
local CONSTRUCT_CONFIRM = Gui.GREEN

local nButtonWidth, nButtonHeight  = 430, 81
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
            {
                key = 'CostBackground',
                hidden = false,
            },
            {
                key = 'CostBackgroundEndCap',
                hidden = false,
            },
            {
                key = 'CostVerticalRule',
                hidden = false,
            },
            {
                key = 'CostIconMatter',
                hidden = false,
            },
            {
                key = 'CostText',
                hidden = false,
            },
        },
        onHideMatterCost =
        {
            {
                key = 'CostBackground',
                hidden = true,
            },
            {
                key = 'CostBackgroundEndCap',
                hidden = true,
            },
            {
                key = 'CostVerticalRule',
                hidden = true,
            },
            {
                key = 'CostIconMatter',
                hidden = true,
            },
            {
                key = 'CostText',
                hidden = true,
            },            
        },
    }, 
    tElements =
    {       
        {
            key = 'LargeBar',
            type = 'onePixel',
            pos = { 0, 0 },
            scale = { nButtonWidth, (nButtonStartY + 7*nButtonHeight) },
            color = Gui.SIDEBAR_BG,
        },
        {
            key = 'BackButton',
            type = 'onePixelButton',
            pos = { 0, 0 },
            scale = { nButtonWidth, nButtonHeight },
            color = Gui.BLACK,
            onPressed =
            {
                {
                    key = 'BackButton',
                    color = BRIGHT_AMBER,
                },            
            },
            onReleased =
            {
                {
                    key = 'BackButton',
                    color = AMBER,
                },       
            },
            onHoverOn =
            {
                {
                    key = 'BackButton',
                    color = Gui.AMBER,
                },
                {
                    key = 'BackLabel',
                    color = { 0, 0, 0 },
                },          
                {
                    key = 'BackHotkey',
                    color = { 0, 0, 0 },                    
                },
                {
                    playSfx = 'hilight',
                },
            },
            onHoverOff =
            {
                {
                    key = 'BackButton',
                    color = Gui.BLACK,
                },
                {
                    key = 'BackLabel',
                    color = Gui.AMBER,
                },
                {
                    key = 'BackHotkey',
                    color = Gui.AMBER,
                },
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
            color = Gui.BLACK,
            onHoverOn =
            {
                {
                    key = 'CancelButton',
                    color = CONSTRUCT_CANCEL,
                },
                {
                    key = 'CancelIcon',
                    color = { 0, 0, 0 },
                },   
                {
                    key = 'CancelLabel',
                    color = { 0, 0, 0 },
                },          
                {
                    key = 'CancelHotkey',
                    color = { 0, 0, 0 },                    
                },
                {
                    playSfx = 'hilight',
                },
            },
            onHoverOff =
            {
                {
                    key = 'CancelButton',
                    color = Gui.BLACK,
                },
                {
                    key = 'CancelIcon',
                    color = CONSTRUCT_CANCEL,
                },   
                {
                    key = 'CancelLabel',
                    color = CONSTRUCT_CANCEL,
                },
                {
                    key = 'CancelHotkey',
                    color = CONSTRUCT_CANCEL,
                },
            },
        },
        {
            key = 'ConfirmButton',
            type = 'onePixelButton',
            pos = { 0, -nButtonHeight * 2 },
            scale = { nButtonWidth, nButtonHeight },
            color = Gui.BLACK,
            onPressed =
            {
                {
                    key = 'ConfirmButton',
                    color = BRIGHT_AMBER,
                },            
            },
            onReleased =
            {
                {
                    key = 'ConfirmButton',
                    color = AMBER,
                },
            },
            onHoverOn =
            {
                {
                    key = 'ConfirmButton',
                    color = CONSTRUCT_CONFIRM,
                },
                {
                    key = 'ConfirmLabel',
                    color = { 0, 0, 0 },
                },
                {
                    key = 'ConfirmIcon',
                    color = { 0, 0, 0 },
                },                
                {
                    key = 'ConfirmHotkey',
                    color = { 0, 0, 0 },
                },
                {
                    key = 'CostBackground',
                    color = CONSTRUCT_CONFIRM,
                },
                {
                    key = 'CostBackgroundEndCap',
                    color = CONSTRUCT_CONFIRM,
                },
                {
                    key = 'CostVerticalRule',
                    color = { 0, 0, 0 },
                },
                {
                    key = 'CostIconMatter',
                    color = { 0, 0, 0 },
                },
                {
                    key = 'CostText',
                    color = { 0, 0, 0 },
                },
                {
                    playSfx = 'hilight',
                },
            },
            onHoverOff =
            {
                {
                    key = 'ConfirmButton',
                    color = Gui.BLACK,
                },
                {
                    key = 'ConfirmLabel',
                    color = CONSTRUCT_CONFIRM,
                },
                {
                    key = 'ConfirmIcon',
                    color = CONSTRUCT_CONFIRM,
                },  
                {
                    key = 'ConfirmHotkey',
                    color = CONSTRUCT_CONFIRM,
                },
                {
                    key = 'CostBackground',
                    color = { 0, 0, 0 },
                },
                {
                    key = 'CostBackgroundEndCap',
                    color = { 0, 0, 0 },
                },
                {
                    key = 'CostVerticalRule',
                    color = CONSTRUCT_CONFIRM,
                },
                {
                    key = 'CostIconMatter',
                    color = CONSTRUCT_CONFIRM,
                },
                {
                    key = 'CostText',
                    color = CONSTRUCT_CONFIRM,
                },
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
            pos = { 0, -(nButtonStartY + 7*nButtonHeight) + 1 },
            scale = { 1.68, 1.68 },            
            color = Gui.SIDEBAR_BG,
        },
    }
}