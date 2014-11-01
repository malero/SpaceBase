local DFUtil = require('DFCommon.Util')
local SeqCommand = require('SeqCommand')

local kChar_a = string.byte('a')
local kChar_z = string.byte('z')
local kChar_A = string.byte('A')
local kChar_Z = string.byte('Z')
	
function GetDisplayName( sAttrName, dontStripSc )
	
	-- Strip the first lower-case character (if there is one)
	local firstChar = string.byte(sAttrName)	
	if firstChar >= kChar_a and firstChar <= kChar_z then
		sAttrName = sAttrName:sub(2)
	else
        local prefix = sAttrName:sub(1,2)
		if (prefix == "Sc" or prefix == "Ae" or prefix == "Ee") and dontStripSc ~= true then
        
            -- Sanitize camera commands
            if sAttrName:sub(1,8) == "ScCamera" then
                sAttrName = sAttrName:sub(9)
            else
                sAttrName = sAttrName:sub(3)
            end
		end
	end
	
	-- Add a space between lower- and upper-case characters
	while true do
	
		local bFound = false
		
		local length = #sAttrName
		local lastChar = string.byte(sAttrName)
		for i=2,length do
			local curChar = string.byte(sAttrName, i)
			if lastChar >= kChar_a and lastChar <= kChar_z then
				if curChar >= kChar_A and curChar <= kChar_Z then
					sAttrName = sAttrName:sub(1,i - 1) .. " " .. sAttrName:sub(i)
					
					bFound = true
					break
				end
			end
			lastChar = curChar
		end
		
		if not bFound then
			break
		end
	
	end
	
	sAttrName = sAttrName:gsub("_", " ")

	return sAttrName
end

function HandleResourceType( sResourceExtension )

	if sResourceExtension == ".anim" then
		return "AnimFilename", "RsRef AnimResource"    
    elseif sResourceExtension == ".inv" then
		return "InventoryFilename", "RsRef AnimResource"    
    elseif sResourceExtension == ".ctsn" then
		return "CutsceneFilename", "RsRef AnimResource"
    elseif sResourceExtension == ".dtree" then
		return "DialogTreeFilename", "RsRef AnimResource"  
    elseif sResourceExtension == ".lua" then
		return "LuaFilename", "RsRef AnimResource"
	elseif sResourceExtension == ".cmpth" then
		return "CamPathFilename", "RsRef CameraPath"
	elseif sResourceExtension == ".particles" then
		return "Filename", "RsRef Effect"
	elseif sResourceExtension == ".effect" then
		return "Filename", "RsRef Effect"
	elseif sResourceExtension == ".matmod" then
		return "Filename", "RsRef Effect"
	else
		Trace(TT_Error, "Unknown resource type: " .. sResourceExtension)
	end

end

function ToStringList( tVector )

	local sResult = ""

	local numComponents = #tVector
	for i=1,numComponents do
	
		if #sResult > 0 then
			sResult = sResult .. ", "
		end
		
		sResult = sResult .. tostring(tVector[i])
	
	end
	
	return sResult

end

function IsInternalAttribute( sAttrName, rAttrSchema )

	-- ToDo: Check the schema of the SeqCommand instead of using an explicit string comparison?!
	if sAttrName == "StartTime" then
		return true
	end

	return false

end

