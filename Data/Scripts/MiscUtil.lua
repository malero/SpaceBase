local m = {}

local World = require('WorldConstants')
local DFMath=require('DFCommon.Math')

function m.isoDist(x0,y0,x1,y1)
    return math.max(math.abs(x1-x0),math.abs(y1-y0))
end

m._worldDirToCartesian={
    [World.directions.SE]={0,-1},
    [World.directions.S]={-1,-1},
    [World.directions.SW]={-1,0},
    [World.directions.W]={-1,1},
    [World.directions.NW]={0,1},
    [World.directions.N]={1,1},
    [World.directions.NE]={1,0},
    [World.directions.E]={1,-1},
    [World.directions.SAME]={0,0},
}

-- takes a direction in iso space and returns a Cartesian coord in world space, compatible with isoToSquare's transformation.
function m.isoDirToCartesian(dir)
    return unpack(m._worldDirToCartesian[dir])
end

function m.isoToSquare(tx,ty)
    local ns, we
    if ty % 2 == 0 then
        ns = tx+ty*.5
        we = g_World.width * .5 - ty*.5 + tx
    else
        ns = tx+ty*.5-.5
        we = g_World.width * .5 - ty*.5 + tx - .5
    end
    return ns,we
end

function m.isoSquareDist(x1,y1,x2,y2)
    x1,y1 = m.isoToSquare(x1,y1)
    x2,y2 = m.isoToSquare(x2,y2)
    local dx,dy = x2-x1,y2-y1
    dx,dy=dx*dx,dy*dy
    return math.sqrt(dx+dy)
end

function m.setTransformVisParent(child,parent)
    --child:setAttrLink ( MOAIProp2D.INHERIT_TRANSFORM, parent, MOAIProp2D.TRANSFORM_TRAIT )    
    if parent then
        child:setAttrLink(MOAITransform.INHERIT_TRANSFORM, parent, MOAITransform.TRANSFORM_TRAIT)
    else
        child:clearAttrLink(MOAITransform.INHERIT_TRANSFORM)
    end
    --child:setAttrLink(MOAIProp.ATTR_VISIBLE, parent)
end

function m.deepCopyData(object)
    local lookup_table = {}
    local function _copy(object)
        local t = type(object)
        if t == 'function' or t == 'thread' or t == 'userdata' then            
        elseif t == 'string' or t == 'nil' or t == 'number' or t == 'boolean' then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        else
            assert(not rawget(object, 'NO_DEEP_COPY'))

            local new_table = {}
            lookup_table[object] = new_table
            for index, value in pairs(object) do
                new_table[_copy(index)] = _copy(value)
            end
            return new_table
        end
    end
    return _copy(object)
end

function m.arrayIndexOf(arr,elem)
    for idx,v in ipairs(arr) do
        if v == elem then 
            return idx
        end
    end
end

-- Between old and new, what key-value pairs were added? Which were removed?
-- Simply does a test for keys. Ignores values.
-- Returns tAdded,tRemoved
function m.diffKeys(tOld,tNew)
    local tRemoved = {}
    local tAdded = {}
    for k,v in pairs(tOld) do
        if not tNew[k] then tRemoved[k] = v end
    end
    for k,v in pairs(tNew) do
        if not tOld[k] then tAdded[k] = v end
    end
    return tAdded,tRemoved
end

-- solve the quadratic equation to hit a moving target.
-- Returns target point at which to aim.
function m.leadTarget(wxSource,wySource, bulletSpeed, wxTarget, wyTarget, targetVelX, targetVelY)
    local a = bulletSpeed*bulletSpeed - DFMath.lengthSquared(targetVelX, targetVelY)
    local dx,dy = wxTarget-wxSource,wyTarget-wySource
    local b = -2*DFMath.dot(targetVelX, targetVelY, dx, dy)
    local c = -DFMath.lengthSquared(dx,dy)
    local largestRoot = (-b+math.sqrt(b*b-4*a*c))/(2*a) -- largetRoot is t
    local wxt,wyt = wxTarget+largestRoot*targetVelX, wyTarget+largestRoot*targetVelY
    --[[
    print('t',largestRoot)
    print('aim at',wxt,wyt)
    local trajx,trajy = wxt-wxSource,wyt-wySource
    trajx,trajy = DFMath.normalize(trajx,trajy)
    print('bullet trajectory',trajx,trajy,'reaches',wxSource+trajx*largestRoot,wySource+trajy*largestRoot)
    ]]--
    return wxt,wyt
end

-- INCREDIBLY SLOW
-- Do not use in performance-intensive places
function m.randomKey(t, tExclude)
    local array={}
    for k,v in pairs(t) do
        if not tExclude or not tExclude[k] then
            table.insert(array,k)
        end
    end
    local n = #array
    return n > 0 and array[math.random(1,n)]
end

