local Task=require('Utility.Task')
local DFMath=require('DFCommon.Math')
local World=require('World')
local GameRules=require('GameRules')
local Class=require('Class')
local Log=require('Log')
local MiscUtil=require('MiscUtil')
local Malady = require('Malady')
local DFUtil = require('DFCommon.Util')
local Topics=require('Topics')
local Character=require('CharacterConstants')

local Chat = Class.create(Task)

Chat.LOG_CHANCE = 0.25

Chat.PHASE_WAITING_TO_START = 0
Chat.PHASE_GREET = 1
Chat.PHASE_NEW_TOPIC = 2
Chat.PHASE_RESPOND = 3
Chat.PHASE_RESULT = 4
Chat.PHASE_OUTRO = 5

Chat.PHASE_START_TRADE = 6
Chat.PHASE_RESPOND_TO_TRADE = 7
Chat.PHASE_TRADE_RESULT = 8

Chat.GREET_DURATION = 1
Chat.BANTER_DURATION = 3
Chat.OUTRO_DURATION = 1

Chat.GREET_LINECODE = 'EMTASK014TEXT'
Chat.INTRO_LINECODE = 'EMTASK015TEXT'
Chat.BYE_LINECODE = 'EMTASK016TEXT'
Chat.YOU_LINECODE = 'EMTASK017TEXT'

-- terminology used:
-- speaker: the person initiating the chat
-- target: the person being drawn into chat by the speaker
-- other: the person other than one doing the thinking a function represents

function Chat:init(rChar, tPromisedNeeds, rActivityOption)
    Task.init(self,rChar,tPromisedNeeds,rActivityOption)
    self.rTargetObject = rActivityOption.tData.rTargetObject
    self.nNextTimeoutTest=GameRules.elapsedTime+15
	self.pathX,self.pathY = rActivityOption.tData.pathX,rActivityOption.tData.pathY
	self.partnerX,self.partnerY = rActivityOption.tData.partnerX,rActivityOption.tData.partnerY
    self:setPath(rActivityOption.tBlackboard.tPath)
	assert(self.rTargetObject and self.rChar)
	assert(self.rChar ~= self.rTargetObject)
    if rActivityOption.name == 'Chat' then
        self.rTargetObject:setPendingCoopTask('ChatPartner',rChar)
    end
	self.phase = Chat.PHASE_WAITING_TO_START
end

function Chat:_isTargetAdjacent()
    if self.rChar:isElevated() or self.rTargetObject:isElevated() then return false end
    local cx,cy = self.rChar:getLoc()
    local tx,ty = self.rTargetObject:getLoc()
    return World.areWorldCoordsAdjacent(cx,cy,tx,ty, true, false)
end

function Chat:_testChat()
    local sActivityName = self.rTargetObject:getCurrentTaskName()
    -- if anyone's still walking, let them finish first.
    if self.tPath or (self.rTargetObject and self.rTargetObject.rCurrentTask and self.rTargetObject.rCurrentTask.rPath) then 
        return false 
    end
    if self:_isTargetAdjacent() and (sActivityName == 'Chat' or sActivityName == 'ChatPartner') and 
            self.rTargetObject.rCurrentTask.rTargetObject == self.rChar and not self.rTargetObject.rCurrentTask.tPath then
        self:_startChat()
    end
end

function Chat:_testStillValid()
    local sRequired
    if self.rChar:getCurrentTaskName() == 'ChatPartner' then
        sRequired = 'Chat'
    elseif self.rChar:getCurrentTaskName() == 'Chat' then
        sRequired = 'ChatPartner'
    else
        return false, 'source character is not in chat task'
    end
    return self:_testCoopStillValid(sRequired)
end

