local Gui = require('UI.Gui')

return 
{
--[[
    posInfo =
    {
        alignX = 'left',
        alignY = 'top',
        offsetX = 0,
        offsetY = 0,
    },
    ]]--
    tElements =
    {       
        {
            key = 'UpButton',
            type = 'textureButton',
            normalTexture = 'ui_scrollbar_arrow',
            sSpritesheetPath = 'UI/Shared',
            pos = { -12, 0 },
            scale = {2, 2},
            normalColor = Gui.AMBER,
        },
        {
            key = 'DownButton',
            type = 'textureButton',
            normalTexture = 'ui_scrollbar_arrow',
            sSpritesheetPath = 'UI/Shared',
            pos = { -12, -24 },
            scale = {2, -2},
            normalColor = Gui.AMBER,
        },
        {
            key = 'ScrollbarButton',
            type = 'textureButton',
            normalTexture = 'ui_scrollbar_grabber',
            sSpritesheetPath = 'UI/Shared',
            pos = { -12, -292 },
            scale = {2, -2},
            normalColor = Gui.AMBER,
            bothMouseEvents=true,
        },
    }
}
