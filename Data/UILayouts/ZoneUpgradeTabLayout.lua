local Gui = require('UI.Gui')

local AMBER = { Gui.AMBER[1], Gui.AMBER[2], Gui.AMBER[3], 0.95 }
local BRIGHT_AMBER = { Gui.AMBER[1], Gui.AMBER[2], Gui.AMBER[3], 1 }
local SELECTION_AMBER = { Gui.AMBER[1], Gui.AMBER[2], Gui.AMBER[3], 0.01 }

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
        tCallbacks =
        {
            onSelected =
            {
                {
                    key = 'FolderTopActive',
                    hidden = false,
                },
                {
                    key = 'FolderTopInactive',
                    hidden = true,
                }, 
                {
                    key = 'ActiveTabBG',
                    hidden = false,
                }, 
                {
                    key = 'Label',
                    color = { 0, 0, 0 },
                },         
            },
            onDeselected =
            {
                {
                    key = 'FolderTopActive',
                    hidden = true,
                },
                {
                    key = 'FolderTopInactive',
                    hidden = false,
                },
                {
                    key = 'ActiveTabBG',
                    hidden = true,
                }, 
                {
                    key = 'Label',
                    color = Gui.AMBER,
                },
            },
        },
    },    
    tElements =
    {       
        {
            key = 'FolderTopActive',
            type = 'uiTexture',
            textureName = 'ui_inspector_folderActive',
            sSpritesheetPath = 'UI/Inspector',
            pos = { 0, 0 },
            scale = { 1.56, 1.56 },
            color = Gui.AMBER,
        },
        {
            key = 'FolderTopInactive',
            type = 'uiTexture',
            textureName = 'ui_inspector_folderInactive',
            sSpritesheetPath = 'UI/Inspector',
            pos = { 0, 0 },
            scale = { 1.56, 1.56 },
            color = Gui.AMBER,
        },
        {
            key = 'TabButton',
            type = 'onePixelButton',
            pos = { 30, -12 },
            scale = { 200, 50 },
            color = { 1, 0, 0 },
            hidden = true,
        },
        {
            key = 'ActiveTabBG',
            type = 'onePixel',
            pos = { 0, -65 },
            scale = { 652, 40 },
            color = Gui.AMBER,
        },
        -- Label
        {
            key = 'Label',
            type = 'textBox',
            pos = { 38, 0 },
            linecode = "INSPEC028TEXT",
            style = 'dosissemibold48',
            rect = { 0, 300, 500, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        -- hint text
        {
            key = 'HintText',
            type = 'textBox',
            pos = { 270, -20 },
            linecode = "INSPEC029TEXT",
            style = 'dosissemibold30',
            rect = { 0, 300, 500, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = { 0, 0, 0 },
            color = Gui.AMBER,
        },
        -- scrollpane
        {
            key='ScrollPane',
            type='scrollPane',
            tNestedInfo=
            {
                posInfo =
                {
                    alignX = 'left',
                    alignY = 'top',
                    offsetX = 0,
                    offsetY = -90,            
                },
                tElements={
                    -- Autopopulate Button
                    {
                        key = 'AutopopulateButton',
                        type = 'onePixelButton',
                        pos = { 16, -22 },
                        scale = { 468, 134 },
                        color = Gui.BROWN,
                        onPressed =
                        {
                            {
                                key = 'AutopopulateButton',
                                color = BRIGHT_AMBER,
                            },            
                        },
                        onReleased =
                        {
                            {
                                key = 'AutopopulateButton',
                                color = AMBER,
                            },       
                        },
                        onHoverOn =
                        {
                            {
                                key = 'AutopopulateButton',
                                color = AMBER,
                            },
                            {
                                key = 'AutopopulateLabel',
                                color = { 0, 0, 0 },
                            },
                            {
                                key = 'AutopopulateIcon',
                                color = { 0, 0, 0 },
                            },                
                            {
                                key = 'AutopopulateHotkey',
                                color = { 0, 0, 0 },
                            },
                        },
                        onHoverOff =
                        {
                            {
                                key = 'AutopopulateButton',
                                color = Gui.BROWN,
                            },
                            {
                                key = 'AutopopulateLabel',
                                color = Gui.AMBER,
                            },
                            {
                                key = 'AutopopulateIcon',
                                color = Gui.AMBER,
                            },  
                            {
                                key = 'AutopopulateHotkey',
                                color = Gui.AMBER,
                            },
                        },
                    },
                    {
                        key = 'AutopopulateLabel',
                        type = 'textBox',
                        pos = { 124, -50 },
                        linecode = 'ZONEUI057TEXT',
                        style = 'dosisregular70',
                        rect = { 0, 300, 400, 0 },
                        scale = { 0.76, 0.76 },
                        hAlign = MOAITextBox.LEFT_JUSTIFY,
                        vAlign = MOAITextBox.LEFT_JUSTIFY,
                        color = Gui.AMBER,
                    },
                    {
                        key = 'AutopopulateIcon',
                        type = 'uiTexture',
                        textureName = 'ui_iconIso_dock',
                        sSpritesheetPath = 'UI/Shared',
                        pos = { 14, -38 },
                        scale = { 0.8, 0.8 },
                        color = Gui.AMBER,
                    },
                    {
                        key = 'AutopopulateHotkey',
                        type = 'textBox',
                        pos = { 422, -108 },
                        text = 'A',
                        style = 'dosissemibold30',
                        rect = { 0, 100, 100, 0 },
                        hAlign = MOAITextBox.LEFT_JUSTIFY,
                        vAlign = MOAITextBox.LEFT_JUSTIFY,
                        color = Gui.AMBER,
                    },
                },
            },
        },
    },
}