function Chat:_startChat()
    Malady.interactedWith(self.rChar,self.rTargetObject)
    self.bChatting = true
    self.rTargetObject.rCurrentTask.bChatting = true
	self.rChar:setEmoticon()
	self.rTargetObject:setEmoticon()
    self.rTargetObject.rCurrentTask:_forceChat()
	-- face each other
    local tx,ty = self.rTargetObject:getLoc()
    self.rChar:faceWorld(tx,ty)
	tx,ty = self.rChar:getLoc()
	self.rTargetObject:faceWorld(tx,ty)
	-- unfamiliar with each other?  introduce, else normal greet
	self.speakerID = self.rChar.tStats.sUniqueID
	self.speakerName = self.rChar.tStats.sName
	self.targetID = self.rTargetObject.tStats.sUniqueID
	self.targetName = self.rTargetObject.tStats.sName
	self.speakerTargetFamiliarity = self.rChar:getFamiliarity(self.targetID)
	self.targetSpeakerFamiliarity = self.rTargetObject:getFamiliarity(self.speakerID)
    local emoticonText = g_LM.line(Chat.GREET_LINECODE)
	if self.speakerTargetFamiliarity == 0 or self.targetSpeakerFamiliarity == 0 then
        emoticonText = g_LM.line(Chat.INTRO_LINECODE)
		-- meeting someone new = happy times
		local tLogData = {}
		if self.speakerTargetFamiliarity == 0 then
			tLogData.sChatPartner = self.targetName
			Log.add(Log.tTypes.CHAT_INTRODUCE, self.rChar, tLogData)
			self.rChar:alterMorale(Character.MORALE_MET_NEW_CITIZEN, 'MetCitizen')
		end
		if self.targetSpeakerFamiliarity == 0 then
			tLogData.sChatPartner = self.speakerName
			Log.add(Log.tTypes.CHAT_INTRODUCE, self.rTargetObject, tLogData)
			self.rTargetObject:alterMorale(Character.MORALE_MET_NEW_CITIZEN, 'MetCitizen')
		end
	end
	self.rChar:setEmoticon(nil, emoticonText, true)
	self.rTargetObject:setEmoticon(nil, emoticonText, true)
    self.rChar:playAnim('talk_greet')
    self.rTargetObject:playAnim('talk_greet')
	self.phase = Chat.PHASE_GREET
	self.duration = Chat.GREET_DURATION
end

function Chat:_nextChatPhase()
	if self.phase == Chat.PHASE_GREET then
        if not self:_newTrade() then
		    self:_newTopic()
        end
	elseif self.phase == Chat.PHASE_START_TRADE then
		self:_respondToTrade()
	elseif self.phase == Chat.PHASE_NEW_TOPIC then
		self:_respondToTopic()
	elseif self.phase == Chat.PHASE_RESPOND then
		self:_topicResult()
	elseif self.phase == Chat.PHASE_RESPOND_TO_TRADE then
		self:_tradeResult()
	elseif self.phase == Chat.PHASE_TRADE_RESULT then
		self:_outro()
	elseif self.phase == Chat.PHASE_RESULT then
		self:_outro()
	elseif self.phase == Chat.PHASE_OUTRO then
		self:_finishChat()
	end
end

--
-- chat phases
--

function Chat:_newTopic()
	self.phase = Chat.PHASE_NEW_TOPIC
	self.duration = Chat.BANTER_DURATION
    self.rChar:playAnim('talk_speak')
	-- get topic from global list of topics.
	-- in the future we could do a simple kind of information modeling,
	-- in which people have to learn about new topics in conversation with
	-- those who already know about them.
	self.category = Topics.getRandomCategory()
	self.topic = Topics.getRandomTopic(self.category)
	--
	-- set emoticon for topic
	--
	-- get affinities
	self.speakerAffForTarget = self.rChar:getAffinity(self.targetID)
	self.speakerAffForTopic = self.rChar:getAffinity(self.topic)
	self.targetAffForSpeaker = self.rTargetObject:getAffinity(self.speakerID)
	self.targetAffForTopic = self.rTargetObject:getAffinity(self.topic)
	
	assert(self.speakerAffForTarget ~= nil and self.targetAffForSpeaker ~= nil)
	assert(self.speakerAffForTopic ~= nil and self.targetAffForTopic ~= nil)
	
	-- listener indicates reaction
	if self.targetAffForTopic > 0 then
		self.rTargetObject:playAnim('talk_react_positive')
	elseif self.targetAffForTopic < 0 then
		self.rTargetObject:playAnim('talk_react_negative')
	else
		self.rTargetObject:playAnim('talk_listen')
	end
	
	-- set topic icon based on category
	self.topicCategory = Topics.tTopics[self.topic].category
	self.topicIcon = Topics.TopicList[self.topicCategory].emoticon
	self.rChar:setEmoticon(self.topicIcon, Topics.tTopics[self.topic].name, true)
	self.rTargetObject:setEmoticon()
    -- after a short delay, show the speaker's affinity for the topic
	-- they've just introduced
    self.speakerAffEmoticon = self.getAffinityEmoticon(self.speakerAffForTopic)

    -- MTF TODO: REMOVE THIS! timedCallback is too dangerous for use.
	DFUtil.timedCallback(Chat.BANTER_DURATION * 0.275, MOAIAction.ACTIONTYPE_GAMEPLAY, false, function() self:changeAffEmoticon() end)
