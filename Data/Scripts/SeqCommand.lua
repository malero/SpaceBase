local Util = require('DFCommon.Util')
local Class = require('Class')
local SeqCommand = Class.create()

local DFSchema = require('DFCommon.DFSchema')
local EntityManager = require('EntityManager')

local AssetAnalysis = nil

-- Editor hooks
SeqCommand.tEditorSchemas = {}
function SeqCommand.addEditorSchema(componentName, rSchema)
    SeqCommand.tEditorSchemas[componentName] = rSchema
end

function SeqCommand.loadEditorCommands()
    SeqCommand.registerCommands()
end

-- Register all sequence command types
local tSeqCommandTypes = {}

function SeqCommand._registerComponent(sType)
    -- Extract the name from the given sequence command type (which fully qualified type name)
    local idxTypeName = 1
    local typeNameLength = #sType
    for i=1,typeNameLength do
        local idx = typeNameLength - i + 1
        if sType:sub(idx, idx) == '.' then
            idxTypeName = idx + 1
            break
        end
    end
    local sTypeName = sType:sub(idxTypeName)
    -- Bind the type to its name
    assert(tSeqCommandTypes[sTypeName] == nil)
    tSeqCommandTypes[sTypeName] = require(sType)
end

function SeqCommand.registerCommands()
    -- Sequence commands
    --[[
    SeqCommand._registerComponent('SeqCommands.ScActorCreateEffect')
    SeqCommand._registerComponent('SeqCommands.ScActorCreateParticleSystem')
    SeqCommand._registerComponent('SeqCommands.ScCameraFollowPath')
    SeqCommand._registerComponent('SeqCommands.ScCreateEffect')
    SeqCommand._registerComponent('SeqCommands.ScCreateEntity')
    SeqCommand._registerComponent('SeqCommands.ScCreateParticleSystem')
    SeqCommand._registerComponent('SeqCommands.ScDelay')
    SeqCommand._registerComponent('SeqCommands.ScDialogTree')
    SeqCommand._registerComponent('SeqCommands.ScFade')
    SeqCommand._registerComponent('SeqCommands.ScEndCutscene')
    SeqCommand._registerComponent('SeqCommands.ScExplanation')
    SeqCommand._registerComponent('SeqCommands.ScFlipRig')
    SeqCommand._registerComponent('SeqCommands.ScInventoryAdd')
    SeqCommand._registerComponent('SeqCommands.ScInventoryRemove')
    SeqCommand._registerComponent('SeqCommands.ScLockControls')
    SeqCommand._registerComponent('SeqCommands.ScSetMeshPartVisibility')
    SeqCommand._registerComponent('SeqCommands.ScMovePosition')    
    SeqCommand._registerComponent('SeqCommands.ScPlayAnimation')
    SeqCommand._registerComponent('SeqCommands.ScPlayCutscene')
    SeqCommand._registerComponent('SeqCommands.ScPlayLine')
    SeqCommand._registerComponent('SeqCommands.ScPlayDialogSet')
    SeqCommand._registerComponent('SeqCommands.ScPlayMusic')
    SeqCommand._registerComponent('SeqCommands.ScPlaySound')
    SeqCommand._registerComponent('SeqCommands.ScPopEnvState')
    SeqCommand._registerComponent('SeqCommands.ScPushEnvState')
    SeqCommand._registerComponent('SeqCommands.ScSetEnvState')
    SeqCommand._registerComponent('SeqCommands.ScSetLightGroupIntensity')
    SeqCommand._registerComponent('SeqCommands.ScSetLogicBool')
    SeqCommand._registerComponent('SeqCommands.ScSetLogicNumber')
    SeqCommand._registerComponent('SeqCommands.ScSetLogicString')
    SeqCommand._registerComponent('SeqCommands.ScSetSceneLayer')
    SeqCommand._registerComponent('SeqCommands.ScSetShadowVisibility')
    SeqCommand._registerComponent('SeqCommands.ScSetTextureStateIntensity')
    SeqCommand._registerComponent('SeqCommands.ScSetVisible')
    SeqCommand._registerComponent('SeqCommands.ScStartShot')    
    SeqCommand._registerComponent('SeqCommands.ScSwitchCamera')
    ]]--
    -- Animation events
    SeqCommand._registerComponent('AnimEvents.AeAnimation')
    SeqCommand._registerComponent('AnimEvents.AeCreateParticleSystem')
    SeqCommand._registerComponent('AnimEvents.AeCreateSpriteAnim')
    SeqCommand._registerComponent('AnimEvents.AePlaySound')
    SeqCommand._registerComponent('AnimEvents.AeFireProjectile')
    SeqCommand._registerComponent('AnimEvents.AeCharacterSpeak')
    -- Animation events
    SeqCommand._registerComponent('EffectEvents.EeAddMaterialModifier')
    SeqCommand._registerComponent('EffectEvents.EeCreateParticleSystem')
    SeqCommand._registerComponent('EffectEvents.EePlaySound')
    SeqCommand._registerComponent('EffectEvents.EeStopParticleSystem')
    SeqCommand._registerComponent('EffectEvents.EeRemoveMaterialModifier')
