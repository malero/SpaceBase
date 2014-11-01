local Class = require('Class')
local MiscUtil = require('MiscUtil')
local Character = require('CharacterConstants')

local Topics = Class.create(nil)

Topics.initialized = false
Topics.counter = 0

Topics.DEFAULT_INITIAL_TOPICS = 10

-- NOTE: TopicList and tActivities declared at bottom

function Topics.initializeTopicList()
	Topics.tTopics = {}
    Topics.tTopicsByCategory = {}
    for category,tData in pairs(Topics.TopicList) do
        Topics.tTopicsByCategory[category] = {}
		-- some topics compile topic lists specially
		if tData.listGeneratorFn then
			tData.listGeneratorFn()
		else
            local quota = tData.initialNumber or Topics.DEFAULT_INITIAL_TOPICS
			Topics.generateGenericList(quota, category)
		end
    end
    Topics.initialized = true
end

function Topics.dumpTopics()
	print('-----------------------')
	print('global topics list')
	print('-----------------------')
	for id,tData in pairs(Topics.tTopics) do
		print(id..' ('..tData.category..'): '..tData.name)
	end
	print('-----------------------')
end

function Topics.dumpTopic(topicName)
	print('-----------------------')
	print('list of '..topicName)
	print('-----------------------')
	for id,tData in pairs(Topics.tTopics) do
		if tData.category == topicName then
			print('"'..tData.name..'"')
		end
	end
	print('-----------------------')
end

function Topics.generatePeopleList()
	-- this should only be run for initial population, so no need to
	-- check the lists of non-owned or dead characters?
    local tChars = require('CharacterManager').getCharacters()
    for _,char in pairs(tChars) do
        if not Topics.tTopics[char.tStats.sUniqueID] then
            Topics.addTopic('People', char.tStats.sUniqueID)
        end
    end
end

function Topics.getTopicForActivity(sActivityName)
	-- returns a topic name/ID for the given activity, if one exists
	for id,tData in pairs(Topics.tActivities) do
		for _,activity in pairs(tData.tActivities) do
			if sActivityName == activity then
				return id
			end
		end
	end
end

function Topics.fromSaveData(tSaveData)
    Topics.tTopics = tSaveData.tTopics or {}
    
    Topics.tTopicsByCategory = {}
    for sID,tData in pairs(Topics.tTopics) do
        if not Topics.tTopicsByCategory[tData.category] then Topics.tTopicsByCategory[tData.category] = {} end
        table.insert(Topics.tTopicsByCategory[tData.category], sID)
    end
end

function Topics.generateActivityList()
	-- adds everything in Topics.tActivities to the global topics list
	for id,_ in pairs(Topics.tActivities) do
		-- only if it's not already in there
		if not Topics.tTopics[id] then
			Topics.addTopic('Activities', id)
		end
	end
end

function Topics.generateDutyList()
	for _,nJob in pairs(Character.tJobs) do
		local nJobName = g_LM.line(Character.JOB_NAMES[nJob])
		if not Topics.tTopics[nJobName] then
			Topics.addTopic('Duties', nJobName)
		end
	end
end

function Topics.generateGenericList(quota, category)
	for i=1,quota do
		Topics.addTopic(category)
	end
end

function Topics.getUniqueID(name)
	Topics.counter = Topics.counter + 1
	return name .. Topics.counter
end

function Topics.addTopic(sCategoryName, sID)
	if not Topics.TopicList[sCategoryName] then
		Print(TT_Warning, 'Topics.addTopic: category '..sCategoryName..' not found.')
		return
	end
	local category = Topics.TopicList[sCategoryName]
	-- for people, citizen ID is passed in, derive name
	local sName
	if sCategoryName == 'People' and sID then
		local rChar = require('CharacterManager').getCharacterByUniqueID(sID)
		assertdev(rChar ~= nil)
		if not rChar then
			return
		end
		sName = rChar.tStats.sName
		if not sName then
			Print(TT_Warning, 'Topics.addTopic: citizen ID '..sID..' not found.')
			return
		end
	elseif sCategoryName == 'Activities' then
		sName = g_LM.line(Topics.tActivities[sID].sNameLC)
	elseif sCategoryName == 'Duties' then
		-- add ' duty' for chat speech bubble clarity
		sName = sID .. ' ' .. g_LM.line('TOPICS005TEXT')
		sID = 'DUTY_' .. sID
	elseif category.nameGeneratorFn then
		-- generate a new name + ID if one isn't provided
		sName = category.nameGeneratorFn()
        -- ensure name is unique
        while Topics.alreadyInList(sName) do
            sName = category.nameGeneratorFn()
        end
		sID = Topics.getUniqueID(sName)
	end
	Topics.tTopics[sID] = {name=sName, category=sCategoryName}
    if not Topics.tTopicsByCategory[sCategoryName] then Topics.tTopicsByCategory[sCategoryName] = {} end
    table.insert(Topics.tTopicsByCategory[sCategoryName], sID)
	-- add to everyone's affinity map
	Topics.generateAffinitiesFor(sID)