end

function Chat:changeAffEmoticon()
    if not self.bComplete and self.rChar and self.speakerAffEmoticon then 
        if self.topic == 'Trade' then
	        self.rChar:setEmoticon(self.speakerAffEmoticon, 'Trade'..self.sCharTradeName, true)
        elseif Topics and Topics.tTopics and self.topic and Topics.tTopics[self.topic] then
	        self.rChar:setEmoticon(self.speakerAffEmoticon, Topics.tTopics[self.topic].name, true)
        end
    end
end

function Chat:_respondToTrade()
	self.phase = Chat.PHASE_RESPOND_TO_TRADE
	self.duration = Chat.BANTER_DURATION

    self.rTargetObject:playAnim('talk_speak')
	self.rChar:playAnim('talk_react_positive')

	self.rChar:setEmoticon()
    local icon = self.getAffinityEmoticon(1)
	self.rTargetObject:setEmoticon(icon, 'Trade'..self.sTargetTradeName, true)
end

function Chat:_respondToTopic()
	self.phase = Chat.PHASE_RESPOND
	self.duration = Chat.BANTER_DURATION

    self.rTargetObject:playAnim('talk_speak')
	
	-- listener indicates reaction
	if (self.targetAffForTopic > 0 and self.speakerAffForTopic > 0) or (self.targetAffForTopic < 0 and self.speakerAffForTopic < 0) then
		self.rChar:playAnim('talk_react_positive')
	elseif (self.targetAffForTopic > 0 and self.speakerAffForTopic < 0) or (self.targetAffForTopic < 0 and self.speakerAffForTopic > 0) then
		self.rChar:playAnim('talk_react_negative')
	else
		self.rChar:playAnim('talk_listen')
	end
	
	-- emoticon shows responder's affinity
	self.rChar:setEmoticon()
    local icon = self.getAffinityEmoticon(self.targetAffForTopic)
	self.rTargetObject:setEmoticon(icon, Topics.tTopics[self.topic].name, true)
end

function Chat:_tradeResult()
	self.phase = Chat.PHASE_TRADE_RESULT
	self.duration = Chat.BANTER_DURATION
    self.rChar:playAnim('talk_speak')
    self.rTargetObject:playAnim('talk_speak')
	
	-- apply affinity changes
	self.rChar:addAffinity(self.targetID, 1)
	self.rTargetObject:addAffinity(self.speakerID, 1)
	-- increase familiarity
	self.rChar:addFamiliarity(self.targetID, Character.FAMILIARITY_CHAT)
	self.rTargetObject:addFamiliarity(self.speakerID, Character.FAMILIARITY_CHAT)
	
	self.rChar:setEmoticon(self.getAffChangeEmoticon(1), g_LM.line(Chat.YOU_LINECODE), true)
	self.rTargetObject:setEmoticon(self.getAffChangeEmoticon(1), g_LM.line(Chat.YOU_LINECODE), true)

	-- JLV: For some reason sometimes the item doesn't exist.  Don't complete the trade if that is the case.
    if self.rChar:transferItemTo(self.rTargetObject,self.sCharTradeName) then
    	self.rTargetObject:transferItemTo(self.rChar,self.sTargetTradeName)
    end
	-- spaceface loggin'
	local tLogData = {
		sTradePartner = self.targetName,
		sItemName = self.sTargetTradeName,
		-- maybe mention the item we traded it for
		sOtherItemName = self.sCharTradeName,
	}
	-- char can mention most loved quality of item they're getting from target
	local tItem = self.rChar.tInventory[self.sTargetTradeName]
	-- if there are no notable tags for this object, pick something generic
	-- eg sweet, cool, rad
	local tGenericTags = {
		'SFTRAD002CITZ','SFTRAD003CITZ','SFTRAD004CITZ','SFTRAD005CITZ',
		'SFTRAD006CITZ',
	}
	if tItem then
		local _,tFavTag = self.rChar:getMostLikedTag(tItem)
		if tFavTag then
			tLogData.sFavTag = g_LM.line(tFavTag.lc)
		else
			-- use a generic "neat", "cool", etc
			tLogData.sFavTag = g_LM.line(MiscUtil.randomValue(tGenericTags))
		end
	end
	Log.add(Log.tTypes.CHAT_TRADE, self.rChar, tLogData)
	-- target does same as above for object they're getting from char
	tLogData = {
		sTradePartner = self.speakerName,
		sItemName = self.sCharTradeName,
		sOtherItemName = self.sTargetTradeName,
	}
	tItem = self.rChar.tInventory[self.sCharTradeName]
	if tItem then
		local _,tFavTag = self.rTargetObject:getMostLikedTag(tItem)
		if tFavTag then
			tLogData.sFavTag = g_LM.line(tFavTag.lc)
		else
			tLogData.sFavTag = g_LM.line(MiscUtil.randomValue(tGenericTags))
		end
	end
	Log.add(Log.tTypes.CHAT_TRADE, self.rTargetObject, tLogData)
    -- just for nice outro behavior, like each other a bit more
	self.speakerTargetAffChange = 1
    self.targetSpeakerAffChange = 1
