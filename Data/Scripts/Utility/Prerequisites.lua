-- Defines the prereq tests.
-- Pulled out of OptionData.lua to keep it free from includes.

local Prerequisites = {}

Prerequisites.Spacewalking = function(rChar, rAO)
    return rChar:spacewalking() or false
end

Prerequisites.WearingSuit = function(rChar, rAO)
    return rChar:wearingSpacesuit()
end

Prerequisites.EmptyHands = function(rChar, rAO)
    return not rChar.tStatus.bCuffed and rChar:heldItem() == nil 
end

Prerequisites.EmptyHandsOrCuffed = function(rChar, rAO)
    return rChar:heldItem() == nil 
end

Prerequisites.Cuffed = function(rChar, rAO)
    return rChar.tStatus.bCuffed == true
end

Prerequisites.HeldItem = function(rChar, rAO, desiredValue)
    if rChar:heldItem() and rChar:heldItem().sTemplate == desiredValue then return desiredValue end
    if rChar:getInventoryItemOfTemplate(desiredValue) then return desiredValue end
    return nil
end

Prerequisites.HeldItemInDanger = function(rChar, rAO, desiredValue)
    return Prerequisites.HeldItem(rChar, rAO, desiredValue)
end

return Prerequisites
