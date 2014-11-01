local Gui = require('UI.Gui')

local AMBER = { Gui.AMBER[1], Gui.AMBER[2], Gui.AMBER[3], 0.95 }
local BRIGHT_AMBER = { Gui.AMBER[1], Gui.AMBER[2], Gui.AMBER[3], 1 }
local SELECTION_AMBER = { Gui.AMBER[1], Gui.AMBER[2], Gui.AMBER[3], 0.01 }

return 
{
    posInfo =
        {
        alignX = 'center',
        alignY = 'center',
        --offsetX = -1250,
        offsetX = -510,
        offsetY = 405,
        scale = { .85, .85 },
    },
    tElements =
    {       
        -- BG
        {
            key = 'Background',
            type = 'onePixel',
            pos = { 0, 0 },
            scale = { 1028, 810 },
            color = { 0, 0, 0 },
        },
        -- Border
        {
            key = 'UpperLeftCorner',
            type = 'uiTexture',
            textureName = 'ui_boxCorner_3px',
            sSpritesheetPath = 'UI/Shared',
            pos = { 0, 2 },
            scale = { 3, 3 },
            color = Gui.AMBER,     
        },
        {
            key = 'UpperRightCorner',
            type = 'uiTexture',
            textureName = 'ui_boxCorner_3px',
            sSpritesheetPath = 'UI/Shared',
            pos = { 1034, 2 },
            scale = { -3, 3 },
            color = Gui.AMBER,     
        },
        {
            key = 'BottomLeftCorner',
            type = 'uiTexture',
            textureName = 'ui_boxCorner_3px',
            sSpritesheetPath = 'UI/Shared',
            pos = { 0, -814 },
            scale = { 3, -3 },
            color = Gui.AMBER,     
        },
        {
            key = 'BottomRightCorner',
            type = 'uiTexture',
            textureName = 'ui_boxCorner_3px',
            sSpritesheetPath = 'UI/Shared',
            pos = { 1034, -814 },
            scale = { -3, -3 },
            color = Gui.AMBER,     
        },
        {
            key = 'TopBorder',
            type = 'onePixel',
            pos = { 6, 0 },
            scale = { 1020, 6 },
            color = Gui.AMBER,     
        },
        {
            key = 'BottomBorder',
            type = 'onePixel',
            pos = { 6, -806 },
            scale = { 1020, 6 },
            color = Gui.AMBER,     
        },
        {
            key = 'LeftBorder',
            type = 'onePixel',
            pos = { 0, -6 },
            scale = { 6, 800 },
            color = Gui.AMBER,     
        },
        {
            key = 'RightBorder',
            type = 'onePixel',
            pos = { 1026, -6 },
            scale = { 6, 800 },
            color = Gui.AMBER,     
        },
        -- Portrait
        {
            key = 'PictureBigBG',
            type = 'onePixel',
            pos = { 12, -60 },
            scale = { 1010, 152 }, 
            color = Gui.AMBER,     
        },
        {
            key = 'PictureBG',
            type = 'onePixel',
            pos = { 40, -42 },
            scale = { 148, 20 },
            color = Gui.AMBER,     
        },
        {
            key = 'PictureBGImage',
            type = 'uiTexture',
            textureName = 'Background_01',
            sSpritesheetPath = 'UI/Portraits',
            pos = { 44, -46 },
            scale = { 1.15, 1.15 },
        },
        {
            key = 'Picture',
            type = 'uiTexture',
            textureName = 'Chicken_female_White_01',
            sSpritesheetPath = 'UI/Portraits',
            pos = { 44, -46 },           
            scale = { 1.15, 1.15 },
        },
        
        -- Inner decor
        {
            key = 'InnerBorder',
            type = 'onePixel',
            pos = { 12, -588 },
            scale = { 1008, 6 },
            color = Gui.AMBER,     
        },        
        {
            key = 'StripesTop',
            type = 'uiTexture',
            textureName = 'ui_dialog_docking_stripesTop',
            sSpritesheetPath = 'UI/DialogBox',
            pos = { 12, -14 },
            scale = { 1.56, 1.56 },
            color = Gui.AMBER,
        },
        {
            key = 'StripesBottom',
            type = 'uiTexture',
            textureName = 'ui_dialog_docking_stripesBottom',
            sSpritesheetPath = 'UI/DialogBox',
            pos = { 10, -788 },
            scale = { 1.56, 1.56 },
            color = Gui.AMBER,
        },
        -- Docking Button
        {
            key = 'AcceptButton',
            type = 'onePixelButton',
            pos = { 36, -622 },
            scale = { 960, 134 },
            layerOverride = 'UIForeground',
            color = Gui.BROWN,
            onPressed =
            {
                {
                    key = 'AcceptButton',
                    color = BRIGHT_AMBER,
                },            
            },
            onReleased =
            {
                {
                    key = 'AcceptButton',
                    color = AMBER,
                },       
            },
            onHoverOn =
            {
                {
                    key = 'AcceptButton',
                    color = AMBER,
                },
                {
                    key = 'AcceptLabel',
                    color = { 0, 0, 0 },
                },
                {
                    key = 'DockingIcon',
                    color = { 0, 0, 0 },
                },                
                {
                    key = 'AcceptHotkey',
                    color = { 0, 0, 0 },
                },
                
                {
                    playSfx = 'hilight',
                },
            },
            onHoverOff =
            {
                {
                    key = 'AcceptButton',
                    color = Gui.BROWN,
                },
                {
                    key = 'AcceptLabel',
                    color = Gui.AMBER,
                },
                {
                    key = 'DockingIcon',
                    color = Gui.AMBER,
                },  
                {
                    key = 'AcceptHotkey',
                    color = Gui.AMBER,
                },
            },
        },
        {
            key = 'AcceptLabel',
            type = 'textBox',
            pos = { 164, -613 },
            linecode = 'HUDHUD021TEXT',
            style = 'dosismedium44',
            rect = { 0, 200, 1000, 0 },
            scale = { 0.76, 0.76 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.CENTER_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'DockingIcon',
            type = 'uiTexture',
            textureName = 'ui_iconIso_dock',
            sSpritesheetPath = 'UI/Shared',
            pos = { 54, -638 },
            scale = { 0.8, 0.8 },
            color = Gui.AMBER,
        },
        {
            key = 'AcceptHotkey',
            type = 'textBox',
            pos = { 965, -708 },
            text = 'C',
            style = 'dosissemibold30',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        -- Texts
        {
            key = 'Title',
            type = 'textBox',
            pos = { 220, -88 },
            linecode = "DOCKUI001TEXT",
            style = 'dosismedium32',
            rect = { 0, 100, 500, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = { 0, 0, 0 },
        },       
        {
            key = 'DockerName',
            type = 'textBox',
            pos = { 220, -128 },
            linecode = "DOCKUI002TEXT",
            style = 'dosismedium44',
            rect = { 0, 100, 800, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = { 0, 0, 0 },
        },        
        {
            key = 'DockMessage',
            type = 'textBox',
            pos = { 220, -240 },
            linecode = "DOCKUI003TEXT",
            style = 'dosismedium32',
            rect = { 0, 400, 760, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },      
        {
            key = 'DockSideSystemMessage',
            type = 'textBox',
            pos = { 40, -250 },
            linecode = "DOCKUI004TEXT",
            style = 'smallSystemFont',
            rect = { 0, 400, 760, 0 },
            scale = { 0.9, 0.9 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = { Gui.AMBER[1], Gui.AMBER[2], Gui.AMBER[3], 0.6 },
        },       
    },
}
