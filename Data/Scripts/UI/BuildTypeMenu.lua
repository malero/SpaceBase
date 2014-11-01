local Gui = require('UI.Gui')
local DFUtil = require("DFCommon.Util")
local DFInput = require('DFCommon.Input')
local UIElement = require('UI.UIElement')
local Renderer = require('Renderer')
local GameRules = require('GameRules')
local SoundManager = require('SoundManager')
local CommandObject = require('Utility.CommandObject')

local m = {}

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())

    local TYPEDEFS_SORT =
    {
        "area",
        "wall",
        "door",
        "airlockdoor",
        "demolish",
        "vaporize",
        "mine",
        "cancel",
    }

    local TYPEDEFS=
    {
        area={
            title = g_LM.line("BUILDM005TEXT"),
            desc= g_LM.line("BUILDM006TEXT"),
            inputMode = GameRules.MODE_BUILD_ROOM,
            sound = "area",
        },
        wall={
            title = g_LM.line("BUILDM001TEXT"),
            desc = g_LM.line("BUILDM002TEXT"),
            inputMode = GameRules.MODE_BUILD_WALL,
            sound = "wall",
        },
        door={
            title = g_LM.line("BUILDM003TEXT"),
            desc = g_LM.line("BUILDM004TEXT"),
            inputMode = GameRules.MODE_BUILD_DOOR,
            modeParam = 'Door',
            sound = "door",
        },
        airlockdoor={
            title = g_LM.line("BUILDM010TEXT"),
            desc = g_LM.line("BUILDM011TEXT"),
            inputMode = GameRules.MODE_BUILD_DOOR,
            modeParam = 'Airlock',
            sound = "airlock",
        },
        vaporize={
            title = g_LM.line("BUILDM021TEXT"),
            desc = g_LM.line("BUILDM022TEXT"),
            inputMode = GameRules.MODE_VAPORIZE,
            sound = "vaporize",
        },
        demolish={
            title = g_LM.line("BUILDM018TEXT"),
            desc = g_LM.line("BUILDM008TEXT"),
            inputMode = GameRules.MODE_DEMOLISH,
            sound = "vaporize",
        },
        mine={
            title = g_LM.line("BUILDM012TEXT"),
            desc = g_LM.line("BUILDM013TEXT"),
            inputMode = GameRules.MODE_MINE,
            sound = "vaporize",
        },
        cancel={
            title = g_LM.line("BUILDM014TEXT"),
            desc = g_LM.line("BUILDM015TEXT"),
            inputMode = GameRules.MODE_CANCEL_COMMAND,
            sound = "vaporize",
        },
    }

    function Ob:init(w)
        Ob.Parent.init(self)

        self.width = w
        self.uiBG = self:addOnePixel()
        self.uiBG:setColor(unpack({226/255,136/255,16/255}))

        self.buttons = {}
        self.rectLookup = {}
        local i=0
        local margin=10
        local rectHeight = 130
        local rectMargin = 5
        local rectThickness = 4
        local curY = -20
        -- Choose build tool header
        local tb = self:addTextBox(g_LM.line("BUILDM007TEXT"), "nevisSmallTitle",0,0,w,30,margin,curY-30)
        curY = curY-30

        for k,v in ipairs(TYPEDEFS_SORT) do
            k = v
            v = TYPEDEFS[k]

            self.buttons[k] = {}
            local btn = self.buttons[k]
            btn.outerRect = self:addOnePixel()
            btn.outerRect:setScl(w-margin*2, rectHeight)
            btn.outerRect:setLoc(margin, curY)
            btn.outerRect:setColor(255/255,202/255,132/255)
            btn.innerRect = self:addOnePixel()
            btn.innerRect:setScl(w-margin*2-rectThickness*2, rectHeight-rectThickness*2)
            btn.innerRect:setLoc(margin+rectThickness, curY-rectThickness)
            btn.innerRect:setColor(226/255,136/255,16/255)
            btn.title = self:addTextBox(v.title, "gothicTitle",0,0,w*.5-margin*4,rectHeight,margin*2,curY-rectHeight-10, nil, MOAITextBox.LEFT_JUSTIFY)
            btn.desc  = self:addTextBox(v.desc, "nevisBody",  0,0,w*.5-margin*4,rectHeight,w*.5,curY-rectHeight-10)
            self.rectLookup[ btn.outerRect ] = k
            self.rectLookup[ btn.innerRect ] = k
            self.rectLookup[ btn.title ] = k
            self.rectLookup[ btn.desc ] = k
            i=i+1
            curY = curY - rectHeight - margin*2
        end
		
		-- back button
		self.buttons['back'] = {}
		local back = self.buttons['back']
		local x = margin
		back.rect = self:addOnePixel()
		back.rect:setScl(w/2, rectHeight)
		back.rect:setLoc(x, curY)
		back.rect:setColor(1, 0.25, 0.25)
		back.title = self:addTextBox('back', "gothicTitle",0,0,w*.5-margin*4,rectHeight,x,curY-rectHeight-10, nil, MOAITextBox.LEFT_JUSTIFY)
		self.rectLookup[ back.rect ] = 'back'
		self.rectLookup[ back.title ] = 'back'
		self.backButton = back
		-- confirm button
		self.buttons['confirm'] = {}
		local confirm = self.buttons['confirm']
		confirm.rect = self:addOnePixel()
		confirm.rect:setScl(w/2, rectHeight)
		x = x + w/2
		confirm.rect:setLoc(x, curY)
		confirm.rect:setColor(0.25, 1, 0.25)
		confirm.title = self:addTextBox('confirm', "gothicTitle",0,0,w*.5-margin*4,rectHeight,x,curY-rectHeight-10, nil, MOAITextBox.LEFT_JUSTIFY)
		-- matter cost display
		confirm.cost = self:addTextBox('XXXX matter', "nevisBody",0,0,w*.5-margin*4,rectHeight,x+10,curY-rectHeight-60)
		self.costDisplay = confirm.cost
		self.rectLookup[ confirm.rect ] = 'confirm'
		self.rectLookup[ confirm.title ] = 'confirm'
		self.confirmButton = confirm
		curY = curY - rectHeight - margin
		
        self.height = -curY
        self.uiBG:setScl(self.width,self.height)
    end

    function Ob:show(basePri)
        local w,h = self.uiBG:getScl()
        local x,y = 0,64
        
        g_GuiManager.createEffectMaskBox(x,y,w,h,0.4) -- rect for wiggle and time
        
        return Ob.Parent.show(self,basePri)
    end
    
    function Ob:inside(wx,wy)
        return self.uiBG:inside(wx,wy)
    end

    function Ob:selectBuildType(bt)
        if self.currentBT ~= bt then
            if self.currentBT then
                self.buttons[self.currentBT].innerRect:setVisible(true)
            end
            self.currentBT = bt
            self.buttons[self.currentBT].innerRect:setVisible(false)

            local mode = TYPEDEFS[bt].inputMode or GameRules.MODE_INSPECT
            local param = TYPEDEFS[bt].modeParam or GameRules.currentModeParam            
            SoundManager.playSfx(TYPEDEFS[bt].sound)
            GameRules.setUIMode(mode, param)            
        end
    end

    function Ob:onFinger(touch, x, y, props)
        if touch.eventType == DFInput.TOUCH_UP then
            for _,v in ipairs(props) do
                local btnIdx = self.rectLookup[v]
                if btnIdx then
                    if btnIdx == 'back' then
                        GameRules.cancelBuild()
                    elseif btnIdx == 'confirm' then
                        GameRules.confirmBuild()
                    else
                        self:selectBuildType(btnIdx)
                    end
                    return true
                end
            end
        end
    end
    
    function Ob:onResize(x0,y0,x1,y1)
        self:setLoc(x0,y0)
    end

    function Ob:allowsInputMode(mode, param)

        for k,v in pairs(TYPEDEFS) do
            if mode == v.inputMode then
                if not v.modeParam then
                    return k
                elseif param == v.modeParam then
                    return k
                end
            end
        end
    end
	
	function Ob:onTick(dt)
		-- update matter costs of current build sketch
		local text = ''
		if CommandObject.pendingBuildCost ~= 0 then
			text = 'B: ' .. CommandObject.pendingBuildCost .. ' \n'
		end
		if CommandObject.pendingVaporizeCost ~= 0 then
			text = text .. 'V: +' .. CommandObject.pendingVaporizeCost .. ' \n'
		end
		if CommandObject.pendingMineCost ~= 0 then
			text = text .. 'M: +' .. CommandObject.pendingMineCost .. ' \n'
		end
		if CommandObject.pendingCancelCost ~= 0 then
			text = text .. 'C: +' .. CommandObject.pendingCancelCost
		end
		self.costDisplay:setString(text)
	end
	
    function Ob:refresh()
        local k = self:allowsInputMode(GameRules.currentMode, GameRules.currentModeParam)
        if k then self:selectBuildType(k) end
    end

    return Ob
end

function m.new(...)
    local Ob = m.create()
    Ob:init(...)

    return Ob
end

return m
