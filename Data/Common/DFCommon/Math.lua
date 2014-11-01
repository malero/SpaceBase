-- "m" for "module"
local m = {}

local EPSILON = 0.001

function m.distance( x1, y1, z1, x2, y2, z2 )
    if y2 then
        return math.sqrt( ( ( x2 - x1 ) ^ 2 ) + ( ( y2 - y1 ) ^ 2 ) + ( ( z2 - z1 ) ^ 2) ) 
    elseif x2 then
        return math.sqrt( ( ( z1 - x1 ) ^ 2 ) + ( ( x2 - y1 ) ^ 2 ) )
    else
        return math.sqrt( ( x1 ^ 2 ) + ( y1 ^ 2 ) )
    end
end

function m.distance2D( x1, y1, x2, y2 )
    return math.sqrt( ( ( x2 - x1 ) ^ 2 ) + ( ( y2 - y1 ) ^ 2 ) )
end

function m.distance2DSquared( x1, y1, x2, y2 )
    return ( ( x2 - x1 ) ^ 2 ) + ( ( y2 - y1 ) ^ 2 )
end

function m.distanceSquared( x1, y1, z1, x2, y2, z2 )
    if y2 then
        return ( ( x2 - x1 ) ^ 2 ) + ( ( y2 - y1 ) ^ 2 ) + ( ( z2 - z1 ) ^ 2)
    elseif x2 then
        return ( ( z1 - x1 ) ^ 2 ) + ( ( x2 - y1 ) ^ 2 )
    else
        return ( x1 ^ 2 ) + ( y1 ^ 2 )
    end
end

function m.length( dx, dy )
	return math.sqrt( ( dx ^ 2 ) + ( dy ^ 2 ) )
end

function m.lengthSquared( dx, dy )
	return ( dx ^ 2 ) + ( dy ^ 2 )
end

function m.dot( x1, y1, x2, y2 )
	return x1 * x2 + y1 * y2
end

function m.clamp( val, minVal, maxVal )
    val = math.min(val, maxVal)
    val = math.max(val, minVal)
    return val
end

-- returns in degrees the angle of v2(x2,y2) relative to v1(x1,y1)
function m.getAngleBetween( x1, y1, x2, y2 )
    local nx1, ny1 = m.normalize( x1,y1 )
    local nx2, ny2 = m.normalize( x2,y2 )
    local theta = math.atan2(ny2,nx2) - math.atan2(ny1,nx1)
    local indegrees = theta * ( 180 / math.pi )
   
    return indegrees
end

function m.cross( x0,y0,z0, x1,y1,z1 )
    return ( y0 * z0 ) - ( z1 * y0 ), ( z0 * x1 ) - ( x0 * z1 ), ( x0 * y1 ) - ( y0 * x1 )
end

function m.normalize( dx, dy )
	local norm = m.length( dx, dy )
	if norm ~= 0 then
		norm = 1 / norm
	end
	dx = dx * norm
	dy = dy * norm
	return dx, dy
end

-- Returns true if rectangles overlap
function m.overlaps(xMin1, yMin1, xMax1, yMax1,
                    xMin2, yMin2, xMax2, yMax2)
    return ( (xMin1 < xMax2) and
             (xMax1 > xMin2) and
             (yMin1 < yMax2) and
             (yMax1 > yMin2) )
end

-- Returns true if point is in rect. (inclusive)
function m.pointIn(x, y, xMin, yMin, xMax, yMax)
    return ( (x <= xMax) and
             (x >= xMin) and
             (y <= yMax) and
             (y >= yMin) )
end

function m.randomFloat( lower, upper )
    return ( lower + ( ( upper - lower ) * math.random() ) )
end

local boxMullerRand1 = nil
local boxMullerRand2 = nil
function m.boxMuller(standardDeviation)
    local variance = standardDeviation * standardDeviation
 
	if boxMullerRand1 then
		local rng = math.sqrt(variance * boxMullerRand1) * math.sin(boxMullerRand2)
        boxMullerRand1, boxMullerRand2 = nil,nil
        return rng
    end
 
	boxMullerRand1 = math.random()
	if boxMullerRand1 < EPSILON then boxMullerRand1 = EPSILON end
	boxMullerRand1 = -2 * math.log(boxMullerRand1)
	boxMullerRand2 = math.random() * math.pi * 2
 
	return math.sqrt(variance * boxMullerRand1) * math.cos(boxMullerRand2)
end

function m.pinPct(val)
    return math.min(math.max(0,val),1)
end

function m.pin( n, minVal, maxVal )
    if minVal > maxVal then
        local temp = minVal
        minVal = maxVal
        maxVal = temp
    end
    
    return math.min( math.max( n, minVal ), maxVal )
end

function m.lerp( a, b, t )
    return a * (1 - t) + b * t
end

function m.accumulate( x, a, w )
    local numComponents = #x
    for i=1,numComponents do
        x[i] = x[i] + a[i] * w
    end
end

-- TODO: port to / expose from C++
function m.lineIntersection(x1,y1,x2,y2,x3,y3,x4,y4)
    local denX,denY = (x1-x2)*(y3-y4) - (y1-y2)*(x3-x4), (x1-x2)*(y3-y4) - (y1-y2)*(x3-x4)
    if math.abs(denX) < 0.00001 or math.abs(denY) < 0.00001 then
        return nil
    end
    local numX,numY = (x1*y2-y1*x2)*(x3-x4) - (x1-x2)*(x3*y4-y3*x4), (x1*y2-y1*x2)*(y3-y4)-(y1-y2)*(x3*y4-y3*x4)
    return numX/denX,numY/denY
end

function m.sign(n)
    return n >= 0 and 1 or -1    
end

function m.fcmp(a, b)
    return math.abs(a - b) < EPSILON
end

function m.sanitizeVector( vec, default )

    if vec == nil then
        return default
    end

    local result = {}
    local numComponents = #default
    for i=1, numComponents do
        if vec[i] == nil then
            table.insert(result, default[i])
        else
            table.insert(result, vec[i])
        end
    end
    
    return result
end

function m.roundDecimal(x, dp)
	return tonumber(string.format("%." .. (dp or 0) .. "f", x))
end

return m
