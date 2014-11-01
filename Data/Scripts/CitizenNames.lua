local DFUtil = require('DFCommon.Util')
local MiscUtil = require('MiscUtil')
local Character = require('CharacterConstants')
local CharacterManager = require('CharacterManager')

local CitizenNames = {

tHumanFirstNames_Female = { "NAMESX001TEXT", "NAMESX002TEXT", "NAMESX003TEXT", "NAMESX004TEXT", "NAMESX005TEXT", "NAMESX006TEXT", "NAMESX007TEXT", "NAMESX008TEXT",
"NAMESX009TEXT","NAMESX010TEXT","NAMESX011TEXT","NAMESX012TEXT", "NAMESX013TEXT", "NAMESX014TEXT", "NAMESX015TEXT", "NAMESX016TEXT", "NAMESX017TEXT",
"NAMESX018TEXT","NAMESX019TEXT","NAMESX020TEXT","NAMESX021TEXT","NAMESX138TEXT", "NAMESX141TEXT","NAMESX142TEXT","NAMESX143TEXT","NAMESX147TEXT",
"NAMESX144TEXT","NAMESX145TEXT","NAMESX149TEXT",
},

tHumanFirstNames_Male = { "NAMESX022TEXT", "NAMESX023TEXT","NAMESX024TEXT","NAMESX025TEXT","NAMESX026TEXT","NAMESX027TEXT","NAMESX028TEXT","NAMESX029TEXT",
"NAMESX030TEXT","NAMESX031TEXT","NAMESX032TEXT", "NAMESX033TEXT","NAMESX034TEXT","NAMESX035TEXT","NAMESX036TEXT","NAMESX037TEXT","NAMESX038TEXT",
"NAMESX039TEXT","NAMESX040TEXT","NAMESX041TEXT","NAMESX042TEXT", "NAMESX043TEXT","NAMESX044TEXT","NAMESX045TEXT","NAMESX046TEXT","NAMESX047TEXT","NAMESX048TEXT",
"NAMESX049TEXT","NAMESX050TEXT","NAMESX051TEXT","NAMESX052TEXT", "NAMESX053TEXT","NAMESX054TEXT","NAMESX055TEXT","NAMESX056TEXT","NAMESX057TEXT","NAMESX058TEXT",
"NAMESX059TEXT","NAMESX060TEXT","NAMESX061TEXT","NAMESX062TEXT", "NAMESX063TEXT","NAMESX064TEXT","NAMESX065TEXT","NAMESX066TEXT","NAMESX067TEXT","NAMESX068TEXT",
"NAMESX069TEXT","NAMESX070TEXT","NAMESX071TEXT","NAMESX072TEXT", "NAMESX073TEXT","NAMESX118TEXT","NAMESX139TEXT","NAMESX140TEXT","NAMESX146TEXT",
"NAMESX148TEXT","NAMESX150TEXT","NAMESX151TEXT","NAMESX152TEXT",
},

tHumanLastNames =
{ "NAMESX074TEXT","NAMESX075TEXT","NAMESX076TEXT","NAMESX077TEXT","NAMESX078TEXT","NAMESX079TEXT","NAMESX080TEXT","NAMESX081TEXT","NAMESX082TEXT",
 "NAMESX083TEXT","NAMESX084TEXT","NAMESX085TEXT","NAMESX086TEXT","NAMESX087TEXT","NAMESX088TEXT","NAMESX089TEXT","NAMESX090TEXT","NAMESX091TEXT",
 "NAMESX092TEXT", "NAMESX093TEXT","NAMESX094TEXT","NAMESX095TEXT","NAMESX096TEXT","NAMESX097TEXT","NAMESX098TEXT","NAMESX099TEXT","NAMESX100TEXT",
 "NAMESX101TEXT","NAMESX102TEXT", "NAMESX103TEXT","NAMESX104TEXT","NAMESX105TEXT","NAMESX106TEXT","NAMESX107TEXT","NAMESX108TEXT","NAMESX109TEXT",
 "NAMESX110TEXT","NAMESX111TEXT","NAMESX112TEXT", "NAMESX113TEXT","NAMESX114TEXT","NAMESX115TEXT","NAMESX116TEXT","NAMESX117TEXT", "NAMESX262TEXT",
 "NAMESX263TEXT","NAMESX264TEXT","NAMESX265TEXT", "NAMESX266TEXT","NAMESX267TEXT","NAMESX268TEXT","NAMESX269TEXT","NAMESX270TEXT", "NAMESX271TEXT",
 "NAMESX272TEXT","NAMESX273TEXT","NAMESX274TEXT", "NAMESX275TEXT","NAMESX276TEXT","NAMESX277TEXT","NAMESX278TEXT","NAMESX279TEXT", "NAMESX280TEXT",
 "NAMESX281TEXT","NAMESX282TEXT","NAMESX283TEXT", "NAMESX284TEXT","NAMESX285TEXT","NAMESX286TEXT","NAMESX287TEXT","NAMESX288TEXT", "NAMESX289TEXT",
 "NAMESX290TEXT","NAMESX291TEXT","NAMESX292TEXT", "NAMESX293TEXT","NAMESX294TEXT","NAMESX295TEXT","NAMESX296TEXT","NAMESX297TEXT", "NAMESX298TEXT",
 "NAMESX299TEXT","NAMESX300TEXT","NAMESX301TEXT", "NAMESX302TEXT","NAMESX303TEXT","NAMESX304TEXT",
},

tBirdSharkNames = { "NAMESX154TEXT", "NAMESX155TEXT","NAMESX156TEXT","NAMESX157TEXT","NAMESX158TEXT","NAMESX159TEXT","NAMESX160TEXT",
    "NAMESX161TEXT","NAMESX162TEXT","NAMESX163TEXT","NAMESX164TEXT","NAMESX165TEXT","NAMESX166TEXT","NAMESX167TEXT","NAMESX168TEXT",
    "NAMESX169TEXT","NAMESX170TEXT","NAMESX171TEXT",
},

tChickenNames_Female = { "NAMESX172TEXT","NAMESX174TEXT", "NAMESX175TEXT","NAMESX176TEXT","NAMESX177TEXT","NAMESX181TEXT","NAMESX250TEXT",
},

tChickenNames_Male = { "NAMESX173TEXT","NAMESX178TEXT","NAMESX179TEXT",
    "NAMESX180TEXT","NAMESX182TEXT","NAMESX183TEXT","NAMESX184TEXT",
},

tCatFirstNames_Male = { "NAMESX185TEXT","NAMESX187TEXT","NAMESX191TEXT","NAMESX192TEXT","NAMESX193TEXT","NAMESX194TEXT","NAMESX195TEXT","NAMESX196TEXT","NAMESX197TEXT","NAMESX199TEXT","NAMESX200TEXT",
},

tCatFirstNames_Female = { "NAMESX186TEXT","NAMESX188TEXT","NAMESX189TEXT","NAMESX190TEXT","NAMESX198TEXT","NAMESX201TEXT","NAMESX324TEXT","NAMESX325TEXT","NAMESX326TEXT",
},

tCatLastNames = { "NAMESX319TEXT","NAMESX320TEXT","NAMESX321TEXT","NAMESX322TEXT","NAMESX323TEXT",
},

tJellyFirstNames = { "NAMESX203TEXT","NAMESX205TEXT","NAMESX206TEXT","NAMESX208TEXT","NAMESX209TEXT","NAMESX210TEXT","NAMESX211TEXT","NAMESX213TEXT","NAMESX214TEXT","NAMESX216TEXT","NAMESX217TEXT",
},

tJellyLastNames = { "NAMESX202TEXT","NAMESX204TEXT","NAMESX207TEXT","NAMESX212TEXT","NAMESX215TEXT","NAMESX218TEXT","NAMESX219TEXT","NAMESX220TEXT","NAMESX221TEXT","NAMESX316TEXT","NAMESX317TEXT","NAMESX318TEXT",
},

tShamonLastNames = { 'NAMESX327TEXT','NAMESX328TEXT','NAMESX329TEXT','NAMESX330TEXT','NAMESX331TEXT','NAMESX332TEXT','NAMESX333TEXT','NAMESX334TEXT',
    'NAMESX335TEXT','NAMESX336TEXT','NAMESX337TEXT','NAMESX338TEXT','NAMESX339TEXT',
},

tTobianNames = { "NAMESX246TEXT","NAMESX247TEXT","NAMESX248TEXT","NAMESX249TEXT","NAMESX251TEXT","NAMESX252TEXT","NAMESX305TEXT","NAMESX306TEXT",
    "NAMESX307TEXT","NAMESX308TEXT","NAMESX309TEXT","NAMESX310TEXT","NAMESX311TEXT","NAMESX312TEXT","NAMESX313TEXT","NAMESX314TEXT","NAMESX315TEXT",
},

--
-- easter egg names: don't bother with linecodes
--
tEasterEggNames_Female = {
    'Su Liu', 'Kristen Russell', 'Isa Stamos', 'Tonya Hickman', 'Say Oh',
    'Morgan Webb', 'Noelle', 'Heidi Hokka', 'Jenn', 'Lovisa Hansén',
    'Kati Dycus', 'Fierre Mallow', 'Velicitia', "Kexel O'bscene",
    'Cadance Lilystrobe', 'Lucy McCallum', 'Lisa Shearman',
    'Marie-France Tessier', 'Paz Ortega Andrade', 'Caro Ilott',
    'Skye Arkima', 'Steph Gibbs', 'Jaima Libeau', 'Kana-san',
    'Reptarella', 'Heather Quinnell', 'Mimness', 'Jenni', 'Claire Bradshaw',
	'Jennifer McMurray',
},

tEasterEggNames_Male = {
    'Gabe Miller', 'Jeremy Mitchell', 'Ben Burbank', 'JP LeBreton', 'Patrick Connor',
    'Jeremy Natividad', 'Chris Remo', 'Matt Franklin', 'Kee Chi', 'Justin Bailey',
    'Tim Schafer', 'Greg Rice', 'Matt Hansen', 'Anthony Vaughn', 'Derek Brand',
    'Razmig Mavlian', 'Stefan Gagne', 'Klink', 'Brendan Sinclair', 'Levi Loftis',
    'Finis', 'Frederik Storm', 'Ray Crook', 'Elliott Roberts', 'Andy Wood',
    'Brian Min', 'Brian Correia', 'Juuso Haimilahti', 'Jes Golka',
    'Vicente Toppington', 'Jeffrey Rosen', 'Frank Aetheria', 'Dustin Noah Brady',
    'TLM3101', 'Will Hudson', 'Madman', 'Mike Klamerus', 'Dominique Dubois',
    'Salem Jericho', 'Tim Lewis', 'Sam Courtney',
    'Malek Annabi', '$M.I.G$', 'Mathias Smythe', 'Jon Caldwell', 'Brian Hseih',
    'Jason Christensen', 'Mike Weldon', 'Angelo "Peps" Pepe', 'Matt Turvey',
    'Doug Tabacco', 'Dimitri Roche', 'GOODYBOY', 'JingQI',
    'Yegor Myronenko', 'Jesse Clark', 'Casebeer', 'Jäg Ermaestro', 'ElementCy',
    'Nicholas Wogberg', 'Charlie Hoyt', 'Brenton Dick',
    'Justin "NeoWulf" Smith', 'Jonathon Bowyer', 'Bryce Whitty',
    'Arne Roomann-Kurrik', 'Brian Haucke', 'James Mitchell', 'Maarten Degenhart',
    'Wolfram Riedel', 'Andreas Sammer', 'Duane Bekaert', 'Sayo Øyerhavn',
    'Max Zettlmeißl', 'Matt Waegelin', 'V0X', 'Kel Cecil', 'Johan Hansén',
    'Ryan Tornell', 'Maik Erhard', 'Arthur Osteen', 'Birk Solem', 'Sabian',
    'Peter Leyshan', 'Frantisek PanMocny Bauer', 'Fefnerphet', 'Michael Beemer',
    'Karsing', 'Austin "Touchdown" Coccia', 'Tranbonium', 'Nick Bomblowski',
    'Gary Marshall', 'Michael Dove', 'Alain Labranche', 'Wesley Ng-A-Fook',
    'Colum Linnane', 'Brodman', 'Udders', 'Copesetic Matt',
    'J Hammarstöm', 'Sir Squeezer', 'Josh Reeves', 'Massimo Crea', 'Axel Baxarias',
    'Ennosuke Zeami', 'Mycroft Geek', 'Crispy duck', 'Thomas Dellign',
    'Robert Campbell', 'Taco Knight', 'Gemini Wong', 'Chadington III',
    'Eduardo Reyes Álvarez', 'Charlie Nordlund', 'Bick Nomford', 'Andy Fox',
    'Arunion Noinura', 'Lachlan Cooper', 'Cpt. Slightly Blue Beard', 'Steve Etherington',
    'Gabo Psy', 'Drax', 'Dom Dom Bear', 'JohnHeroHD', 'Dominik Johann', 'Lann Cowman',
    'Carlos M Gomez', 'Stefan "McGyver" Correa', 'Bob-Colin Balkenhol',
    'Telarian Bender', "LasBlast' Denson", 'Jaybox Furball', 'Patrix Devitt',
    'Spelaea', 'Luca Frigerio', 'Byron Lunau', 'Sunit Das', 'Adrian Eccles',
    'Officerfriendly', 'John Cruickshanks', 'LC NOoSE IV', 'Alexander A. Young',
    'Todd Kolbuck', 'Horst Hellfire', 'Nikita Samoylov', 'J.A. Dalley',
    'Paul Jickling', 'Daniel Harmsworth', 'Heiko Müller', 'Johan Skörk', 'Golg0than',
    'Brandalf the Wise', 'Caleb "Pariah" McCarty', 'Lukas Sarnowski', 'Jesse Coppel',
    'Dodger', 'Norleif Slettebø', 'Sascha Lipiec', 'Will Brockie', 'Alexander Simmons',
    'Joseph Milazzo', 'Vince Von Wilman', 'Dan', 'Mecheil Shiflett',
    'Michael G Fuller Jr', 'Jeremy Moody', 'Tim Gray', 'Remirol', 'Isaac Blum',
    'lunacus', 'Andy Causon', 'Dennis H.', 'Thomas Adam Madigan', 'Chris Fratz',
    'Jacques Michelet', 'Min Hyeon Jo', 'Murakai Haru', 'AceTycho', 'Cameron Tingley',
    'Whittle', 'Morkulv', 'Nathan Taylor', 'Ranaziel', 'DHeth', 'Maximilian Marx',
    'Borstie', 'Oma Omni', 'Patrick Vöhrs', 'Volker Andres', 'Seth Brush', 'Axl Who',
    'Lars -harlequin- Meyer', 'Stefan Weber', 'Mondez', 'Drakon Drakunov',
    'Invader Sascha', 'Carlius Rabbithofen', 'Auer', 'Brian Levinsen', 'Roland Veen',
    'Jason Scrivens', "TV's Adam", 'Pawel Kolek', 'Julian Schmid',
    'Jarred Brown', 'Dominick Allen', 'Golin Son', 'Nick Pitino',
    'Alex Dunlevie', 'Tim Bridges', 'Koen De Couck', 'Aidan Coxon', 'Brett "Gatewayy" Elliff',
    'Tom Grundy', 'Jarred Leverton', 'Adam Kamrad', 'Burt Rito', 'Prince Metal',
    'Edmond Tran', 'Chase Quinnell', 'Peaches', 'Eric Amsler', 'J.D.', 'Declan Pears',
    'Justin Ouellette', 'Matthew Daly', 'Engin Ünsal', 'Timothy Bridges',
    "Phillip 'Palnai' Kinsella", 'Mike Brewer', 'Arthur Dent', 'J-Scrivens', 'PanMocny',
    'Jimtwo Fasoline', 'X Myth', 'Dead Videos', 'Greensap', 'Frank "The Tank" Messier',
    'Albert G.', 'YamiCaleb SoulSlayer', 'Colonel "Bulldog" Banks', 'David Elton',
    'Jose Biosca Martin', 'Steve Gauthier', 'S.T. Hippie', 'Scott Stevenson',
    'Michael R', 'Mr. J.P. Drum', 'Andrew Simpson', 'Tyler', 'Riaan Jonker',
    'Brumley Pritchett', 'Steve Wilman', 'Daniel "Curumim" Lopez', 'Luke Jennings',
    'Steve Olic', 'BLacK_AtA', 'Dave Mongoose', 'Thomas Wyndham', 'Marcel Matz',
    'John McDaris', 'Robert A Vick, V', 'BrainlessKing', 'Pascal Vogler', 'Tyler Cooke',
    'Mordecai Jones', 'Beevan', 'Logan', 'Alexis Levan',
    'Terror Ingatius Mark Eggman', 'Albin Kleinman', 'Malcolm MacDonald', 'alexthekok',
    'Lewismic', 'Willrad von Doomenstein', 'Rastice', 'Dave Sherman', 'Dan Ellis',
    'Son Golin', 'Andreas Sjursen', 'Marneus', 'Brock Wilbur', 'Joey Fowler',
	'Ross Dexter', 'João Carlos Bastos', 'Harrison Pink', 'Steve Gaynor',
	'Richard Porczak', 'Ortwyn Regal', 'Sghoul', 'Dirk Crimson', 'Peter Silk',
	"Michiel 'elmuerte' Hendrik", 'Markus Bachler', 'Patrick Kirkner',
	'Colin Marc', 'David Kellaway', 'Dinnerbone', 'Adam Heslop', 'Donato Sinicco, III',
	'Craig Dolan', 'Nysosis',
},

tEasterEggNames_Other = {
    'Cheeseness', 'Shawnee Camu', 'Lennart Kessler', 'zer0her0', 'Eimi Edana',
    'Portario 44', 'Piotr Michalczyk', 'Chip Nerdtech', 'Trinest', 'Shawnee Camu',
    'Probeus', 'Torbjørn Grønnevik Dahle', 'Meepasaurus Meeps', 'Gamer', 'Kayrack',
	'Corey VanMeekeren', 'Mikhail Popov',
},

}

