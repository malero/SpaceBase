local Gui = require('UI.Gui')

local buttonX, buttonY = 0, -205

-- button draws above label in other element, give it low alpha
local DIM_AMBER = Gui.AMBER_DIM
DIM_AMBER[4] = 0.25

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
            key = 'OccupantButton',
            type = 'onePixelButton',
            pos = { buttonX,buttonY },
            scale = { 418, 35 },
            color = Gui.BLACK_NO_ALPHA,
            hidden = false,
            onHoverOn =
            {
				{ key = 'OccupantButton', color = DIM_AMBER, },
			},
            onHoverOff =
            {
				{ key = 'OccupantButton', color = Gui.BLACK_NO_ALPHA, },
			},
			onDisabledOn =
            {
				{ key = 'OccupantButton', color = Gui.BLACK_NO_ALPHA, },
			},
			onDisabledOff =
            {
				{ key = 'OccupantButton', color = DIM_AMBER, },
			},
		},
	},
}