end

function Chat:_topicResult()
	self.phase = Chat.PHASE_RESULT
	self.duration = Chat.BANTER_DURATION
    self.rChar:playAnim('talk_speak')
    self.rTargetObject:playAnim('talk_speak')
	self:_computeResult()
end

function Chat:_computeResult()
	-- get results
	self.speakerTargetAffChange, self.speakerTopicAffChange = self:_getAffChange(self.speakerAffForTopic, self.speakerAffForTarget, self.targetAffForTopic)
	self.targetSpeakerAffChange, self.targetTopicAffChange = self:_getAffChange(self.targetAffForTopic, self.targetAffForSpeaker, self.speakerAffForTopic)
	
	-- apply affinity changes
	self.rChar:addAffinity(self.targetID, self.speakerTargetAffChange)
    self.rChar:addAffinity(self.topic, self.speakerTopicAffChange)

	self.rTargetObject:addAffinity(self.speakerID, self.targetSpeakerAffChange)
	self.rTargetObject:addAffinity(self.topic, self.targetTopicAffChange)
	-- increase familiarity
	self.rChar:addFamiliarity(self.targetID, Character.FAMILIARITY_CHAT)
	self.rTargetObject:addFamiliarity(self.speakerID, Character.FAMILIARITY_CHAT)
	
	-- update morale and log:
	-- "good" conversation: both participants like each other more
	-- "bad" conversation: both participants like each other less
	local tLogData = { sTopic = Topics.getName(self.topic) }
	if self.targetSpeakerAffChange > 0 and self.speakerTargetAffChange > 0 then
		-- speaker
		tLogData.sChatPartner = self.targetName
		Log.add(Log.tTypes.CHAT_GOOD_GENERIC, self.rChar, tLogData)
		self.rChar:alterMorale(Character.MORALE_NICE_CHAT, 'Chat')
        self.rChar:addRoomAffinity(Character.AFFINITY_CHANGE_MINOR)
		-- target
		tLogData.sChatPartner = self.speakerName
		Log.add(Log.tTypes.CHAT_GOOD_GENERIC, self.rTargetObject, tLogData)
		self.rTargetObject:alterMorale(Character.MORALE_NICE_CHAT, 'Chat')
        self.rTargetObject:addRoomAffinity(Character.AFFINITY_CHANGE_MINOR)
	elseif self.targetSpeakerAffChange < 0 and self.speakerTargetAffChange < 0 then
		-- speaker
		tLogData.sChatPartner = self.targetName
		Log.add(Log.tTypes.CHAT_BAD_GENERIC, self.rChar, tLogData)
		self.rChar:alterMorale(Character.MORALE_BAD_CHAT, 'Chat')
        self.rChar:angerEvent( (self.speakerAffForTarget < -.5*Character.STARTING_AFFINITY and Character.ANGER_BAD_CONVO_WITH_JERK) or Character.ANGER_BAD_CONVO_WITH_NORMAL)
        self.rChar:addRoomAffinity(-Character.AFFINITY_CHANGE_MINOR)
		-- target
		tLogData.sChatPartner = self.speakerName
		Log.add(Log.tTypes.CHAT_BAD_GENERIC, self.rTargetObject, tLogData)
		self.rTargetObject:alterMorale(Character.MORALE_BAD_CHAT, 'Chat')
        self.rTargetObject:angerEvent( (self.targetAffForSpeaker < -.5*Character.STARTING_AFFINITY and Character.ANGER_BAD_CONVO_WITH_JERK) or Character.ANGER_BAD_CONVO_WITH_NORMAL)
        self.rTargetObject:addRoomAffinity(-Character.AFFINITY_CHANGE_MINOR)
        -- chance to brawl if conversation went poorly
        -- goals: people with bad tempers should brawl very noticeably more,
        -- brawls should be lots more common than rampages/tantrums
		-- NOTE: this will be run on BOTH characters
        local bShouldBrawl = false
        local function shouldBrawl(rChar, rOther)
            -- the following factors affect chance to brawl:
            -- morale: -100 to 100
			-- allow negative values for positive situations
            local nMoraleChance = -(rChar.tStats.nMorale / Character.MORALE_MAX)
            -- temper: 0 (pacifist) to 1 (raging)
            local nTemperChance = (rChar.tStats.tPersonality.nTemper - 0.5) * 2
            -- anger: 0 to 100
            local nAngerChance = rChar.tStatus.nAnger / Character.ANGER_MAX
            -- affinity: -10 to 10 (tho value can go above/below this)
            local nAffChance = -(rChar:getAffinity(rOther.tStats.sUniqueID) / 10)
            local nChance = (nMoraleChance + nTemperChance + nAngerChance + nAffChance) / 4
			-- halve chance again
			nChance = nChance / 2
            return math.random() < nChance
        end
        bShouldBrawl = shouldBrawl(self.rChar, self.rTargetObject) or shouldBrawl(self.rTargetObject, self.rChar)
        if bShouldBrawl then
            -- register brawlers, log time of brawl start
            -- TODO: make brawlers stop if it's gone on long enough?
			self.rChar:startBrawling(self.rTargetObject)
			self.rTargetObject:startBrawling(self.rChar)
        end
	end
	
	-- show up/down emoticons for both participants showing aff change
    local icon
	if math.abs(self.speakerTargetAffChange) > math.abs(self.speakerTopicAffChange) then
        -- speaker aff change for target
        icon = self.getAffChangeEmoticon(self.speakerTargetAffChange)
		self.rChar:setEmoticon(icon, g_LM.line(Chat.YOU_LINECODE), true)
	elseif math.abs(self.speakerTargetAffChange) < math.abs(self.speakerTopicAffChange) then
        -- speaker aff change for topic
        icon = self.getAffChangeEmoticon(self.speakerTopicAffChange)
		self.rChar:setEmoticon(icon, Topics.tTopics[self.topic].name, true)
	else
        self.rChar:setEmoticon()
    end
	if math.abs(self.targetSpeakerAffChange) > math.abs(self.targetTopicAffChange) then
        -- target aff change for speaker
        icon = self.getAffChangeEmoticon(self.targetSpeakerAffChange)
		self.rTargetObject:setEmoticon(icon, g_LM.line(Chat.YOU_LINECODE), true)
	elseif math.abs(self.targetSpeakerAffChange) < math.abs(self.targetTopicAffChange) then
        -- target aff change for topic
        icon = self.getAffChangeEmoticon(self.targetTopicAffChange)
		self.rTargetObject:setEmoticon(icon, Topics.tTopics[self.topic].name, true)
	else
        self.rTargetObject:setEmoticon()
    end
