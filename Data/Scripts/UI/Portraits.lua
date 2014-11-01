local DFUtil = require("DFCommon.Util")
local Portraits = {}

--Human Male
Portraits.HUMAN_MALE_WHITE = {'Human_Male_White_01','Human_Male_White_02','Human_Male_White_03','Human_Male_White_04','Human_Male_White_05','Human_Male_White_06',
    'Human_Male_White_07','Human_Male_White_08','Human_Male_White_09','Human_Male_White_10',}
Portraits.HUMAN_MALE_BROWN = {'Human_Male_Brown_01','Human_Male_Brown_02','Human_Male_Brown_03','Human_Male_Brown_04','Human_Male_Brown_05','Human_Male_Brown_06',
    'Human_Male_Brown_07','Human_Male_Brown_08','Human_Male_Brown_09','Human_Male_Brown_10', }
Portraits.HUMAN_MALE_BLACK = {'Human_Male_Black_01','Human_Male_Black_02','Human_Male_Black_03','Human_Male_Black_04','Human_Male_Black_05','Human_Male_Black_06',
    'Human_Male_Black_07','Human_Male_Black_08','Human_Male_Black_09','Human_Male_Black_10', }
Portraits.HUMAN_MALE_REDDISH = {'Human_Male_Reddish_01','Human_Male_Reddish_02','Human_Male_Reddish_03','Human_Male_Reddish_04','Human_Male_Reddish_05','Human_Male_Reddish_06',
    'Human_Male_Reddish_07','Human_Male_Reddish_08','Human_Male_Reddish_09','Human_Male_Reddish_10', }
Portraits.HUMAN_MALE_YELLOWISH = {'Human_Male_Yellowish_01','Human_Male_Yellowish_02','Human_Male_Yellowish_03','Human_Male_Yellowish_04','Human_Male_Yellowish_05','Human_Male_Yellowish_06',
    'Human_Male_Yellowish_07','Human_Male_Yellowish_08','Human_Male_Yellowish_09','Human_Male_Yellowish_10', }
--Human Male (Fat)
Portraits.HUMAN_MALE_WHITE_FAT = {'Human_Large_Male_White_01','Human_Large_Male_White_02',}
Portraits.HUMAN_MALE_BROWN_FAT = {'Human_Large_Male_Brown_01','Human_Large_Male_Brown_02', }
Portraits.HUMAN_MALE_BLACK_FAT = {'Human_Large_Male_Black_01','Human_Large_Male_Black_02', }
Portraits.HUMAN_MALE_REDDISH_FAT = {'Human_Large_Male_Reddish_01','Human_Large_Male_Reddish_02', }
Portraits.HUMAN_MALE_YELLOWISH_FAT = {'Human_Large_Male_Yellowish_01','Human_Large_Male_Yellowish_02', }

--Human Female   
Portraits.HUMAN_FEMALE_WHITE = {'Human_Female_White_01','Human_Female_White_02','Human_Female_White_03','Human_Female_White_04','Human_Female_White_05',
    'Human_Female_White_06','Human_Female_White_07','Human_Female_White_08',}
Portraits.HUMAN_FEMALE_BROWN = {'Human_Female_Brown_01','Human_Female_Brown_02','Human_Female_Brown_03','Human_Female_Brown_04','Human_Female_Brown_05',
    'Human_Female_Brown_06','Human_Female_Brown_07','Human_Female_Brown_08',}
Portraits.HUMAN_FEMALE_BLACK = {'Human_Female_Black_01','Human_Female_Black_02','Human_Female_Black_03','Human_Female_Black_04','Human_Female_Black_05',
    'Human_Female_Black_06','Human_Female_Black_07','Human_Female_Black_08',}
Portraits.HUMAN_FEMALE_REDDISH = {'Human_Female_Reddish_01','Human_Female_Reddish_02','Human_Female_Reddish_03','Human_Female_Reddish_04','Human_Female_Reddish_05',
    'Human_Female_Reddish_06','Human_Female_Reddish_07','Human_Female_Reddish_08',}
Portraits.HUMAN_FEMALE_YELLOWISH = {'Human_Female_Yellowish_01','Human_Female_Yellowish_02','Human_Female_Yellowish_03','Human_Female_Yellowish_04','Human_Female_Yellowish_05',
    'Human_Female_Yellowish_06','Human_Female_Yellowish_07','Human_Female_Yellowish_08',}
--Human Female (Fat)
Portraits.HUMAN_FEMALE_WHITE_FAT = {'Human_Large_Female_White_01','Human_Large_Female_White_02',}
Portraits.HUMAN_FEMALE_BROWN_FAT = {'Human_Large_Female_Brown_01','Human_Large_Female_Brown_02', }
Portraits.HUMAN_FEMALE_BLACK_FAT = {'Human_Large_Female_Black_01','Human_Large_Female_Black_02', }
Portraits.HUMAN_FEMALE_REDDISH_FAT = {'Human_Large_Female_Reddish_01','Human_Large_Female_Reddish_02', }
Portraits.HUMAN_FEMALE_YELLOWISH_FAT = {'Human_Large_Female_Yellowish_01','Human_Large_Female_Yellowish_02', }

