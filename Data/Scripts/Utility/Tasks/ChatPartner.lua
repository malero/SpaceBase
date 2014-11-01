local Class = require('Class')
local Task = require('Utility.Task')
local Chat = require('Utility.Tasks.Chat')

local ChatPartner = Class.create(Chat)

function ChatPartner:init(rChar,tPromisedNeeds,rActivityOption)
    Chat.init(self, rChar, tPromisedNeeds, rActivityOption)
end

function ChatPartner:_startChat(duration)
    self.bChatting = true
	-- no logic further than this point; the chat initiator's Chat task
	-- controls us from here on.
	--print('ChatPartner '..self.rChar.tStats.sUniqueID..' started')
end

function ChatPartner:onUpdate(dt, dtRaw)
    if not self.bChatting then
        self:_followTarget(dt)
    end
end

return ChatPartner
