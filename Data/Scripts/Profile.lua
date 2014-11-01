
local Profile = {}

local v = nil
local jit = require("jit")    
local DFUtil = require('DFCommon.Util')

local DEFAULT_ENABLED = true

local ffi = require("ffi")
ffi.cdef[[
void DFFFI_profileEnterScope(const char*);
void DFFFI_profileLeaveScope(const char*);
]]

local nilFunction = function(scopeName)
end

local function FFIProfileEnterScope(scope)
	ffi.C.DFFFI_profileEnterScope(scope)
end

local function FFIProfileLeaveScope(scope)
	ffi.C.DFFFI_profileLeaveScope(scope)
end

Profile.setProfilingEnabled = function(bEnabled)
	local bUseFFI = MOAIEnvironment.osBrand ~= "OSX"

	if bEnabled then
		if bUseFFI then
	        v = require('jit.v')
			Profile.enterScope = FFIProfileEnterScope
			Profile.leaveScope = FFIProfileLeaveScope
		else
			Profile.enterScope = MOAISim.profileEnterScope
			Profile.leaveScope = MOAISim.profileLeaveScope
		end
	else
		-- Set functions to nops so we don't have to wrap them with a branch
		Profile.enterScope = nilFunction
		Profile.leaveScope = nilFunction
	end
	Profile.enabled = bEnabled
end

function Profile.findFileName(prefix, ext)
	for i = 1, 100 do
		local name = prefix .. i .. ext
		local f = io.open(name,"r")
		if f == nil then
			return name
		else
			io.close(f) 
		end
	end
end

Profile.setJitProfilingEnabled = function(bEnabled)
	if bEnabled then
		if not jit.status() then
			Trace(TT_Warning, "Can't enable jit profiling when jit disabled.")
			return
		end

		if DFUtil.isTraceEnabled() then
			Trace(TT_Warning, "JIT profiling is not very useful when Trace is enabled.  Call DFUtil.setTraceEnabled(false) for better results.")
		end

		local f = Profile.findFileName("jit_profile", ".txt")
		v.on(f)
	else
		v.off()
	end
end

local shinyName = nil
local shinyLoops = 0
local shinyCount = 0
local shinyInLoop = false
SHINY_DEFAULT_ZONE = 'main_loop'
SHINY_DEFAULT_LOOPS = 1

Profile.shinyStart = function(name, loopcount)
	name = name or SHINY_DEFAULT_ZONE
	loopcount = loopcount or SHINY_DEFAULT_LOOPS

    if not shiny then return end
	if shinyName then
		Trace("Already running shiny profile.")
		return
	end

	shinyName = name
	shinyLoops = loopcount
	shinyCount = 0

	Profile.setProfilingEnabled(false)
end

Profile.shinyStop = function(name)
	if shinyName then
		local f = Profile.findFileName(shinyName .. '_' .. shinyLoops .. '_', '.txt')
		shiny.output(f)
		shinyLoops = 0
		shinyCount = 0
		shinyName = nil
		shinyInLoop = false
	end
end

Profile.shinyBeginLoop = function(name)
	if shinyName ~= name or shinyLoops <= 0 then
		return
	end

	assert (not shinyInLoop)
	shinyInLoop = true

	shiny.start()
end

Profile.shinyEndLoop = function(name)
	if shinyName ~= name or shinyLoops <= 0 then
		return
	end

	shiny.stop()
	shiny.update()
	shinyInLoop = false

	shinyCount = shinyCount + 1
	if shinyCount >= shinyLoops then
		Trace("Shiny profile complete.")
		Profile.shinyStop()
	end
end

Profile.setProfilingEnabled(DEFAULT_ENABLED)

return Profile