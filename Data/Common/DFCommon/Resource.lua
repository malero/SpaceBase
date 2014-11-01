-- "m" for "module"
local m = {}

function RESOURCE(sFilename)

    local tResource = {}
    tResource.sFilename = sFilename
    
    function tResource.getFilename()
        return tResource.sFilename
    end
    
    return tResource
end

function DYNAMIC_RESOURCE(sFilename)

    return RESOURCE(sFilename)
end

return m