end

function Chat:_likeHate(value)
	if value < 0 then
		return 'hate'
	else
		return 'like'
	end
end

function Chat:_getAffChange(myAffForTopic, myAffForOther, otherAffForTopic)
	-- given self and another's affinities, return two values for change
	-- to affinity for other and topic.
	-- JPL TODO: change things in different magnitudes based on
	-- context, if we need more drama
	local myTopicAffChange = 0
	local myOtherAffChange = 0
	-- we feel more strongly about topic, change our opinion of other
	if math.abs(myAffForTopic) > math.abs(myAffForOther) then
		-- we like topic
		if myAffForTopic > 0 then
			-- other likes topic; we like them more
			if otherAffForTopic > 0 then
				myOtherAffChange = 1
			-- other dislikes topic; we like them less
			elseif otherAffForTopic < 0 then
				myOtherAffChange = -1
			end
		-- we dislike topic
		elseif myAffForTopic < 0 then
			-- other likes topic; we like them less
			if otherAffForTopic > 0 then
				myOtherAffChange = -1
			-- other dislikes topic; we like them more
			elseif otherAffForTopic < 0 then
				myOtherAffChange = 1
			end
		end
		-- weight topics vs people differently
		myOtherAffChange = myOtherAffChange * Character.THING_WEIGHT
	-- we feel more strongly about other, change our opinion of topic
	elseif math.abs(myAffForTopic) < math.abs(myAffForOther) then
		-- we like other
		if myAffForOther > 0 then
			-- other likes topic; we like it more
			if otherAffForTopic > 0 then
				myTopicAffChange = 1
			-- other dislikes topic; we like it less
			elseif otherAffForTopic < 0 then
				myTopicAffChange = -1
			end
		-- we dislike other
		elseif myAffForOther < 0 then
			-- other likes topic; we like it less
			if otherAffForTopic > 0 then
				myTopicAffChange = -1
			-- other dislikes topic; we like it more
			elseif otherAffForTopic < 0 then
				myTopicAffChange = 1
			end
		end
	end
	return myOtherAffChange, myTopicAffChange
