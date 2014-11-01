local Gui = require('UI.Gui')

local AMBER = { Gui.AMBER[1], Gui.AMBER[2], Gui.AMBER[3], 0.95 }
local BRIGHT_AMBER = { Gui.AMBER[1], Gui.AMBER[2], Gui.AMBER[3], 1 }
local SELECTION_AMBER = { Gui.AMBER[1], Gui.AMBER[2], Gui.AMBER[3], 0.01 }

local CONSTRUCT_CANCEL = Gui.RED
local CONSTRUCT_CONFIRM = Gui.GREEN

local nButtonWidth, nButtonHeight  = 330, 81
local nTextHeight = nButtonHeight + 20
local nButtonStartY = -204
local nIconX, nIconStartY = 10, -206
local nCancelIconStartY = -2
local nLabelX, nLabelStartY = 105, -214
local nCancelLabelStartY = -10
local nHotkeyX, nHotkeyStartY = nButtonWidth - 112, -250
local nCancelHotkeyY = -46
local nIconScale = .6
local numButtons = 7
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
            key = 'CancelButton',
            type = 'onePixelButton',
            pos = { 0, 0 },
            scale = { nButtonWidth, nButtonHeight },
            color = CONSTRUCT_CANCEL,
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
            pos = { 0, -nButtonHeight },
            scale = { nButtonWidth, nButtonHeight },
            color = CONSTRUCT_CONFIRM,
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
            key = 'AreaButton',
            type = 'onePixelButton',
            pos = { 0, nButtonStartY },
            scale = { nButtonWidth, nButtonHeight },
            color = Gui.BLACK,
            onPressed =
            {
                {
                    key = 'AreaButton',
                    color = BRIGHT_AMBER,
                },            
            },
            onReleased =
            {
                {
                    key = 'AreaButton',
                    color = AMBER,
                },       
            },
            onHoverOn =
            {
                {
                    key = 'AreaButton',
                    color = Gui.AMBER,
                },
                {
                    key = 'AreaLabel',
                    color = { 0, 0, 0 },
                },
                {
                    key = 'AreaIcon',
                    color = { 0, 0, 0 },
                },                
                {
                    key = 'AreaHotkey',
                    color = { 0, 0, 0 },
                },
                {
                    playSfx = 'hilight',
                },
            },
            onHoverOff =
            {
                {
                    key = 'AreaButton',
                    color = Gui.BLACK,
                },
                {
                    key = 'AreaLabel',
                    color = Gui.AMBER,
                },
                {
                    key = 'AreaIcon',
                    color = Gui.AMBER,
                },  
                {
                    key = 'AreaHotkey',
                    color = Gui.AMBER,
                },
            },
        },
        {
            key = 'WallButton',
            type = 'onePixelButton',
            pos = { 0, nButtonStartY - nButtonHeight },
            scale = { nButtonWidth, nButtonHeight },
            color = Gui.BLACK,
            onPressed =
            {
                {
                    key = 'WallButton',
                    color = BRIGHT_AMBER,
                },            
            },
            onReleased =
            {
                {
                    key = 'WallButton',
                    color = AMBER,
                },       
            },
            onHoverOn =
            {
                {
                    key = 'WallButton',
                    color = Gui.AMBER,
                },
                {
                    key = 'WallLabel',
                    color = { 0, 0, 0 },
                },
                {
                    key = 'WallIcon',
                    color = { 0, 0, 0 },
                },                
                {
                    key = 'WallHotkey',
                    color = { 0, 0, 0 },
                },
                {
                    playSfx = 'hilight',
                },
            },
            onHoverOff =
            {
                {
                    key = 'WallButton',
                    color = Gui.BLACK,
                },
                {
                    key = 'WallLabel',
                    color = Gui.AMBER,
                },
                {
                    key = 'WallIcon',
                    color = Gui.AMBER,
                },  
                {
                    key = 'WallHotkey',
                    color = Gui.AMBER,
                },
            },
        },
        {
            key = 'FloorButton',
            type = 'onePixelButton',
            pos = { 0, nButtonStartY - (nButtonHeight*2) },
            scale = { nButtonWidth, nButtonHeight },
            color = AMBER,
            color = Gui.BLACK,
            onPressed =
            {
                {
                    key = 'FloorButton',
                    color = BRIGHT_AMBER,
                },            
            },
            onReleased =
            {
                {
                    key = 'FloorButton',
                    color = AMBER,
                },       
            },
            onHoverOn =
            {
                {
                    key = 'FloorButton',
                    color = Gui.AMBER,
                },
                {
                    key = 'FloorLabel',
                    color = { 0, 0, 0 },
                },
                {
                    key = 'FloorIcon',
                    color = { 0, 0, 0 },
                },                
                {
                    key = 'FloorHotkey',
                    color = { 0, 0, 0 },
                },
                {
                    playSfx = 'hilight',
                },
            },
            onHoverOff =
            {
                {
                    key = 'FloorButton',
                    color = Gui.BLACK,
                },
                {
                    key = 'FloorLabel',
                    color = Gui.AMBER,
                },
                {
                    key = 'FloorIcon',
                    color = Gui.AMBER,
                },  
                {
                    key = 'FloorHotkey',
                    color = Gui.AMBER,
                },
            },
        },
        {
            key = 'ObjectButton',
            type = 'onePixelButton',
            pos = { 0, nButtonStartY - (nButtonHeight*3) },
            scale = { nButtonWidth, nButtonHeight },
            color = AMBER,
            color = Gui.BLACK,
            onPressed =
            {
                {
                    key = 'ObjectButton',
                    color = BRIGHT_AMBER,
                },            
            },
            onReleased =
            {
                {
                    key = 'ObjectButton',
                    color = AMBER,
                },       
            },
            onHoverOn =
            {
                {
                    key = 'ObjectButton',
                    color = Gui.AMBER,
                },
                {
                    key = 'ObjectLabel',
                    color = { 0, 0, 0 },
                },
                {
                    key = 'ObjectIcon',
                    color = { 0, 0, 0 },
                },       
                {
                    playSfx = 'hilight',
                },     
            },
            onHoverOff =
            {
                {
                    key = 'ObjectButton',
                    color = Gui.BLACK,
                },
                {
                    key = 'ObjectLabel',
                    color = Gui.AMBER,
                },
                {
                    key = 'ObjectIcon',
                    color = Gui.AMBER,
                },  
            },
        },
        {
            key = 'DemolishButton',
            type = 'onePixelButton',
            pos = { 0, nButtonStartY - (nButtonHeight*4) },
            scale = { nButtonWidth, nButtonHeight },
            color = AMBER,
            color = Gui.BLACK,
            onPressed =
            {
                {
                    key = 'DemolishButton',
                    color = BRIGHT_AMBER,
                },            
            },
            onReleased =
            {
                {
                    key = 'DemolishButton',
                    color = AMBER,
                },       
            },
            onHoverOn =
            {
                {
                    key = 'DemolishButton',
                    color = Gui.AMBER,
                },
                {
                    key = 'DemolishLabel',
                    color = { 0, 0, 0 },
                },
                {
                    key = 'DemolishIcon',
                    color = { 0, 0, 0 },
                },                
                {
                    key = 'DemolishHotkey',
                    color = { 0, 0, 0 },
                },
                {
                    playSfx = 'hilight',
                },
            },
            onHoverOff =
            {
                {
                    key = 'DemolishButton',
                    color = Gui.BLACK,
                },
                {
                    key = 'DemolishLabel',
                    color = Gui.AMBER,
                },
                {
                    key = 'DemolishIcon',
                    color = Gui.AMBER,
                },  
                {
                    key = 'DemolishHotkey',
                    color = Gui.AMBER,
                },
            },
        },
        {
            key = 'VaporizeButton',
            type = 'onePixelButton',
            pos = { 0, nButtonStartY - (nButtonHeight*5) },
            scale = { nButtonWidth, nButtonHeight },
            color = AMBER,
            color = Gui.BLACK,
            onPressed =
            {
                {
                    key = 'VaporizeButton',
                    color = BRIGHT_AMBER,
                },            
            },
            onReleased =
            {
                {
                    key = 'VaporizeButton',
                    color = AMBER,
                },       
            },
            onHoverOn =
            {
                {
                    key = 'VaporizeButton',
                    color = Gui.AMBER,
                },
                {
                    key = 'VaporizeLabel',
                    color = { 0, 0, 0 },
                },
                {
                    key = 'VaporizeIcon',
                    color = { 0, 0, 0 },
                },                
                {
                    key = 'VaporizeHotkey',
                    color = { 0, 0, 0 },
                },
                {
                    playSfx = 'hilight',
                },
            },
            onHoverOff =
            {
                {
                    key = 'VaporizeButton',
                    color = Gui.BLACK,
                },
                {
                    key = 'VaporizeLabel',
                    color = Gui.AMBER,
                },
                {
                    key = 'VaporizeIcon',
                    color = Gui.AMBER,
                },  
                {
                    key = 'VaporizeHotkey',
                    color = Gui.AMBER,
                },
            },
        },
        {
            key = 'EraseButton',
            type = 'onePixelButton',
            pos = { 0, nButtonStartY - (nButtonHeight * 6) },
            scale = { nButtonWidth, nButtonHeight },
            color = AMBER,
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
            key = 'AreaIcon',
            type = 'uiTexture',
            textureName = 'ui_iconIso_room',
            sSpritesheetPath = 'UI/Shared',
            pos = { nIconX, nIconStartY },
            color = Gui.AMBER,
            scale = { nIconScale, nIconScale }
        },
        {
            key = 'WallIcon',
            type = 'uiTexture',
            textureName = 'ui_iconIso_Wall',
            sSpritesheetPath = 'UI/Shared',
            pos = { nIconX, nIconStartY - nButtonHeight },
            color = Gui.AMBER,
            scale = { nIconScale, nIconScale }
        },
        {
            key = 'FloorIcon',
            type = 'uiTexture',
            textureName = 'ui_iconIso_floor',
            sSpritesheetPath = 'UI/Shared',
            pos = { nIconX, nIconStartY - (nButtonHeight * 2) },
            color = Gui.AMBER,
            scale = { nIconScale, nIconScale }
        },
        {
            key = 'ObjectIcon',
            type = 'uiTexture',
            textureName = 'ui_iconIso_object',
            sSpritesheetPath = 'UI/Shared',
            pos = { nIconX, nIconStartY - (nButtonHeight * 3) },
            scale = {nIconScale, nIconScale},
            color = Gui.AMBER,
        },
        {
            key = 'DemolishIcon',
            type = 'uiTexture',
            textureName = 'ui_iconIso_demolish',
            sSpritesheetPath = 'UI/Shared',
            pos = { nIconX, nIconStartY - (nButtonHeight * 4) },
            color = Gui.AMBER,
            scale = { nIconScale, nIconScale }
        },
        {
            key = 'VaporizeIcon',
            type = 'uiTexture',
            textureName = 'ui_iconIso_demolish',
            sSpritesheetPath = 'UI/Shared',
            pos = { nIconX, nIconStartY - (nButtonHeight * 5) },
            color = Gui.AMBER,
            scale = { nIconScale, nIconScale }
        },
        {
            key = 'EraseIcon',
            type = 'uiTexture',
            textureName = 'ui_iconIso_erase',
            sSpritesheetPath = 'UI/Shared',
            pos = { nIconX, nIconStartY - (nButtonHeight * 6) },
            color = Gui.AMBER,
            scale = { nIconScale, nIconScale }
        },
        {
            key = 'MenuSublabel',
            type = 'textBox',
            pos = { 40, -166 },
            linecode = "HUDHUD012TEXT",
            style = 'dosissemibold22',
            rect = { 0, 100, 200, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.GREY,
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
            key = 'AreaLabel',
            type = 'textBox',
            pos = { nLabelX, nLabelStartY },
            linecode = 'HUDHUD013TEXT',
            style = 'dosisregular40',
            rect = { 0, 300, nTextHeight, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'WallLabel',
            type = 'textBox',
            pos = { nLabelX, nLabelStartY - nButtonHeight },
            linecode = 'HUDHUD014TEXT',
            style = 'dosisregular40',
            rect = { 0, 300, nTextHeight, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'FloorLabel',
            type = 'textBox',
            pos = { nLabelX, nLabelStartY - (nButtonHeight * 2) },
            linecode = 'HUDHUD027TEXT',
            style = 'dosisregular40',
            rect = { 0, 300, nTextHeight, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'ObjectLabel',
            type = 'textBox',
            pos = { nLabelX, nLabelStartY - (nButtonHeight * 3) },
            linecode = 'HUDHUD023TEXT',
            style = 'dosisregular40',
            rect = { 0, 300, nTextHeight, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'DemolishLabel',
            type = 'textBox',
            pos = { nLabelX, nLabelStartY - (nButtonHeight * 4) },
            linecode = 'HUDHUD017TEXT',
            style = 'dosisregular40',
            rect = { 0, 300, 280, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'VaporizeLabel',
            type = 'textBox',
            pos = { nLabelX, nLabelStartY - (nButtonHeight * 5) },
            linecode = 'HUDHUD045TEXT',
            style = 'dosisregular40',
            rect = { 0, 300, 280, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'EraseLabel',
            type = 'textBox',
            pos = { nLabelX, nLabelStartY - (nButtonHeight * 6) },
            linecode = 'HUDHUD011TEXT',
            style = 'dosisregular40',
            rect = { 0, 300, 280, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
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
            key = 'AreaHotkey', --now 'ROOM'
            type = 'textBox',
            pos = { nHotkeyX, nHotkeyStartY },
            text = 'R',
            style = 'dosissemibold22',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'WallHotkey',
            type = 'textBox',
            pos = { nHotkeyX, nHotkeyStartY - nButtonHeight },
            text = 'W',
            style = 'dosissemibold22',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'FloorHotkey',
            type = 'textBox',
            pos = { nHotkeyX, nHotkeyStartY - (nButtonHeight * 2) },
            text = 'F',
            style = 'dosissemibold22',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'ObjectHotkey',
            type = 'textBox',
            pos = { nHotkeyX, nHotkeyStartY - (nButtonHeight * 3) },
            text = 'B',
            style = 'dosissemibold22',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'DemolishHotkey',
            type = 'textBox',
            pos = { nHotkeyX, nHotkeyStartY - (nButtonHeight * 4) },
            text = 'D',
            style = 'dosissemibold22',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'VaporizeHotkey',
            type = 'textBox',
            pos = { nHotkeyX, nHotkeyStartY - (nButtonHeight * 5) },
            text = 'V',
            style = 'dosissemibold22',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'EraseHotkey',
            type = 'textBox',
            pos = { nHotkeyX, nHotkeyStartY - (nButtonHeight * 6) },
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
        },
        -- cost submenu
        {
            key = 'CostBackground',
            type = 'onePixel',
            pos = { nButtonWidth, -nButtonHeight },
            scale = { nBGWidth, nButtonHeight },
            color = CONSTRUCT_CONFIRM,
        },    
        {
            key = 'CostBackgroundEndCap',
            type = 'uiTexture',
            textureName = 'ui_confirm_endcap',
            sSpritesheetPath = 'UI/Shared',
            pos = { nButtonWidth + nBGWidth - 1, -nButtonHeight },
            color = CONSTRUCT_CONFIRM,
        },   
        {
            key = 'CostVerticalRule',
            type = 'uiTexture',
            textureName = 'ui_confirm_verticalrule',
            sSpritesheetPath = 'UI/Shared',
            pos = { nButtonWidth, -nButtonHeight - 4 },
            color = { 0, 0, 0 },
        },     
        {
            key = 'CostIconMatter',
            type = 'uiTexture',
            textureName = 'ui_confirm_iconmatter',
            sSpritesheetPath = 'UI/Shared',
            pos = { nButtonWidth + 10, -nButtonHeight - 10 },
            color = { 0, 0, 0 },
        },   
        {
            key = 'CostText',
            type = 'textBox',
            pos = { nButtonWidth + 34, -nButtonHeight - 4 },
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
            pos = { 0, nButtonStartY - (nButtonHeight * numButtons) },
            scale = { 1.28, 1.28 },            
            color = Gui.SIDEBAR_BG,
        },
    },
}
