local PlantData = {}

PlantData.tPlants =
{
    Corn =
    {
        ageInfo=
        {
            {nAbove=0.0, spriteName='plant_corn_01_a'},
            {nAbove=0.6, spriteName='plant_corn_01_b'},
            {nAbove=0.8, spriteName='plant_corn_01_c', bCanBeEaten=true},
            {nAbove=0.98, spriteName='plant_corn_01_c', bCanBeHarvested=true, bCanBeEaten=true},
        },
        nLifeTime = 500, -- plant age
		sPlantLC = 'PROPSX048TEXT',
        tHarvestableFoods =
        {
            Corn = {
				tNumHarvestedRange={3,9},
			},
        },
    },
    Pod =
    {
        ageInfo=
        {
            {nAbove=0.0, spriteName='plant_pod_01_a'},
            {nAbove=0.6, spriteName='plant_pod_01_b'},
            {nAbove=0.8, spriteName='plant_pod_01_c', bCanBeEaten=true},
            {nAbove=0.98, spriteName='plant_pod_01_c', bCanBeHarvested=true, bCanBeEaten=true},
        },
        nLifeTime = 500,
		sPlantLC = 'PROPSX050TEXT',
        tHarvestableFoods =
        {
            Pod = {
				tNumHarvestedRange={3,9},
			},
        },
    },
    Glowfruit =
    {
        ageInfo=
        {
            {nAbove=0.0, spriteName='plant_glowfruit_01_a'},
            {nAbove=0.6, spriteName='plant_glowfruit_01_b'},
            {nAbove=0.8, spriteName='plant_glowfruit_01_c', bCanBeEaten=true},
            {nAbove=0.98, spriteName='plant_glowfruit_01_c', bCanBeHarvested=true, bCanBeEaten=true},
        },
        nLifeTime = 500,
		sPlantLC = 'PROPSX049TEXT',
        tHarvestableFoods =
        { 
            Glowfruit = {
				tNumHarvestedRange={3,9},
			},
        },
    },
    CandyCane =
    {
        ageInfo=
        {
            {nAbove=0.0, spriteName='plant_xmas_a'},
            {nAbove=0.6, spriteName='plant_xmas_b'},
            {nAbove=0.8, spriteName='plant_xmas_c', bCanBeEaten=true},
            {nAbove=0.98, spriteName='plant_xmas_c', bCanBeHarvested=true, bCanBeEaten=true},
        },
        nLifeTime = 500,
		sPlantLC = 'PROPSX051TEXT',
        tHarvestableFoods =
        { 
            CandyCane = {
				tNumHarvestedRange={1,5},
			},
        },
    },       
}

return PlantData