end

function Chat:_outro()
	self.phase = Chat.PHASE_OUTRO
	self.duration = Chat.OUTRO_DURATION
	local bNiceChat = false
	-- parting anim shows how they feel about one another
	-- JPL TODO: find a place where 'become_friends' anim is appropriate
	if self.speakerTargetAffChange > 0 then
		self.rChar:playAnim('talk_bye_positive')
		bNiceChat = true
	elseif self.speakerTargetAffChange < 0 then
		self.rChar:playAnim('talk_bye_negative')
	else
		self.rChar:playAnim('talk_bye')
	end
	if self.targetSpeakerAffChange > 0 then
		self.rTargetObject:playAnim('talk_bye_positive')
		bNiceChat = true
	elseif self.targetSpeakerAffChange < 0 then
		self.rTargetObject:playAnim('talk_bye_negative')
	else
		self.rTargetObject:playAnim('talk_bye')
	end
	self.rChar:setEmoticon(nil, g_LM.line(Chat.BYE_LINECODE), true)
	self.rTargetObject:setEmoticon(nil, g_LM.line(Chat.BYE_LINECODE), true)
	-- if you're sad, talking to a happy person makes you a little happier
	if bNiceChat then
		if self.rTargetObject.tStats.nMorale > 0 and self.rChar.tStats.nMorale < 0 then
			-- speaker morale increase based on how happy target is
			local nBonus = self.rTargetObject.tStats.nMorale / Character.MORALE_MAX
			nBonus = DFMath.lerp(Character.MORALE_HAPPY_CHAT_BASE, Character.MORALE_HAPPY_CHAT_MAX, nBonus)
			self.rChar:alterMorale(nBonus, 'HappyChat')
			Log.add(Log.tTypes.CHAT_CHEER_UP, self.rChar, {sChatPartner=self.targetName})
		elseif self.rChar.tStats.nMorale > 0 and self.rTargetObject.tStats.nMorale < 0 then
			-- target morale increase based on how happy speaker is
			local nBonus = self.rChar.tStats.nMorale / Character.MORALE_MAX
			nBonus = DFMath.lerp(Character.MORALE_HAPPY_CHAT_BASE, Character.MORALE_HAPPY_CHAT_MAX, nBonus)
			self.rTargetObject:alterMorale(nBonus, 'HappyChat')
			Log.add(Log.tTypes.CHAT_CHEER_UP, self.rTargetObject, {sChatPartner=self.speakerName})
		end
	end
end

function Chat:_finishChat()
    self.rChar:playAnim('breathe')
    self.rTargetObject:playAnim('breathe')
	self.rChar:setEmoticon()
	self.rTargetObject:setEmoticon()
	-- set memory
	local time = GameRules.elapsedTime
	if not self.rChar.tMemory.tTaskChat then
		self.rChar.tMemory.tTaskChat = {}
	end
	if not self.rTargetObject.tMemory.tTaskChat then
		self.rTargetObject.tMemory.tTaskChat = {}
	end
	self.rChar.tMemory.tTaskChat.sPartnerID = self.rTargetObject.tStats.sUniqueID
	self.rTargetObject.tMemory.tTaskChat.sPartnerID = self.rChar.tStats.sUniqueID
	self.rChar.tMemory.tTaskChat.lastTime = time
	self.rTargetObject.tMemory.tTaskChat.lastTime = time
	self:complete()