function m.randomValue(t)
	return t[math.random(#t)]
end

function m.weightedRandom(tChoices, nSeed)
	-- get range of weights
	local total = 0
	for choice,weight in pairs(tChoices) do
        if type(weight) == 'table' then weight = weight.weight end
		total = total + weight
	end
	-- pick a value in total range and use it as a threshold
	local pick = math.random(0, total)
	-- if seed provided, deterministic pseudorandom based on that
	if nSeed then
		pick = (1103515245 * nSeed + 12345) % 2^32
		pick = (pick / 2^32) * total
	end
	local lastChoice
	for choice,weight in pairs(tChoices) do
        if type(weight) == 'table' then weight = weight.weight end
		pick = pick - weight
		if pick <= 0 then
			return choice
		end
		lastChoice = choice
	end
	return lastChoice
end

function m.padString(inString, nAmount, bLeftJustify, char)
    char = char or ' '
	-- auto convert type for convenience
	if type(inString) ~= 'string' then
		inString = tostring(inString)
	end
	while #inString < nAmount do
		if bLeftJustify then
            inString = inString .. char
		else
			inString = char .. inString
		end
	end
	return inString
end

m.tRomanNumeralMap = {
    -- table of tables because Lua tables are unordered and toRoman algo
    -- depends on order of denominations :/
    { M  = 1000 },
    { CM = 900 },
    { D  = 500 },
    { CD = 400 },
    { C  = 100 },
    { XC = 90 },
    { L  = 50 },
    { XL = 40 },
    { X  = 10 },
    { IX = 9 },
    { V  = 5 },
    { IV = 4 },
    { I  = 1 },
}

function m.toRoman(n)
    if n > 4999 or n < 1 then
        return 'MiscUtil.toRoman: out of range!'
    end
    local r = ''
    for _,numeralPair in ipairs(m.tRomanNumeralMap) do
        for numeral,integer in pairs(numeralPair) do
            while n >= integer do
                r = r .. numeral
                n = n - integer
            end
        end
    end
    return r
end

m.tSeverityCodes = {
    { { "UIMISC008TEXT" }, 'low' }, 
    { { "UIMISC003TEXT" }, 'low' }, 
    { { "UIMISC001TEXT" }, 'low' }, 
    { { "UIMISC002TEXT" }, 'mid' },
    { { "UIMISC010TEXT" }, 'mid' },
    { { "UIMISC004TEXT" }, 'mid' }, 
    { { "UIMISC005TEXT" }, 'high' },
    { { "UIMISC006TEXT" }, 'high' },
    { { "UIMISC009TEXT" }, 'high' },
}

function m.getSeverityFromValue(nValue)
    local DFMath = require('DFCommon.Math')
    nValue = DFMath.clamp((nValue or 0), 0, 1)
    local step = 1 / #m.tSeverityCodes
    local tChoice = m.tSeverityCodes[DFMath.clamp(math.floor(nValue / step)+1, 1, #m.tSeverityCodes)]
    local severityText = g_LM.line(tChoice[1][1])
    local severityColor = tChoice[2]
    return severityText, severityColor
end

m.tDistanceCodes1 = { "UIMISC011TEXT" }
m.tDistanceCodes2 = { "UIMISC012TEXT" }
m.tDistanceCodes3 = { "UIMISC013TEXT" }
m.tDistanceCodes = { 
    { m.tDistanceCodes1, 'close' },
    { m.tDistanceCodes2, 'mid' },
    { m.tDistanceCodes3, 'far' },
}

function m.getDistanceFromValue(nValue)
    local DFMath = require('DFCommon.Math')
    nValue = DFMath.clamp((nValue or 0), 0, 1)
    local step = 1 / #m.tDistanceCodes
    local tChoice = m.tDistanceCodes[DFMath.clamp(math.floor(nValue / step)+1, 1, #m.tDistanceCodes)]
    local distanceText = g_LM.line(m.randomValue(tChoice[1]))
    local distanceColor = tChoice[2]
    return distanceText, distanceColor
end

function m.getGalaxyMapValues(x, y)
    return require('UI.Data.GalaxyData')[x..","..y]
end 

function m.getGalaxyMapValue(x, y, key)
    local tValues = m.getGalaxyMapValues(x, y)
    return tValues[key]
end

-- returns H:MM:SS format string for specified time in seconds
-- if no H component, returns MM:SS, NOT 0:MM:SS
function m.formatTime(nSeconds)
    local hours = math.floor(nSeconds / 3600)
	local minutes = math.floor((nSeconds % 3600) / 60)
	local seconds = math.floor(nSeconds % 60)
    local s = ''
    if hours > 0 then
        s = s .. hours .. ':'
    end
	s = s .. string.format("%02d", minutes) .. ':'
	s = s .. string.format("%02d", seconds)
	return s
end

m.staticRigCounter=1

function m.spawnRig(sRigPath,sTexture,sLayer, sMaterial)
    local rProp = MOAIProp.new()

    local rRenderLayer = g_Renderer.getRenderLayer(sLayer)
    local tHackEntity = require('Entity').new(rProp, rRenderLayer, sRigPath..'_'..m.staticRigCounter)
    m.staticRigCounter=m.staticRigCounter+1

    local tRigArgs = {}
    tRigArgs.sResource = sRigPath
    tRigArgs.sMaterial = sMaterial or "meshSingleTexture"
    tRigArgs.sTexture = sTexture
    local rRig = require('Rig').new(tHackEntity, tRigArgs, require('GameRules').worldAssets)

    rRenderLayer:insertProp(tHackEntity.rProp)
        
    rRig:activate()

    rProp.rRig=rRig
    rProp.rEntity=tHackEntity
    return rProp --rRig,tHackEntity
end

return m
