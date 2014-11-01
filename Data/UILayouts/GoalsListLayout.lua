local Gui = require('UI.Gui')

local nButtonWidth, nButtonHeight  = 286, 98
local nHotkeyX, nHotkeyStartY = nButtonWidth - 110, -68

local nScrollAreaTopMargin = 160

local nSortButton1X = 1106
local nSortButton2X = nSortButton1X + 190
local nSortButtonY = -80

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
    tElements =
    {
        {
            key = 'LargeBar',
            type = 'onePixel',
            pos = { 0, 0 },
            scale = { 'g_GuiManager.getUIViewportSizeX()', 'g_GuiManager.getUIViewportSizeY()' },
            color = Gui.SIDEBAR_BG,
        },
        {
            key = 'GoalScrollPane',
            type = 'scrollPane',
            pos = { 550, -nScrollAreaTopMargin },
            rect = { 0, 0, 970, '(g_GuiManager.getUIViewportSizeY() - 192)' },
            scissorLayerName='UIScrollLayerRight',
        },
        {
            key = 'BackButton',
            type = 'onePixelButton',
            pos = { 0, 0 },
            scale = { nButtonWidth, nButtonHeight },
            color = Gui.AMBER,
            hidden = true,
            onPressed =
            {
                { key = 'BackButton', color = Gui.AMBER, },
            },
            onReleased =
            {
                { key = 'BackButton', color = Gui.AMBER, },
            },
            onHoverOn =
            {
                { key = 'BackButton', hidden = false, },
                { key = 'BackLabel', color = Gui.BLACK },
                { key = 'BackHotkey', color = Gui.BLACK },
                { playSfx = 'hilight', },
            },
            onHoverOff =
            {
                { key = 'BackButton', hidden = true, },
                { key = 'BackLabel', color = Gui.AMBER, },
                { key = 'BackHotkey', color = Gui.AMBER, },
            },
        },
		-- back button / research heading
        {
            key = 'BackLabel',
            type = 'textBox',
            pos = { 96, -20 },
            linecode = 'HUDHUD035TEXT',
            style = 'dosisregular40',
            rect = { 0, 300, 200, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'BackHotkey',
            type = 'textBox',
            pos = { nHotkeyX, -60 },
            text = 'ESC',
            style = 'dosissemibold22',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'GoalLabel',
            type = 'textBox',
            pos = { 380, -20 },
            linecode = 'HUDHUD052TEXT',
            style = 'dosismedium44',
            rect = { 0, 300, 400, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'SortLabel',
            type = 'textBox',
            pos = { nSortButton1X - 75, nSortButtonY + 6 },
            linecode = 'GOALSS014TEXT',
            style = 'dosismedium32',
            rect = { 0, 300, 400, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
		{
			key = 'SortCompletedButton',
            type = 'templateButton',
            layoutFile = 'UILayouts/ActionButtonLayout',
            replacements = {
                ActionLabel={linecode='GOALSS012TEXT',
							 -- nuuudge
							 pos={0+0-10,0-5}
				},
				ActionButtonTexture={textureName='buttontoggle2_left'},
				ActionButtonTexturePressed={textureName='buttontoggle2_left_pressed'},
            },
            buttonName='ActionButton',
            pos = { nSortButton1X, nSortButtonY },
		},
		{
			key = 'SortUncompletedButton',
            type = 'templateButton',
            layoutFile = 'UILayouts/ActionButtonLayout',
            replacements = {
                ActionLabel={linecode='GOALSS013TEXT'},
				ActionButtonTexture={textureName='buttontoggle2_right'},
				ActionButtonTexturePressed={textureName='buttontoggle2_right_pressed'},
            },
            buttonName='ActionButton',
            pos = { nSortButton2X, nSortButtonY },
		},
    },
}