function SchemaAttributesToXml( tAttributes, isMetaData )

	local sSchemaAttrs = ""
	local sActorType = "Global"
	local sMetaDataAttrs = ""
    
    local sAttrTag = "attrib"
    if isMetaData == true then
        sAttrTag = "meta_attrib"
    end
	
	for sAttrName,rAttrSchema in pairs(tAttributes) do
		
		if not IsInternalAttribute( sAttrName, rAttrSchema ) then
		
			-- Name
			local sAttributes = "name=\"" .. sAttrName .. "\""
			sAttributes = sAttributes .. " displayName=\"" .. GetDisplayName(sAttrName, true) .. "\""
			
			-- Description
			sAttributes = sAttributes .. " description=\"" .. rAttrSchema.sDescription .. "\""
			
			-- Type and the engine type
			local sType = nil
			local sEngineType = nil
            local tEnumOptions = nil
			
			local defaultValue = ""			
			if rAttrSchema.default ~= nil then
				defaultValue = tostring(rAttrSchema.default)
			end
			
			local sAttrType = rAttrSchema.tTypes[1]
			if sAttrType == "resource" then
			
				sType, sEngineType = HandleResourceType(rAttrSchema.sExtension)
            
            elseif sAttrType == "linecode" then
			
				sType = "String"				
				sEngineType = "LineCode"
                
			elseif sAttrType == "entityName" then
			
				-- Is it the name of the controlling actor?
				if rAttrSchema.sAnnotation == "ControllingActor" then
					sActorType = "Actor"
					sType = "ControllingActor"
				else
					sType = "String"
				end
				sEngineType = "Name"
				
			elseif sAttrType == "prototype" then
			
				sType = "Prototype"
				sEngineType = "Prototype*"
			
			elseif sAttrType == "vec2" or sAttrType == "vec3" then
			
				if sAttrType == "vec2" then
					sType = "Vector2"
				else
					sType = "Vector3"
				end
				sEngineType = sAttrType
				
				defaultValue = sAttrType .. "(" .. ToStringList(rAttrSchema.tDefaultVec) .. ")"
				
			elseif sAttrType == "number" then
			
				sType = "Numeric"
				sEngineType = "float"
					
			elseif sAttrType == "bool" then
			
				sType = "Boolean"
				sEngineType = "bool"
					
			elseif sAttrType == "string" then
			
				sType = "String"
				sEngineType = "string"
                
                -- Check for specific meta flags
                if isMetaData then
                    if sAttrName == "MetaFlag_CameraCommand" then
                        sActorType = "Camera"
                    elseif sAttrName == "MetaFlag_LogicCommand" then
                        sActorType = "Logic"
                    elseif sAttrName == "MetaFlag_AnimEventOwnerCommand" then
                        sActorType = "AnimEventOwner"
                    elseif sAttrName == "MetaFlag_AnimEventCommand" then
                        sActorType = "AnimEvent"
                    elseif sAttrName == "MetaFlag_EffectEventCommand" then
                        sActorType = "EffectEvent"
                    end
                end
				
			elseif sAttrType == "enum" then
            
				sType = "Enum"
				sEngineType = sAttrName
                tEnumOptions = rAttrSchema.tCandidates
            
			elseif sAttrType == "metaData" then
			
                if #sMetaDataAttrs == 0 then
                
                    local rMetaSchema = rAttrSchema.tFieldSchemas
                    local sMetaAttrs, sMetaActorType, _ = SchemaAttributesToXml( rMetaSchema[1].tFieldSchemas, true )
                    sMetaDataAttrs = sMetaAttrs
                    
                    if sMetaActorType ~= "Global" then
                        if sActorType == "Global" then
                            sActorType = sMetaActorType
                        else
                            Trace(TT_Warning, "Can't override actor type of command to " .. sMetaActorType .. " because it has been defined to be " .. sActorType .. "  !")
                        end
                    end
                    
                else
                    Trace(TT_Warning, "More than one meta schema!")
                end

			else
			
				Trace(TT_Warning, "Unknown type: " .. sAttrType)
				
			end
			
			if sType ~= nil and sEngineType ~= nil then
			
				sAttributes = sAttributes .. " type=\"" .. sType .. "\" engineType=\"" .. sEngineType .. "\""
				
				-- Default value
				sAttributes = sAttributes .. " defaultValue=\"" .. defaultValue .. "\""
                
                -- Append enum options
                if tEnumOptions ~= nil and #tEnumOptions > 0 then
                    local sEnumOptions = ""
                    for _, sOption in ipairs(tEnumOptions) do
                        sEnumOptions = sEnumOptions .. sOption .. "|"
                    end
                    sAttributes = sAttributes .. " enumValues=\"" .. sEnumOptions .. "\""
                end
				
				-- Construct the Xml tag for the current attribute                
				sSchemaAttrs = sSchemaAttrs .. "\t\t<" .. sAttrTag .. " " .. sAttributes .. " />\n"
			end
			
		end
	end
	
	return sSchemaAttrs, sActorType, sMetaDataAttrs

end

function SchemaToXml( sTypeName, rSchema )
	
	local sAttributesXml, sActorType, sMetaAttrs = SchemaAttributesToXml( rSchema.tFieldSchemas )
	
	local sAttributes = "tagName=\"" .. sTypeName .. "\""
	sAttributes = sAttributes .. " name=\"" .. GetDisplayName(sTypeName) .. "\""
	sAttributes = sAttributes .. " description=\"" .. rSchema.sDescription .. "\""
	sAttributes = sAttributes .. " actorType=\"" .. sActorType .. "\""
	
	local sSchemaXml = "\t<command " .. sAttributes .. ">\n"
	
	if #sMetaAttrs > 0 then
        sSchemaXml = sSchemaXml .. sMetaAttrs
    end
    
    sSchemaXml = sSchemaXml .. sAttributesXml
	
	sSchemaXml = sSchemaXml .. "\t</command>"
	
	return sSchemaXml

end

function SchemasToXml( tSchemas )

	local sSchemasXml = "<commands>"

	for sTypeName,rSchema in pairs(tSchemas) do
		if sTypeName ~= "SeqCommand" and sTypeName ~= "AnimEvent" and sTypeName ~= "EffectEvent" then
			local sSchemaXml = SchemaToXml(sTypeName, rSchema)
			sSchemasXml = sSchemasXml .. "\n" .. sSchemaXml
		end
	end
	
	sSchemasXml = sSchemasXml .. "\n</commands>"
	
	return sSchemasXml
	
end

function exportSequenceCommands()
	local SeqCommand = require('SeqCommand')
	SeqCommand.loadEditorCommands()
	
	-- Get the Xml description 
	local seqCommandsXml = SchemasToXml(SeqCommand.tEditorSchemas, "command")
	
	local seqCommandsFile = io.open("SequenceCommands.xml", "w")
	seqCommandsFile:write(seqCommandsXml)
	seqCommandsFile:close()
	
	Trace("Export successful: SequenceCommands.xml")
	print("Sequence commands:")
	print(seqCommandsXml)
	
end

exportSequenceCommands()