end

function Topics.generateAffinitiesFor(topicID)
    local tChars = require('CharacterManager').getCharacters()
    for _,rChar in pairs(tChars) do
		rChar:generateAffinityFor(topicID)
    end
end

function Topics.generateCharacterAffinities(rChar)
	for topic,tData in pairs(Topics.tTopics) do
        if not rChar.tAffinity[topic] then
            rChar:generateAffinityFor(topic)
        end
	end
end

function Topics.alreadyInList(name)
	for _,tData in pairs(Topics.tTopics) do
		if tData.name == name then
			return true
		end
	end
	return false
end

function Topics.getRandomCategory()
    return MiscUtil.randomKey(Topics.tTopicsByCategory)
end

function Topics.getRandomTopic(sCategory)
    if sCategory then
        assertdev(Topics.tTopicsByCategory[sCategory] and #Topics.tTopicsByCategory[sCategory] > 0)
        if not (Topics.tTopicsByCategory[sCategory] and #Topics.tTopicsByCategory[sCategory] > 0) then
            sCategory = nil
        end
    end
    if not sCategory then
        -- if no category given, return a purely random topic
        return MiscUtil.randomKey(Topics.tTopics)
    end
    return MiscUtil.randomValue(Topics.tTopicsByCategory[sCategory])
end

function Topics.numberOfCategories()
	local i = 0
	for _,category in pairs(Topics.TopicList) do
		i = i + 1
	end
	return i
end

function Topics.getName(topic)
	return Topics.tTopics[topic].name
end

--
-- generator functions
--

function Topics.generateBandName()
	-- [the] [adjective] noun (singular or plural)
    local name = ''
    if math.random() < 0.25 then
        name = 'The '
    end
    if math.random() < 0.5 then
        name = name .. g_LM.randomLine(Topics.BandNameAdjectives) .. ' '
    end
    name = name .. g_LM.randomLine(Topics.BandNameNouns)
    return name
end

function Topics.generateFoodName()
	-- [provenance] [prep method] [adjective] ingredient [dish type]
	local name = ''
    local nFoodDescriptors = 0 -- to keep text from getting too long
	if math.random() < 0.25 then
		name = g_LM.randomLine(Topics.FoodProvenance) .. ' '
        nFoodDescriptors = nFoodDescriptors + 1
	end
	if math.random() < 0.4 then
		name = name .. g_LM.randomLine(Topics.FoodPrepMethods) .. ' '
        nFoodDescriptors = nFoodDescriptors + 1
	end
    if nFoodDescriptors < 2 then
        if math.random() < 0.2 then
            name = name .. g_LM.randomLine(Topics.FoodAdjectives) .. ' '
            nFoodDescriptors = nFoodDescriptors + 1
        end
    end
    
	-- always have a "key ingredient"
	name = name .. g_LM.randomLine(Topics.FoodKeyIngredients) .. ' '
    
    if nFoodDescriptors == 0 then -- force a descriptor if none
        name = name .. g_LM.randomLine(Topics.FoodDishes)
    elseif nFoodDescriptors < 2 then
        if math.random() < 0.5 then
            name = name .. g_LM.randomLine(Topics.FoodDishes)
        end
    end
	-- snip space at end
	if name:find(' ', -1) then
		name = name:sub(1, #name-1)
	end
	return name
end

function Topics.generateDrinkName()
	-- beer: provenance + beer type
	-- cocktail: adjective [adjective] noun
	local BEER_CHANCE = 0.5
	if math.random() < BEER_CHANCE then
		local sPlace = Topics.getRandomProvenance()
		local sType = g_LM.randomLine(Topics.BeerTypes)
		return sPlace .. ' ' .. sType
	else
		local adj = g_LM.randomLine(Topics.CocktailAdjectives)
		-- small chance for extra adjective
		if math.random() < 0.1 then
			adj = adj .. ' ' .. g_LM.randomLine(Topics.CocktailAdjectives)
		end
		local noun = g_LM.randomLine(Topics.CocktailNouns)
		return adj .. ' ' .. noun
	end
end

function Topics.generateCreatureName()
	-- goofy random space creature name
	-- pattern: [provenance] [adjective] [descriptor] noun
	local s = ''
	-- pick at least one provenance, adjective, descriptor, or noun
	while string.len(s) == 0 do
		if math.random() > 0.4 then
			s = s .. Topics.getRandomProvenance() .. ' '
		end
		if math.random() > 0.5 then
			s = s .. g_LM.randomLine(Topics.CreatureAdjectives) .. ' '
		end
		if math.random() > 0.6 then
			s = s .. g_LM.randomLine(Topics.CreatureDescriptors) .. ' '
		end
	end
	s = s .. g_LM.randomLine(Topics.CreatureNouns)
	return s
end

function Topics.getRandomProvenance()
	return g_LM.randomLine(Topics.FoodProvenance)
end

function Topics.testGenerator(genFn, count)
	local count = count or 10
	for i=1,count do
		print(genFn())
	end
end

--
-- random name ingredients
--

-- band names
Topics.BandNameAdjectives={'TBANDS001TEXT','TBANDS002TEXT','TBANDS003TEXT','TBANDS004TEXT','TBANDS005TEXT','TBANDS006TEXT','TBANDS007TEXT',
    'TBANDS008TEXT','TBANDS009TEXT','TBANDS010TEXT','TBANDS011TEXT','TBANDS012TEXT','TBANDS013TEXT','TBANDS014TEXT','TBANDS015TEXT',
    'TBANDS016TEXT','TBANDS017TEXT','TBANDS018TEXT','TBANDS034TEXT','TBANDS035TEXT','TBANDS036TEXT','TBANDS038TEXT','TBANDS039TEXT',}
Topics.BandNameNouns={'TBANDS019TEXT','TBANDS020TEXT','TBANDS021TEXT','TBANDS022TEXT','TBANDS023TEXT','TBANDS024TEXT','TBANDS025TEXT',
    'TBANDS026TEXT','TBANDS027TEXT','TBANDS028TEXT','TBANDS029TEXT','TBANDS030TEXT','TBANDS031TEXT','TBANDS032TEXT','TBANDS033TEXT',
    'TBANDS037TEXT','TBANDS040TEXT','TBANDS041TEXT','TBANDS042TEXT','TBANDS043TEXT'}

-- foods
Topics.FoodPrepMethods={'TFOODS001TEXT','TFOODS002TEXT','TFOODS003TEXT','TFOODS004TEXT','TFOODS005TEXT','TFOODS006TEXT','TFOODS007TEXT',
    'TFOODS009TEXT','TFOODS010TEXT','TFOODS011TEXT','TFOODS012TEXT','TFOODS014TEXT','TFOODS015TEXT',
    'TFOODS016TEXT','TFOODS017TEXT','TFOODS018TEXT','TFOODS019TEXT','TFOODS020TEXT','TFOODS021TEXT',}
Topics.FoodAdjectives={'TFOODS022TEXT','TFOODS023TEXT','TFOODS024TEXT','TFOODS025TEXT','TFOODS026TEXT','TFOODS027TEXT','TFOODS028TEXT',
    'TFOODS029TEXT','TFOODS030TEXT','TFOODS031TEXT','TFOODS032TEXT',}
Topics.FoodProvenance={'TFOODS033TEXT','TFOODS034TEXT','TFOODS035TEXT','TFOODS036TEXT', 'TFOODS079TEXT', 'TFOODS080TEXT', 'TFOODS081TEXT',
					   'TFOODS084TEXT','TFOODS085TEXT','TFOODS086TEXT','TFOODS087TEXT','TFOODS088TEXT', 'TFOODS089TEXT', }
Topics.FoodKeyIngredients={'TFOODS037TEXT','TFOODS038TEXT','TFOODS039TEXT','TFOODS040TEXT','TFOODS041TEXT','TFOODS042TEXT','TFOODS043TEXT',
    'TFOODS044TEXT','TFOODS045TEXT','TFOODS046TEXT','TFOODS047TEXT','TFOODS048TEXT','TFOODS049TEXT','TFOODS050TEXT','TFOODS051TEXT',
    'TFOODS075TEXT','TFOODS076TEXT','TFOODS077TEXT','TFOODS078TEXT','TFOODS082TEXT','TFOODS083TEXT', }
Topics.FoodDishes={'TFOODS052TEXT','TFOODS053TEXT', 'TFOODS054TEXT','TFOODS055TEXT','TFOODS056TEXT','TFOODS057TEXT','TFOODS058TEXT',
    'TFOODS059TEXT','TFOODS060TEXT','TFOODS061TEXT','TFOODS062TEXT','TFOODS063TEXT', 'TFOODS064TEXT','TFOODS065TEXT','TFOODS066TEXT',
    'TFOODS067TEXT','TFOODS068TEXT','TFOODS069TEXT','TFOODS070TEXT','TFOODS071TEXT','TFOODS072TEXT','TFOODS073TEXT','TFOODS074TEXT',}

-- game names
Topics.GameNames={'TGAMES001TEXT','TGAMES002TEXT','TGAMES003TEXT','TGAMES004TEXT','TGAMES005TEXT','TGAMES006TEXT','TGAMES007TEXT',
    'TGAMES008TEXT','TGAMES009TEXT','TGAMES010TEXT','TGAMES011TEXT','TGAMES012TEXT','TGAMES013TEXT','TGAMES014TEXT','TGAMES015TEXT',
    'TGAMES016TEXT','TGAMES017TEXT','TGAMES018TEXT','TGAMES019TEXT','TGAMES020TEXT','TGAMES021TEXT','TGAMES022TEXT','TGAMES023TEXT',
}

-- drink names
Topics.BeerTypes={'TDRINK001TEXT', 'TDRINK002TEXT', 'TDRINK003TEXT', 'TDRINK004TEXT', 'TDRINK005TEXT', 'TDRINK006TEXT'}
Topics.CocktailAdjectives={'TDRINK007TEXT', 'TDRINK008TEXT', 'TDRINK009TEXT', 'TDRINK010TEXT', 'TDRINK011TEXT'}
Topics.CocktailNouns={'TDRINK012TEXT', 'TDRINK013TEXT', 'TDRINK014TEXT', 'TDRINK015TEXT', 'TDRINK016TEXT'}

-- creature names
Topics.CreatureAdjectives={
	'TCREAT005TEXT','TCREAT006TEXT','TCREAT007TEXT','TCREAT012TEXT','TCREAT013TEXT',
	'TCREAT014TEXT','TCREAT015TEXT','TCREAT021TEXT','TCREAT022TEXT',
}
Topics.CreatureDescriptors={
	'TCREAT001TEXT','TCREAT008TEXT','TCREAT009TEXT','TCREAT019TEXT','TCREAT020TEXT',
	'TCREAT023TEXT','TCREAT024TEXT','TCREAT027TEXT','TCREAT028TEXT','TCREAT030TEXT',
}
Topics.CreatureNouns={
	'TCREAT002TEXT','TCREAT003TEXT','TCREAT004TEXT','TCREAT010TEXT','TCREAT011TEXT',
	'TCREAT016TEXT','TCREAT017TEXT','TCREAT018TEXT','TCREAT025TEXT','TCREAT026TEXT',
	'TCREAT029TEXT','TCREAT031TEXT',
}

Topics.ACTIVITY_WALKING = 'Walking'
Topics.ACTIVITY_DRINKING = 'Drinking'
Topics.ACTIVITY_EXERCISE = 'Exercise'
Topics.ACTIVITY_GAMING = 'Gaming'

-- activities we can have affinity for:
-- values are a list of Task class names; a single hobby-like behavior can be
-- comprised of multiple activities/tasks
Topics.tActivities = 
{
	[Topics.ACTIVITY_WALKING] = {
		sNameLC = 'TOPICS001TEXT',
		tActivities = {'WanderAround',},
	},
	[Topics.ACTIVITY_DRINKING] = {
		sNameLC = 'TOPICS004TEXT',
		tActivities = {'GetDrink',},
	},
	[Topics.ACTIVITY_EXERCISE] = {
		sNameLC = 'TOPICS002TEXT',
		tActivities = {'WorkOutNoGym','WorkOutInGym','LiftAtWeightBench',},
	},
	[Topics.ACTIVITY_GAMING] = {
		sNameLC = 'TOPICS003TEXT',
		tActivities = {'PlayGameSystem',},
	},
}

Topics.TopicList=
{
    People=
    {
		listGeneratorFn = Topics.generatePeopleList,
		emoticon = 'topic_person',
    },
    Bands=
    {
        initialNumber = 12,
        nameGeneratorFn = Topics.generateBandName,
		emoticon = 'topic_band',
		bCanGenerateOnImmigration = true,
    },
    Foods=
    {
        nameGeneratorFn = Topics.generateFoodName,
		emoticon = 'topic_food',
		bCanGenerateOnImmigration = true,
    },
	Activities=
	{
		listGeneratorFn = Topics.generateActivityList,
		emoticon = 'topic_person',
	},
	Duties=
	{
		listGeneratorFn = Topics.generateDutyList,
		emoticon = 'topic_person',
	}
}

return Topics
