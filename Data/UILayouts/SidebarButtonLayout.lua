local Gui = require('UI.Gui')

local nIconX, nIconStartY = 10, -12
local nLabelX, nLabelStartY = 94, -10
local nButtonWidth, nButtonHeight  = 330, 81

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
    },
    tElements =
    {
        {
            key = 'SidebarButton',
            type = 'onePixelButton',
            pos = { 0, 0 },
            scale = { nButtonWidth, nButtonHeight },
            color = Gui.BLACK,
            onHoverOn =
            {
                {
                    key = 'SidebarButton',
                    color = Gui.AMBER,
                },
                {
                    key = 'SidebarLabel',
                    color = { 0, 0, 0 },
                },
                {
                    key = 'SidebarIcon',
                    color = { 0, 0, 0 },
                },                
                {
                    key = 'SidebarHotkey',
                    color = { 0, 0, 0 },
                },
                {
                    playSfx = 'hilight',
                },
            },
            onHoverOff =
            {
                {
                    key = 'SidebarButton',
                    color = Gui.BLACK,
                },
                {
                    key = 'SidebarLabel',
                    color = Gui.AMBER,
                },
                {
                    key = 'SidebarIcon',
                    color = Gui.AMBER,
                },  
                {
                    key = 'SidebarHotkey',
                    color = Gui.AMBER,
                },
            },
        },
        {
            key = 'SidebarIcon',
            type = 'uiTexture',
            textureName = 'ui_iconIso_erase',
            sSpritesheetPath = 'UI/Shared',
            pos = { nIconX, nIconStartY },
            color = Gui.AMBER,
        },
        {
            key = 'SidebarLabel',
            type = 'textBox',
            pos = { nLabelX, nLabelStartY },
            linecode = 'HUDHUD037TEXT',
            style = 'dosisregular40',
            rect = { 0, 300, 280, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
   },
}
