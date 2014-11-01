-- Hack object to emulate the Entity functionality of Reds.
-- Occasionally necessary to use some of their features.

local Class=require('Class')

local Entity = Class.create()

function Entity:init(prop, layer, name)
    self.rProp = prop
    self.tProps = {}
    self.tProps[prop] = prop
    self.rRenderLayer = layer
    self.sName = name
end

function Entity:getSceneLayer()
    return self.rRenderLayer
end

function Entity:addProp(rProp)
    self.tProps[rProp] = rProp
    if self.rRenderLayer then
        self.rRenderLayer:insertProp(rProp)
    end
end

function Entity:removeProp(rProp)
    self.tProps[rProp] = nil
    if self.rRenderLayer then
        self.rRenderLayer:removeProp(rProp)
    end
end

function Entity:setRenderLayer(rLayer)
    if rLayer ~= self.rRenderLayer then
        if self.rRenderLayer then
            for rProp,_ in pairs(self.tProps) do
                self.rRenderLayer:removeProp(rProp)
            end
        end
        self.rRenderLayer = rLayer
        if self.rRenderLayer then
            for rProp,_ in pairs(self.tProps) do
                self.rRenderLayer:insertProp(rProp)
            end
        end
    end
end

function Entity:getProp()
    return self.rProp
end

return Entity