end

function SeqCommand.createCommand(sCommandType, tAttributeOverrides, rSequence)

    local rCommand = nil

    local rCmdType = tSeqCommandTypes[sCommandType]
    if rCmdType ~= nil then
       rCommand = rCmdType.new(sCommandType, rSequence) 
    end
    
    if rCommand ~= nil and tAttributeOverrides ~= nil then
        for key, value in pairs(tAttributeOverrides) do
            rCommand[key] = value
        end
    end
    
    return rCommand
end

-- META ATTRIBUTES --
SeqCommand.rMetaSchema = DFSchema.object(
	{
		MetaValue_Priority = DFSchema.number(0, "Execution priority relative to commands starting at the same time"),
	},
	"Meta information for this command"
)

-- ATTRIBUTES --
SeqCommand.Blocking = false

SeqCommand.rSchema = DFSchema.object(
    {
		MetaSchema = DFSchema.metaData(SeqCommand.rMetaSchema),
		Blocking = DFSchema.bool(false, "Will the command wait for completion?"),
    },
    "Abstract base class for all sequence commands."
)
SeqCommand.addEditorSchema('SeqCommand', SeqCommand.rSchema)

-- META MODIFICATION --
function SeqCommand.metaType(tSchemaFields, value)

	SeqCommand.metaString(tSchemaFields, "Type", value)
end

function SeqCommand.metaPriority(tSchemaFields, value)

	SeqCommand.metaNumber(tSchemaFields, "Priority", value)
end

function SeqCommand.metaNumber(tSchemaFields, sName, defaultValue, description)

	SeqCommand.metaValue(tSchemaFields, sName, defaultValue, description, "number")	
end

function SeqCommand.metaString(tSchemaFields, sName, defaultValue, description)

	SeqCommand.metaValue(tSchemaFields, sName, defaultValue, description, "string")	
end

function SeqCommand.metaValue(tSchemaFields, sName, defaultValue, description, type)

	local rMetaSchema = tSchemaFields["MetaSchema"]
	
	if rMetaSchema ~= nil then
	
		local sAttrName = "MetaValue_" .. sName
	
		local tMetaAttrs = rMetaSchema.tFieldSchemas[1].tFieldSchemas
		local rMetaAttr = tMetaAttrs[sAttrName]
		if rMetaAttr == nil then
            if type == "number" then
                rMetaAttr = DFSchema.number(defaultValue, description)
            elseif type == "string" then
                rMetaAttr = DFSchema.string(defaultValue, description)
            end
			tMetaAttrs[sAttrName] = rMetaAttr
		else
			rMetaAttr.default = defaultValue
		end
		
	else
		Trace("No meta schema defined")
	end
	
end

function SeqCommand.metaFlag(tSchemaFields, sName)

	local rMetaSchema = tSchemaFields["MetaSchema"]
	
	if rMetaSchema ~= nil then
	
		local sAttrName = "MetaFlag_" .. sName
		
		local tMetaAttrs = rMetaSchema.tFieldSchemas[1].tFieldSchemas
		local rMetaAttr = tMetaAttrs[sAttrName]
		if rMetaAttr == nil then
			rMetaAttr = DFSchema.string(sName, "")
			tMetaAttrs[sAttrName] = rMetaAttr
		end
		
	else
		Trace("No meta schema defined")
	end