function CitizenNames.testGenerateNames(race, sex, count)
    -- function for testing name generation
    local sRace = g_LM.line(Character.tRaceNames[race])
    Print(TT_Info, 'character name test dump: '..sex..' '..race)
    count = count or 50
    while count > 0 do
        count = count - 1
        Print(TT_Info, CitizenNames.getNewUniqueName(race, sex))
    end
end

function CitizenNames.getTobianName()
    local name = g_LM.line(DFUtil.arrayRandom(CitizenNames.tTobianNames))
    -- chance to also have a human surname, ie cultural "humanization"
    local nHumanizedChance = 0.2
    if math.random() <= nHumanizedChance then
        name = name .. ' ' .. g_LM.line(DFUtil.arrayRandom(CitizenNames.tHumanLastNames))
    end
    return name
end

function CitizenNames.getBirdSharkName(sex)
    local name = ''
    -- male iwo names encased in vowels (plumage)
    if sex == 'M' then
        name = DFUtil.arrayRandom({'u', 'o', 'i', 'oo', 'uu', 'ii'})
    end
    -- consonant, vowel, middle -> mirror
    name = name .. DFUtil.arrayRandom({'w', 'm', 'x', 'l', 'v', 'b', 'd'})
    name = name .. DFUtil.arrayRandom({'u', 'o', 'i'})
    local middle = DFUtil.arrayRandom({'X', 'W', 'Y', '8', '0', 'I', 'U', 'O'})
    local backhalf = name:reverse()
    if backhalf:find('b') then
        backhalf = backhalf:gsub('b', 'd')
    elseif backhalf:find('d') then
        backhalf = backhalf:gsub('d', 'b')
    end
    return string.format('%s%s%s', name, middle, backhalf)
