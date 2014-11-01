local Gui = require('UI.Gui')

local AMBER = { Gui.AMBER[1], Gui.AMBER[2], Gui.AMBER[3], 0.95 }
local BRIGHT_AMBER = { Gui.AMBER[1], Gui.AMBER[2], Gui.AMBER[3], 1 }
local SELECTION_AMBER = { Gui.AMBER[1], Gui.AMBER[2], Gui.AMBER[3], 0.01 }

local CONSTRUCT_CONFIRM = Gui.GREEN

local nButtonWidth, nButtonHeight  = 330, 81
local nTextHeight = nButtonHeight + 20
local nButtonStartY = -123
local nIconX, nIconStartY = 10, -125
local nLabelX, nLabelStartY = 105, -133
local nHotkeyX, nHotkeyStartY = nButtonWidth - 112, -169
local nIconScale = .6
local numButtons = 2
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
            scale = { nButtonWidth, -nButtonStartY + (nButtonHeight * numButtons) },
            color = Gui.SIDEBAR_BG,
        },
        {
            key = 'DoneButton',
            type = 'onePixelButton',
            pos = { 0, 0 },
            scale = { nButtonWidth, nButtonHeight },
            color = Gui.BLACK,
            onPressed =
            {
                {
                    key = 'DoneButton',
                    color = BRIGHT_AMBER,
                },            
            },
            onReleased =
            {
                {
                    key = 'DoneButton',
                    color = AMBER,
                },
            },
            onHoverOn =
            {
                {
                    key = 'DoneButton',
                    color = CONSTRUCT_CONFIRM,
                },
                {
                    key = 'DoneLabel',
                    color = { 0, 0, 0 },
                },
                {
                    key = 'DoneHotkey',
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
                    key = 'DoneButton',
                    color = Gui.BLACK,
                },
                {
                    key = 'DoneLabel',
                    color = CONSTRUCT_CONFIRM,
                },
                {
                    key = 'DoneHotkey',
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
            key = 'MineButton',
            type = 'onePixelButton',
            pos = { 0, nButtonStartY },
            scale = { nButtonWidth, nButtonHeight },
            color = Gui.BLACK,
            onPressed =
            {
                {
                    key = 'MineButton',
                    color = BRIGHT_AMBER,
                },            
            },
            onReleased =
            {
                {
                    key = 'MineButton',
                    color = AMBER,
                },       
            },
            onHoverOn =
            {
                {
                    key = 'MineButton',
                    color = Gui.AMBER,
                },
                {
                    key = 'MineLabel',
                    color = { 0, 0, 0 },
                },
                {
                    key = 'MineIcon',
                    color = { 0, 0, 0 },
                },                
                {
                    key = 'MineHotkey',
                    color = { 0, 0, 0 },
                },
                {
                    playSfx = 'hilight',
                },
            },
            onHoverOff =
            {
                {
                    key = 'MineButton',
                    color = Gui.BLACK,
                },
                {
                    key = 'MineLabel',
                    color = Gui.AMBER,
                },
                {
                    key = 'MineIcon',
                    color = Gui.AMBER,
                },  
                {
                    key = 'MineHotkey',
                    color = Gui.AMBER,
                },
            },
        },
        {
            key = 'EraseButton',
            type = 'onePixelButton',
            pos = { 0, nButtonStartY - nButtonHeight },
            scale = { nButtonWidth, nButtonHeight },
            color = Gui.BLACK,
            onPressed =
            {
                {
                    key = 'EraseButton',
                    color = BRIGHT_AMBER,
                },            
            },
            onReleased =
            {
                {
                    key = 'EraseButton',
                    color = AMBER,
                },       
            },
            onHoverOn =
            {
                {
                    key = 'EraseButton',
                    color = Gui.AMBER,
                },
                {
                    key = 'EraseLabel',
                    color = { 0, 0, 0 },
                },
                {
                    key = 'EraseIcon',
                    color = { 0, 0, 0 },
                },                
                {
                    key = 'EraseHotkey',
                    color = { 0, 0, 0 },
                },
                {
                    playSfx = 'hilight',
                },
            },
            onHoverOff =
            {
                {
                    key = 'EraseButton',
                    color = Gui.BLACK,
                },
                {
                    key = 'EraseLabel',
                    color = Gui.AMBER,
                },
                {
                    key = 'EraseIcon',
                    color = Gui.AMBER,
                },  
                {
                    key = 'EraseHotkey',
                    color = Gui.AMBER,
                },
            },
        },
        {
            key = 'MineIcon',
            type = 'uiTexture',
            textureName = 'ui_iconIso_mine',
            sSpritesheetPath = 'UI/Shared',
            pos = { nIconX, nIconStartY },
            color = Gui.AMBER,
            scale = { nIconScale, nIconScale }
        },
        {
            key = 'EraseIcon',
            type = 'uiTexture',
            textureName = 'ui_iconIso_erase',
            sSpritesheetPath = 'UI/Shared',
            pos = { nIconX, nIconStartY - nButtonHeight },
            color = Gui.AMBER,
            scale = { nIconScale, nIconScale }
        },
        {
            key = 'MenuSublabel',
            type = 'textBox',
            pos = { 40, -85 },
            linecode = "HUDHUD010TEXT",
            style = 'dosissemibold22',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.GREY,
        },
        {
            key = 'DoneLabel',
            type = 'textBox',
            pos = { nLabelX, -10 },
            linecode = 'HUDHUD019TEXT',
            style = 'dosisregular40',
            rect = { 0, 300, 280, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = CONSTRUCT_CONFIRM,
        },
        {
            key = 'MineLabel',
            type = 'textBox',
            pos = { nLabelX, nLabelStartY },
            linecode = 'HUDHUD008TEXT',
            style = 'dosisregular40',
            rect = { 0, 300, 280, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'EraseLabel',
            type = 'textBox',
            pos = { nLabelX, nLabelStartY - nButtonHeight },
            linecode = 'HUDHUD011TEXT',
            style = 'dosisregular40',
            rect = { 0, 300, 280, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'DoneHotkey',
            type = 'textBox',
            pos = { nHotkeyX, -46 },
            text = 'ESC',
            style = 'dosissemibold22',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = CONSTRUCT_CONFIRM
        },
        {
            key = 'MineHotkey',
            type = 'textBox',
            pos = { nHotkeyX, nHotkeyStartY },
            text = 'M',
            style = 'dosissemibold22',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'EraseHotkey',
            type = 'textBox',
            pos = { nHotkeyX, nHotkeyStartY - nButtonHeight },
            text = 'E',
            style = 'dosissemibold22',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'SelectionHighlight',
            type = 'onePixel',
            pos = { 0, 0 },
            scale = { nButtonWidth, nButtonHeight },
            color = SELECTION_AMBER,
            hidden = true,
        },
        -- cost submenu
        {
            key = 'CostBackground',
            type = 'onePixel',
            pos = { nButtonWidth, 0 },
            scale = { nBGWidth, nButtonHeight },
            color = CONSTRUCT_CONFIRM,
        },    
        {
            key = 'CostBackgroundEndCap',
            type = 'uiTexture',
            textureName = 'ui_confirm_endcap',
            sSpritesheetPath = 'UI/Shared',
            pos = { nButtonWidth + nBGWidth - 1, 0 },
            color = CONSTRUCT_CONFIRM,
        },   
        {
            key = 'CostVerticalRule',
            type = 'uiTexture',
            textureName = 'ui_confirm_verticalrule',
            sSpritesheetPath = 'UI/Shared',
            pos = { nButtonWidth, -4 },
            color = { 0, 0, 0 },
        },     
        {
            key = 'CostIconMatter',
            type = 'uiTexture',
            textureName = 'ui_confirm_iconmatter',
            sSpritesheetPath = 'UI/Shared',
            pos = { nButtonWidth + 10, -10 },
            color = { 0, 0, 0 },
        },   
        {
            key = 'CostText',
            type = 'textBox',
            pos = { nButtonWidth + 34, -4 },
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
            pos = { 0, nButtonStartY - numButtons*nButtonHeight },
            scale = { 1.28, 1.28 },            
            color = Gui.SIDEBAR_BG,
        },
    },
}