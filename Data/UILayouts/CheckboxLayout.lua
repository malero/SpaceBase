local Gui = require('UI.Gui')

return 
{
    posInfo =
    {
        alignX = 'left',
        alignY = 'top',
        offsetX = 0,
        offsetY = 0,
    },
    tElements =
    {       
        {
            key = 'Background',
            type = 'uiTexture',
            textureName = 'ui_iconIso_confirm_circle',
            sSpritesheetPath = 'UI/Shared',
            pos = { 0, 0 },
            color = Gui.WHITE,
            scale = { 0.5, 0.5 },
            hidden = false,
        },
        {
            key = 'Check',
            type = 'uiTexture',
            textureName = 'ui_iconIso_confirm',
            sSpritesheetPath = 'UI/Shared',
            pos = { 0, 0 },
            scale = { 0.5, 0.5 },
            color = Gui.AMBER,
            hidden = false,
        },
        {
            key = 'ButtonToggle',
            type = 'onePixelButton',
            pos = { 0, 0 },
            scale = { 64, 64 },
            color = Gui.WHITE,
            hidden = true,
            clickWhileHidden=true,
        }
    }
}