end

function CitizenNames.getChickenName(sex)
    local tNameTable = CitizenNames.tChickenNames_Female
    if sex == 'M' then
        tNameTable = CitizenNames.tChickenNames_Male
    end
    local name = g_LM.line(DFUtil.arrayRandom(tNameTable))
    local number = string.format('%s', math.random(1, 99999))
    number = MiscUtil.padString(number, 7, false, '0')
    return string.format('%s %s', name, number)
end

function CitizenNames.getCatName(sex)
    local tNameTable
    local nHumanizedChance = 0.1
    if math.random() <= nHumanizedChance then
        if sex == 'F' then
            tNameTable = CitizenNames.tHumanFirstNames_Female
        elseif sex == 'M' then
            tNameTable = CitizenNames.tHumanFirstNames_Male
        end
    else
        if sex == 'F' then
            tNameTable = CitizenNames.tCatFirstNames_Female
        elseif sex == 'M' then
            tNameTable = CitizenNames.tCatFirstNames_Male
        end
    end
    local first = g_LM.line(DFUtil.arrayRandom(tNameTable))
    local last = g_LM.line(DFUtil.arrayRandom(CitizenNames.tCatLastNames))
    local number = math.random(10, 101)
    return string.format('%s %s %s', first, last, MiscUtil.toRoman(number))
