local Gui = require('UI.Gui')

local sFlipBorderX = '0'
local sFlipBorderTopY = 30
local sFlipBorderBottomY = sFlipBorderTopY .. ' - 206'
local sFlipLabelX = sFlipBorderX .. ' + 4'
local sFlipHotkeyX = sFlipBorderX .. ' + 176'
local sFlipTextY = sFlipBorderTopY .. ' + 41'
local sFlipArrowsX = sFlipBorderX .. ' + 76'
local sFlipArrowsY = sFlipBorderTopY .. ' - 124'
local sFlipButtonX = sFlipBorderX .. ' + 1'
local sFlipButtonY = sFlipBorderTopY .. ' - 1'
local nFlipButtonW = 193
local nFlipButtonH = 206

return 
{
    posInfo =
        {
        --[[
        alignX = 'right',
        alignY = 'top',
        offsetX = -1150,
        offsetY = 36,
        scale = { 1, 1 },
        ]]--
    },
    tElements =    
    {
        -- flip zone
       {
            key = 'FlipButton',
            type = 'onePixelButton',
            pos = { sFlipButtonX, sFlipButtonY },
            scale = { nFlipButtonW, nFlipButtonH },
            color = {0.2, 0.2, 0.2, 0.01},
            hidden = true,
            onHoverOn =
            {
                {
                    key = 'FlipButton',
                    hidden = false,
                },
                {
                    playSfx = 'hilight',
                },
            },
            onHoverOff =
            { 
                {
                    key = 'FlipButton',
                    hidden = true,
                },
            },
        },  
        {
            key = 'FlipLabel',
            type = 'textBox',
            pos = { sFlipLabelX, sFlipTextY },
            text = 'Flip Object',
            style = 'dosissemibold26',
            rect = { 0, 100, 300, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'FlipHotkey',
            type = 'textBox',
            pos = { sFlipHotkeyX, sFlipTextY },
            text = 'F',
            style = 'dosissemibold26',
            rect = { 0, 100, 300, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'FlipZoneTop',
            type = 'uiTexture',
            textureName = 'ui_flip_border',
            sSpritesheetPath = 'UI/HUD',
            pos = { sFlipBorderX, sFlipBorderTopY },
            scale = {1.0, 1.0},
            color = Gui.AMBER,        
        },
        {
            key = 'FlipZoneBottom',
            type = 'uiTexture',
            textureName = 'ui_flip_border',
            sSpritesheetPath = 'UI/HUD',
            pos = { sFlipBorderX, sFlipBorderBottomY },
            scale = {1.0, -1.0},
            color = Gui.AMBER,        
        },     
        {
            key = 'FlipZoneArrows',
            type = 'uiTexture',
            textureName = 'ui_flip_arrows',
            sSpritesheetPath = 'UI/HUD',
            pos = { sFlipArrowsX, sFlipArrowsY },
            scale = {1.0, -1.0},
            color = Gui.AMBER,        
        },
    },
}
