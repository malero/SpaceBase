local m = {}

local DFUtil = require("DFCommon.Util")
local UIElement = require('UI.UIElement')
local DFInput = require('DFCommon.Input')
local TemplateButton = require('UI.TemplateButton')
local Base = require('Base')

-- used for each TemplateButton, not this element
local sUILayoutFileName = 'UILayouts/GoalEntryLayout'

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())
	
    function Ob:init()
        self:setRenderLayer('UIScrollLayerRight')
        Ob.Parent.init(self,self:getRenderLayerName())
		self.rButton = TemplateButton.new()
        self.rButton:setRenderLayer(self:getRenderLayerName())
        self.rButton:setLayoutFile(sUILayoutFileName)
		self.rButton:setButtonName('Button')
        self:addElement(self.rButton)
		self.nProgressBarWidth = self.rButton:getExtraTemplateInfo('nProgressBarWidth')
		self.nProgressBarHeight = self.rButton:getExtraTemplateInfo('nProgressBarHeight')
        self.rName = self.rButton:getTemplateElement('GoalName')
        self.rDesc = self.rButton:getTemplateElement('GoalDescription')
        self.rIcon = self.rButton:getTemplateElement('GoalIcon')
        self.rProgressBar = self.rButton:getTemplateElement('ProgressBar')
        self.rProgressLabel = self.rButton:getTemplateElement('ProgressLabel')
        self:_calcDimsFromElements()
		self.tGoal = nil
    end
	
    function Ob:setGoal(tGoal)
		if not tGoal then
			return
		end
		self.tGoal = tGoal
		self.rName:setString(g_LM.line(tGoal.sName))
		local sDesc = g_LM.line(tGoal.sDesc)
		-- search-replace /TARGET/ for target # to avoid discrepancies
		sDesc = sDesc:gsub('/TARGET/', tGoal.nTarget)
		self.rDesc:setString(sDesc)
		-- use project's icon if given, (?) if not, checkmark for completed ones
		local sSpriteSheetName = 'UI/JobRoster'
		local rIconSheet = require('DFCommon.Graphics').loadSpriteSheet(sSpriteSheetName)
		-- if goal was completed in a prior session, it will never tick
		-- so check if complete in base data
		local bComplete = tGoal.nProgress >= tGoal.nTarget or Base.tS.tGoals[tGoal.sID]
		if bComplete then
			self.rIcon:setIndex(rIconSheet.names['ui_jobs_icon_checkCircle'])
		else
			self.rIcon:setIndex(rIconSheet.names['ui_jobs_iconHelp'])
		end
		local sProgress
        if bComplete then
            sProgress = g_LM.line('GOALSS009TEXT')
		-- special case: target of 1 for final siege
		elseif tGoal.nTarget == 1 then
			sProgress = ''
        else
            sProgress = string.format('%s / %s', tGoal.nProgress, tGoal.nTarget)
        end
		self.rProgressLabel:setString(sProgress)
		-- set progress bar to correct width
		local w = (tGoal.nProgress / tGoal.nTarget) * self.nProgressBarWidth
		if bComplete then
			w = self.nProgressBarWidth
		end
		self.rProgressBar:setScl(w, self.nProgressBarHeight)
    end
	
	return Ob
end

function m.new(...)
    local Ob = m.create()
    Ob:init(...)

    return Ob
end

return m