end

function CitizenNames.getShamonName()
    local first = DFUtil.arrayRandom({'T','R','G','Z','C','K','M'})
    local last = g_LM.line(DFUtil.arrayRandom(CitizenNames.tShamonLastNames))
    return string.format('%s %s', first, last)
end

function CitizenNames.getJellyName()
    local first = g_LM.line(DFUtil.arrayRandom(CitizenNames.tJellyFirstNames))
    local nHumanizedChance = 0.05
    if math.random() <= nHumanizedChance then
        first = g_LM.line(DFUtil.arrayRandom(CitizenNames.tHumanFirstNames_Female))
    end
    local last = g_LM.line(DFUtil.arrayRandom(CitizenNames.tJellyLastNames))
    return string.format('%s **%s**', first, last)
end

function CitizenNames.getHumanName(sex)
    local thisName

    if sex == 'M' then
        thisName = g_LM.line(DFUtil.arrayRandom(CitizenNames.tHumanFirstNames_Male))
    elseif sex == 'F' then
        thisName = g_LM.line(DFUtil.arrayRandom(CitizenNames.tHumanFirstNames_Female))
    end
    thisName = thisName .. ' ' .. g_LM.line(DFUtil.arrayRandom(CitizenNames.tHumanLastNames))

    return thisName