--Jelly
Portraits.JELLY_FEMALE_BLUE = {'Jelly_Female_Blue_01','Jelly_Female_Blue_02',}
Portraits.JELLY_FEMALE_PINK = {'Jelly_Female_Pink_01','Jelly_Female_Pink_02',}
Portraits.JELLY_FEMALE_PURPLE = {'Jelly_Female_Purple_01','Jelly_Female_Purple_02',}
Portraits.JELLY_FEMALE_MAUVE = {'Jelly_Female_Mauve_01','Jelly_Female_Mauve_02',}


--Cats
Portraits.CAT_MALE = {'Cat_male_black_01',}
Portraits.CAT_FEMALE = {'Cat_female_yellow_01',}

--Chickens
Portraits.CHICKEN_MALE = {'Chicken_Male_White_01',}
Portraits.CHICKEN_FEMALE = {'Chicken_female_White_01','Chicken_Female_White_02',}

--Birdsharks
Portraits.BIRDSHARK_MALE = {'Birdshark_Male_White_01','Birdshark_Male_White_02',}
Portraits.BIRDSHARK_FEMALE = {'Birdshark_female_White_01','Birdshark_Female_White_02',}
Portraits.BIRDSHARK_MALE_FAT = {'Birdshark_Large_Male_White_01',}
Portraits.BIRDSHARK_FEMALE_FAT = {'Birdshark_Large_Female_White_01',}

--Tobians
Portraits.TOBIAN_DONG_HEAD = { 
    Blue = {'TobianDongHead_Male_Blue_01','TobianDongHead_Male_Blue_02',}, 
    Light_Blue = {'TobianDongHead_Male_Light_Blue_01','TobianDongHead_Male_Light_Blue_02',},
    Teal = {'TobianDongHead_Male_Teal_01','TobianDongHead_Male_Teal_02',},
    Light_Teal = {'TobianDongHead_Male_Light_Teal_01','TobianDongHead_Male_Light_Teal_02',},
    Purple = {'TobianDongHead_Male_Purple_01','TobianDongHead_Male_Purple_02',},  
}
Portraits.TOBIAN_ELEPHANT_HEAD = { 
    Blue = {'TobianElephantHead_Male_Blue_01','TobianElephantHead_Male_Blue_02',}, 
    Light_Blue = {'TobianElephantHead_Male_Light_Blue_01','TobianElephantHead_Male_Light_Blue_02',},  
    Teal = {'TobianElephantHead_Male_Teal_01','TobianElephantHead_Male_Teal_02',},
    Light_Teal = {'TobianElephantHead_Male_Light_Teal_01','TobianElephantHead_Male_Light_Teal_02',},  
    Purple = {'TobianElephantHead_Male_Purple_01','TobianElephantHead_Male_Purple_02',},  
}
Portraits.TOBIAN_EYESTALK_MUSTACHE_HEAD = { 
    Blue = {'TobianEyestalkMustacheHead_Male_Blue_01','TobianEyestalkMustacheHead_Male_Blue_02',}, 
    Light_Blue = {'TobianEyestalkMustacheHead_Male_Light_Blue_01','TobianEyestalkMustacheHead_Male_Light_Blue_02',},  
    Teal = {'TobianEyestalkMustacheHead_Male_Teal_01','TobianEyestalkMustacheHead_Male_Teal_02',},
    Light_Teal = {'TobianElephantHead_Male_Light_Teal_01','TobianElephantHead_Male_Light_Teal_02',},  
    Purple = {'TobianEyestalkMustacheHead_Male_Purple_01','TobianEyestalkMustacheHead_Male_Purple_02',},  
}
--Shamons
Portraits.SHAMON_MALE = {'Shamon_Male_White_01','Shamon_Male_White_02','Shamon_Male_White_03',}

--Murderface
Portraits.MURDERFACE = {'MurderFace_Male_Green_01','MurderFace_Male_Green_02','MurderFace_Male_Green_03',}

--Murder Slug
Portraits.MURDER_SLUG = {'Murder_Slug_01','Murder_Slug_02',}

--KillBot
Portraits.KILLBOT = {'Murder_Robot_01','Murder_Robot_02',}

--Monster
Portraits.MONSTER = {'Monster_01',}

local tValidPortraits = {}

-- a little gross, but we need to have all possible values in a table so we can validate settings
for k,tPortraitList in pairs(Portraits) do
    for idx,sPortraitId in ipairs(tPortraitList) do
        tValidPortraits[sPortraitId] = true
    end
end

-- this should be below the above for loop to be safe
Portraits.PORTRAIT_PATH = 'UI/Portraits'
Portraits.GENERIC_PORTRAIT = 'portrait_generic'

function Portraits.isValidPortrait( img )
    return true == tValidPortraits[img]
end 

function Portraits.getRandomPortrait()
    local tRandom = {'TobianEyestalkMustacheHead_Male_Light_Blue_01', 'TobianDongHead_Male_Light_Teal_02','Birdshark_Large_Male_White_01',
    'Jelly_Female_Purple_02','Human_Female_Black_01','Human_Large_Female_Brown_01','Human_Female_Yellowish_03','Human_Male_White_04',
    'Human_Large_Male_Black_02','Shamon_Male_White_02','Chicken_Male_White_01','TobianElephantHead_Male_Purple_02','Cat_male_black_01',}
    local p = DFUtil.arrayRandom(tRandom)
    return p
end

return Portraits
