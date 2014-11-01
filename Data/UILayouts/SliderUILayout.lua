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
            type = 'onePixel',
            pos = { 0, 0 },
            scale = { 400, 40 },
            color = Gui.WHITE,
        },
        {
            key = 'Foreground',
            type = 'onePixel',
            pos = { 0, 0 },
            scale = { 400, 40 },
            color = Gui.AMBER,
        },
        {
            key = 'Thumb',
            type = 'onePixel',
            pos = { 0, 0 },
            scale = { 10, 40 },
            color = Gui.BLACK,
        },
    }
}