end

function CitizenNames.getEasterEggName(race, sex)
    if race == Character.RACE_HUMAN then
        if sex == 'M' then
            return DFUtil.arrayRandom(CitizenNames.tEasterEggNames_Male)
        else
            return DFUtil.arrayRandom(CitizenNames.tEasterEggNames_Female)
        end
    else
        return DFUtil.arrayRandom(CitizenNames.tEasterEggNames_Other)
    end
end

function CitizenNames.getNewUniqueName(nRace, sSex)
    local sName = CitizenNames.getName(nRace, sSex)
    local function alreadyUsed(sNewName)
        local tChars = CharacterManager.getCharacters()
        for _,rChar in pairs(tChars) do
            if rChar.tStats.sName == sNewName then
                return true
            end
        end
        return false
    end
    while alreadyUsed(sName) do
        sName = CitizenNames.getName(nRace, sSex)
    end
    return sName
end

function CitizenNames.getName(race, sex)
    -- % chance to grab an easter egg name (team member or paid tier name)
    -- (we can bump this up as needed once/if people pay to have their name in the game)
	local nEasterEggChance = 0.1  -- 10% chance
    if math.random() <= nEasterEggChance then
        return CitizenNames.getEasterEggName(race, sex)
    else
        -- races with gendered names
        if race == Character.RACE_CHICKEN then
            return CitizenNames.getChickenName(sex)
        elseif race == Character.RACE_CAT then
            return CitizenNames.getCatName(sex)
        elseif race == Character.RACE_BIRDSHARK then
            return CitizenNames.getBirdSharkName(sex)
        -- shamon names are gender-neutral
        elseif race == Character.RACE_SHAMON then
            return CitizenNames.getShamonName()
        -- tobians are hermaphroditic
        elseif race == Character.RACE_TOBIAN then
            return CitizenNames.getTobianName()
        -- jellies are all female
        elseif race == Character.RACE_JELLY then
            return CitizenNames.getJellyName()
        elseif race == Character.RACE_KILLBOT then
            return "Kill Bot"
        -- human (or undefined)
        else
            return CitizenNames.getHumanName(sex)
        end
    end
end

return CitizenNames
