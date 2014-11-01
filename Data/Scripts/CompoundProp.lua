local Class=require('Class')
local MiscUtil=require('MiscUtil')
local Renderer=require('Renderer')
local DFGraphics = require('DFCommon.Graphics')

local CompoundProp = Class.create(nil, MOAIProp.new)

-- *grumble grumble MOAI attr linking incompatible with renderlayer insert/remove pattern grumble grumble*
function CompoundProp:init()
end

function CompoundProp:setScl(x,y,z)
    self._UserData:setScl(x,y,z)
    if x < 0 or y < 0 and (not x < 0 or not y < 0) then
        if self.tProps then
            for _,rProp in ipairs(self.tProps) do
                rProp:setLoc(0,0,-5)
            end
        end
    end
end

function CompoundProp:addSprite(sSpriteName,sSpriteSheetName)
    local rProp
    if not self.sSpriteName then
        self.sSpriteName = sSpriteName
        self.sSpriteSheetName = sSpriteSheetName
        rProp = self
    else
        if not self.tProps then self.tProps = {} end
        rProp = MOAIProp.new()
        table.insert(self.tProps,rProp)
        MiscUtil.setTransformVisParent(rProp,self)
        rProp:setLoc(0,0,5)
    end

    local rSpriteSheet = DFGraphics.loadSpriteSheet(sSpriteSheetName, false, false, false)
    rProp:setDeck(rSpriteSheet)
    rProp:setIndex(rSpriteSheet.names[sSpriteName])
    
    return rProp
end

function CompoundProp:addToRenderLayer(sLayerName)
    Renderer.getRenderLayer(sLayerName):insertProp(self)
    if self.tProps then
        for _,rProp in ipairs(self.tProps) do
            Renderer.getRenderLayer(sLayerName):insertProp(rProp)
        end
    end
end

function CompoundProp:removeFromRenderLayer(sLayerName)
    Renderer.getRenderLayer(sLayerName):removeProp(self)
    if self.tProps then
        for _,rProp in ipairs(self.tProps) do
            Renderer.getRenderLayer(sLayerName):removeProp(rProp)
        end
    end
end

return CompoundProp
