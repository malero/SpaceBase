-- Temp testing activity.
-- Character just stands around and does nothing.
-- Should not be used in shipping game.

local Task=require('Utility.Task')
local Class=require('Class')
local TreeWalker=require('AI.TreeWalker')
local BehaviorTree=require('AI.BehaviorTree')

local TreeWrapTask = Class.create(Task)

function TreeWrapTask:init(rChar, tPromisedNeeds, rActivityOption, treeName, tFakeboard)
    self.super.init(self, rChar,tPromisedNeeds, rActivityOption)
    self.tTree = require('AI.TreeDefs')[treeName]
    self.rBehaviorTree = BehaviorTree.new('Wrap_'..treeName, self.tTree, rChar)    
    self.rTreeWalker = TreeWalker.new(true)
    self.rTreeWalker:tick(self.rBehaviorTree, 0, tFakeboard)
end

function TreeWrapTask:onUpdate(dt)
    return self.rTreeWalker:tick(self.rBehaviorTree, dt)
end

return TreeWrapTask