end

-- TYPE MODIFICATION --
function SeqCommand.nonBlocking(tSchemaFields)

	tSchemaFields["Blocking"] = nil
end

function SeqCommand.implicitlyBlocking(tSchemaFields)

	SeqCommand.nonBlocking(tSchemaFields)
	SeqCommand.metaFlag(tSchemaFields, "ImplicitBlock")
end

function SeqCommand.levelOfDetail(tSchemaFields)

	tSchemaFields["LodGroup"] = DFSchema.enum('default', { 'default', 'ambient_low', 'ambient_medium', 'ambient_high', 'gameplay_low', 'gameplay_medium', 'gameplay_high' }, "Level-of-detail group")
    tSchemaFields["LodType"] = DFSchema.enum('explicit', { 'explicit', 'include_lower', 'include_higher' }, "Level-of-detail selector type")
end
    
-- ANIM EVENT SCHEMA --
SeqCommand.rAnimEventSchema = Util.deepCopy(SeqCommand.rSchema.tFieldSchemas)
SeqCommand.metaType(SeqCommand.rAnimEventSchema, "AnimEvent")
SeqCommand.implicitlyBlocking(SeqCommand.rAnimEventSchema)

-- CONSTRUCTOR --
function SeqCommand:init(sCommandType, rSequence)

	self.sType = sCommandType
    self.rSequence = rSequence
    
    if self:_getDebugFlags().DebugLoading then
        Trace(TT_Gameplay, "Creating sequence command: " .. sCommandType)
    end
    
    self:created()
    
	return self
end

-- ABSTRACT FUNCTIONS --
function SeqCommand:onCreated()
end

function SeqCommand:onAnalyzeAssets(rClump, sParentReference)
    if not AssetAnalysis then
        AssetAnalysis = require('AssetAnalysis')
    end
    AssetAnalysis.handleSequenceCommand(self, rClump)
end

function SeqCommand:onPreloadCutscene(rAssetSet)
end

function SeqCommand:onExecute()
end

function SeqCommand:onPause()
end

function SeqCommand:onResume()
end

function SeqCommand:onCleanup()
end

function SeqCommand:onUpdateActorName(sOriginalActorName, sActorName)

    if self.ActorName ~= nil and self.ActorName == sOriginalActorName then
        self.ActorName = sActorName
    end
end

-- PUBLIC BASECLASS FUNCTIONS (to prevent the subclasses from having to call the Parent's in the normal case)
function SeqCommand:created()
    self:onCreated()
end

function SeqCommand:analyzeAssets(rClump, sParentReference)
    self:onAnalyzeAssets(rClump, sParentReference)
end

function SeqCommand:preloadCutscene(rAssetSet)
    self.bSkip = false
    self:onPreloadCutscene(rAssetSet)
end

function SeqCommand:execute()
    self:onExecute()
end

function SeqCommand:pause()
    self.bPaused = true
    self:onPause()
end

function SeqCommand:resume()
    self.bPaused = false
    self:onResume()
end

function SeqCommand:skip()
    self.bSkip = true
end

function SeqCommand:cleanup(bSkipped)    
    self:onCleanup(bSkipped)
end

function SeqCommand:updateActorName(sOriginalActorName, sActorName)    
    self:onUpdateActorName(sOriginalActorName, sActorName)    
end

-- PUBLIC FUNCTIONS --
function SeqCommand:getSibling(sCommandType)

    local tCommands = self.rSequence.tCommands
    if tCommands ~= nil then
        local numCommands = #tCommands
        for i=1,numCommands do
            local rCommand = tCommands[i]
            if rCommand.sType == sCommandType then
                return rCommand
            end
        end
    end
    
    return nil
end

-- DEBUG --
local tDebugFlags = {
	DebugLoading = false,
	DebugExecution = false,
}

function SeqCommand:_getDebugFlags()
    return tDebugFlags
end

return SeqCommand
