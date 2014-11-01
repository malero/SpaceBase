--x; /*
--
-- $Id$
-- Copyright 2005-2012 Double Fine Productions
-- All rights reserved.  Proprietary and Confidential.
--

local DFFile = require('DFCommon.File')

-- Don't reset this stuff when the file is reloaded.
if not g_classes then
	g_classes = {}
end

function _LoadClass(class_name, class_root)
	-- Loading a file returns a function (representing the file contents).
	-- Executing the file returns an object.

	local filename = string.format('%s/%s.lua', class_root, string.gsub(class_name, "%.", "/"))
	filename = DFFile.getDataPath(filename)
	Trace(TT_Spam, "Loading file "..filename)
	local file_contents, err = loadfile(filename)

	if not file_contents then
		Trace(TT_Error, "Compiling %s: %s", class_name, err)
		return nil
	end

	-- Executing the file returns a table
	local bSuccess, result = pcall(file_contents)
	if not bSuccess then
		Trace(TT_Error, "Executing %s: %s", class_name, result)
		return nil
	end

	if not result then
		Tracef(TT_Error, "Executing %s: didn't return a table", class_name)
		return nil
	end

	rawset(result, 'Type', class_name)

	if not getmetatable(result) and class_name ~= "Component" and class_name ~= "Entity" then
		Trace(TT_Error, "Executing %s: didn't return a proper table", class_name)
		return nil
	end
	
	return result
end

-- Memoized version of _LoadClass
function _GetClass(class_name, class_root)
	if not g_classes[class_name] then
		g_classes[class_name] = _LoadClass(class_name, class_root)
	end
	return g_classes[class_name]
end

-- Return an empty table set up to inherit from |parent_class|
-- Used in .lua files
function _CreateSubclass(parent_class, class_root)
	local klass = {}
	if parent_class then
		local p = _GetClass(parent_class, class_root)
		-- if a parent was specified, then it better exist
		assert(p ~= nil)
		klass.Parent = p
		setmetatable(klass, { __index = p })
	end
	return klass
end

function CreateSubclass(parent_class)
	return _CreateSubclass(parent_class, "Scripts")
end

-- */
