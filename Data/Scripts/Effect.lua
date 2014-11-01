local Class=require('Class')
local World=require('World')
local ParticleSystem=require('ParticleSystem')
local Renderer=require('Renderer')
local Entity=require('Entity')
local DFUtil = require('DFCommon.Util')

local Effect = Class.create(nil, MOAIProp.new)

Effect.RENDER_LAYER = 'WorldWall'

function Effect:init(tEffectPaths, wx,wy, attachEntity, sLayerName, tOffsetLoc)
    if type(tEffectPaths) == 'string' then tEffectPaths = {tEffectPaths} end
    
    self.tEffects = {}
    self.rLayer = Renderer.getRenderLayer(sLayerName or Effect.RENDER_LAYER)
    self.hackEntity = Entity.new(self, self.rLayer, 'Effect')

    for i,v in ipairs(tEffectPaths) do
	    if attachEntity then
            table.insert(self.tEffects,ParticleSystem.new(attachEntity, v))
	    else
            table.insert(self.tEffects,ParticleSystem.new(self.hackEntity, v))
	    end
    end

    local z = World.getHackySortingZ(wx,wy)
    self:setLoc(wx,wy,z) 
    self.rLayer:insertProp(self)

    for i,v in ipairs(self.tEffects) do
        v:init()
        if tOffsetLoc then
            v:setOffsetLocation(tOffsetLoc)
        end
        if not attachEntity then
		    v:setOffsetRotation( {30,0,0} )
	    end
        v:addToEntity()
        v:start()
    end
end

function Effect:remove()
    for i,v in ipairs(self.tEffects) do
        v:unload()
    end
    self.tEffects = nil
end

return Effect