end

function Chat:_forceChat(duration)
    if not self.bChatting then
        self:_startChat()
    end
end

function Chat:onComplete(bSuccess)
    Task.onComplete(self, bSuccess)
    self.rChar:playAnim('breathe')
    self.rTargetObject:chatComplete(self.rChar, bSuccess)
end

-- override from Task
function Chat:dismissEmoticon()
	if not self.bChatting then
		Task.dismissEmoticon(self)
	end
end

function Chat:_enteredNewTile()
    Task._enteredNewTile(self)
end

function Chat:_followTarget(dt)
    local bValid, sFailure = self:_testStillValid()
    if not bValid then
        self:interrupt(sFailure)
        return
    end
    if self:_hackyFollowTimeoutTest(dt) then
        self:interrupt('timed out attempting to chat with target')
        return
    end
    if self.tPath then
        if self:tickWalk(dt) then
            self.tPath = nil
            self.rChar:playAnim('breathe')
        end
    elseif self:_isTargetAdjacent() then
        self:_testChat()
    end
end

function Chat:onUpdate(dt)
    if self.bChatting then
        self.duration = self.duration - dt
        if self.duration < 0 then
			self:_nextChatPhase()
        end
    else
        self:_followTarget(dt)
    end
end

function Chat:_newTrade()
    local nBestTradeDiff=2
    local sBestTradeKeyChar,sBestTradeKeyTarget
    for sCharKey,tCharItem in pairs(self.rChar.tInventory) do
        for sTargetKey,tTargetItem in pairs(self.rTargetObject.tInventory) do
            -- does rChar like tTargetItem better than they like tCharItem?
            local nDiffChar = self.rChar:getObjectAffinity(tTargetItem) - self.rChar:getObjectAffinity(tCharItem)
            -- does rTargetObject like tCharItem better than they like tTargetItem?
            local nDiffTarget = self.rTargetObject:getObjectAffinity(tCharItem) - self.rChar:getObjectAffinity(tTargetItem)
            if nDiffTarget > 0 and nDiffChar > 0 then
                -- each char thinks they'd be better off with the other item.
                if nBestTradeDiff < nDiffChar+nDiffTarget then
                    nBestTradeDiff = nDiffChar+nDiffTarget
                    sBestTradeKeyChar = sCharKey
                    sBestTradeKeyTarget = sTargetKey
                    self.sCharTradeName = tCharItem.sName
                    self.sTargetTradeName = tTargetItem.sName
                end
            end
        end
    end

    if not sBestTradeKeyChar then return false end

	self.phase = Chat.PHASE_START_TRADE
	self.duration = Chat.BANTER_DURATION
    self.rChar:playAnim('talk_speak')
    self.sBestTradeKeyChar = sBestTradeKeyChar
    self.sBestTradeKeyTarget = sBestTradeKeyTarget
	self.rTargetObject:playAnim('talk_react_positive')
	self.topicIcon = Topics.TopicList['Activities'].emoticon
	self.rChar:setEmoticon(self.topicIcon, g_LM.line('UITASK077TEXT')..' '..self.sCharTradeName, true)
	self.rTargetObject:setEmoticon()
    -- after a short delay, show the speaker's affinity for the topic
	-- they've just introduced
    self.speakerAffEmoticon = self.getAffinityEmoticon(1)

    -- MTF TODO: REMOVE THIS! timedCallback is too dangerous for use.
	DFUtil.timedCallback(Chat.BANTER_DURATION * 0.275, MOAIAction.ACTIONTYPE_GAMEPLAY, false, function() self:changeAffEmoticon() end)

    return true
end

function Chat.getAffinityEmoticon( affinity )
    if affinity > 0 then
        return 'thumbsup'
    else
        return 'thumbsdown'
    end
end

function Chat.getAffChangeEmoticon( change )
    if change > 0 then
        return 'arrowup'
    else
        return 'arrowdown'
    end
end

return Chat
