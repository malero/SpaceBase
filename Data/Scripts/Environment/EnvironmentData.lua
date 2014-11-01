local DFGraphics = require('DFCommon.Graphics')
local EnvironmentData = {}

kBLEND_MULTIPLY = { MOAIProp.GL_DST_COLOR, MOAIProp.GL_ONE_MINUS_SRC_ALPHA }
kBLEND_ADD = { MOAIProp.GL_ONE, MOAIProp.GL_ONE }
kBLEND_ALPHA = { MOAIProp.GL_SRC_ALPHA, MOAIProp.GL_ONE_MINUS_SRC_ALPHA}
kBLEND_PREMULTIPLIED = { MOAIProp.GL_ONE, MOAIProp.GL_ONE_MINUS_SRC_ALPHA}


local kFARAWAYPLANE = -5500

EnvironmentData.tPresets=
{
    default =
    {
        sPostColorLUT = "neutral",
        
        gradColorLeft = { 0.0, 0.0, 0.0, 0.0 },
        gradColorRight = { 0.00, 0.0, 0.014, 0.0 },
        gradColorTop = { 0.0, 0.0, 0.0, 0.0 },
        gradColorBottom = { 1.0, 1.0, 1.0, 0.0 },
        
        ambientColor = {  0,0,0  },
        
        nebulaSprites = 
        {
            Sprite01 = 
            {
                sSpritePath = 'Backgrounds/Elements',
                sSpriteName = "nebulaStreak",
                scale = { 2000.0, 1300.0 },
                color = { 0.2, 0.8, 1.0, 0.8 },
                offset = { -100.0, 100.0, -500.0 },
                rotation = 0,
            },
            
            Blobber = 
            {
                sSpritePath = 'Backgrounds/Elements',
                sSpriteName = "softCloud",
                scale = { 1200, 1200 },
                color = { 0.2, 0.352, 0.3, 0.7 },
                offset = { 0.0, 0.0, 0.0 },

            },
            nebnoise = 
            {
                sSpritePath = 'Backgrounds/Elements',
                sSpriteName = "noiseCloud01",
                scale = { 1300.0*0.3, 900.0*0.3 },
                color = { 0.48, 0.45, 0.7, 0.7 },
                offset = { -50.0, 0.0, 600.0 },
                rotation = 30,
                layerName = 'foreground'
            },
            BlueStars = 
            {
                sSpritePath = 'Backgrounds/Elements',
                sSpriteName = "starSpatter",
                scale = { 1000.0*5, 800.0*5 },
                offset = { 0.0, 0.0, kFARAWAYPLANE },
                color = { 0.3, .8, 1.0, 1.0 },
                distribution = { 600.0, 600.0, 0.0 },
                count = 5,
                rotation = 360,
                blendMode = kBLEND_ALPHA,
                
            },
            LightStars = 
            {
                sSpritePath = 'Backgrounds/Elements',
                sSpriteName = "starSpatter",
                scale = { 1000.0*5, 800.0*5 },
                color = { 1.0, 1.0, 1.0, 1.0 },
                offset = { 0.0, 0.0, kFARAWAYPLANE },
                distribution = { 600.0, 600.0, 0.0 },
                count = 1,
                rotation = 360,
            },
            BrightStars = 
            {
                sSpritePath = 'Backgrounds/Elements',
                sSpriteName = "starYellow",
                scale = { 40.0*5, 40.0*5 },
                scaleRange = 0.7,
                --color = { 2.0, 2.0, 0.6, 1.0 },
                offset = { 200.0, 30.0, kFARAWAYPLANE },
                distribution = { 150.0*5, 70.0*5, 500 },
                count = 7,
                rotation = 360,
            },

              BrightStars2 = 
            {
                sSpritePath = 'Backgrounds/Elements',
                sSpriteName = "starBlue",
                scale = { 50.0*7, 50.0*7 },
                scaleRange = 0.3,
                --color = { 2.0, 2.0, 0.6, 1.0 },
                offset = { 0.0, 0.0, kFARAWAYPLANE },
                distribution = { 155.0*5, 170.0*5, 0 },
                count = 5,
                rotation = 360,
            },                    
        },
        flares =
        {
           Flare1 = 
           {
                color = { 0.15, 1.0, 0.0},
                sSpritePath = 'Backgrounds/Backgrounds/Elements',
                sSpriteName = 'bigblob',
                offset = { 4.0, 0.0 },
                size = { 0.2, 0.2 },
           }
        },
    },
    magentaSpace =
    {
        sPostColorLUT = "neutral",
        
        gradColorLeft = { 0.0, 0.0, 0.0, 0.0 },
        gradColorRight = { 0.06, 0.0, 0.01, 0.0 },
        gradColorTop = { 0.0, 0.0, 0.0, 0.0 },
        gradColorBottom = { 2.0, 2.0, 2.0, 0.0 },
        
        ambientColor = { 0,0,0 },
        
        nebulaSprites = 
        {
            Sprite01 = 
            {
                sSpritePath = 'Backgrounds/Elements',
                sSpriteName = "nebulaStreak",
                scale = { 1400.0, 1000.0 },
                color = { 1.0, 0.2, 0.3, 0.8 },
                offset = { 0.0, 0.0, -500.0 },
                rotation = 5,
            },
            
            Blobber = 
            {
                sSpritePath = 'Backgrounds/Elements',
                sSpriteName = "softCloud",
                scale = { 1200, 1200 },
                color = { 0.2, 0.2, 0.5, 0.7 },
                offset = { 300.0, -100.0, 0.0 },
                
            },
            nebnoise = 
            {
                sSpritePath = 'Backgrounds/Elements',
                sSpriteName = "noiseCloud01",
                scale = { 1300.0, 900.0 },
                color = { 0.8, 0.2, 0.5, 0.8 },
                offset = { -500.0, 0.0, 600.0 },
                rotation = 30,
                layerName = 'foreground'
            },
            BlueStars = 
            {
                sSpritePath = 'Backgrounds/Elements',
                sSpriteName = "starSpatter",
                scale = { 1000.0*5, 800.0*5 },
                offset = { 0.0, 0.0,   kFARAWAYPLANE },
                color = { 0.3, .8, 1.0, 1.0 },
                distribution = { 600.0, 600.0, 0.0 },
                count = 5,
                rotation = 360,
                blendMode = kBLEND_ALPHA,
                
            },
            LightStars = 
            {
                sSpritePath = 'Backgrounds/Elements',
                sSpriteName = "starSpatter",
                scale = { 1000.0*5, 800.0*5 },
                color = { 1.0, 1.0, 1.0, 1.0 },
                offset = { 0.0, 0.0,  kFARAWAYPLANE },
                distribution = { 600.0, 600.0, 0.0 },
                count = 1,
                rotation = 360,
            },
            BrightStars = 
            {
                sSpritePath = 'Backgrounds/Elements',
                sSpriteName = "starYellow",
                scale = { 50.0*5, 50.0*5 },
                scaleRange = 0.6,
                --color = { 2.0, 2.0, 0.6, 1.0 },
                offset = { 300.0*5, 30.0, kFARAWAYPLANE },
                distribution = { 50.0*5, 70.0*5, 0.0 },
                count = 5,
                rotation = 360,
            },

              BrightStars2 = 
            {
                sSpritePath = 'Backgrounds/Elements',
                sSpriteName = "starBlue",
                scale = { 50.0*5, 50.0*5 },
                scaleRange = 0.3,
                --color = { 2.0, 2.0, 0.6, 1.0 },
                offset = { 0.0, 0.0, kFARAWAYPLANE },
                distribution = { 600.0*5, 400.0*5, 0.0 },
                count = 5,
                rotation = 360,
            },          
            BrightNeb = 
            {
                sSpritePath = 'Backgrounds/Elements',
                sSpriteName = "softCloud",
                scale = { 400.0, 400.0 },

                color = { 1.0, 0.4, 0.3, 0.4 },
                offset = { 270.0, 30.0, 0.0 },
                rotation = 0,
            },            
        },
        flares =
        {
           Flare1 = 
           {
                color = { 0.15, 1.0, 0.0},
                sSpritePath = 'Backgrounds/Backgrounds/Elements',
                sSpriteName = 'bigblob',
                offset = { 4.0, 0.0 },
                size = { 0.2, 0.2 },
           }
        },
    },    
    greenSpace =
    {
        sPostColorLUT = "neutral",
        
        gradColorLeft = { 0.0, 0.0, 0.05, 0.0 },
        gradColorRight = { 0.1, 0.3, 0.03, 0.0 },
        gradColorTop = { 0.5, 0.5, 0.5, 1.0  },
        gradColorBottom = { 1.0, 1.0, 1.0, 0.0 },
        
        ambientColor = { 0,0,0 },
        
        nebulaSprites = 
        {
            NebStreak = 
            {
                sSpritePath = 'Backgrounds/Elements',
                sSpriteName = "nebulaStreak",
                scale = { 1400.0, 1000.0 },
                color = { 1.0*0.5, 0.65*0.5, 0.31*0.5, 1.0 },
                distribution = { 100.0, 100.0, 0.0 },
                count = 2,                
                offset = { 0.0, 0.0, 0.0 },
                scaleRange = 0.3,                
                rotation = 360,
            },
            
            Blobber = 
            {
                sSpritePath = 'Backgrounds/Elements',
                sSpriteName = "softCloud",
                scale = { 1200, 1200 },
                color = { 0.2, 0.2, 0.5, 0.7 },
                offset = { 500.0, -100.0, 0.0 },
                
            },
            nebnoise = 
            {
                sSpritePath = 'Backgrounds/Elements',
                sSpriteName = "noiseCloud01",
                scale = { 1300.0, 900.0 },
                color = { 1, 0.7, 0.5, 0.4 },
                count = 3,                      
                offset = { 300.0, 0.0, 0.0 },
                scaleRange = 0.6,                  
                rotation = 360,
                layerName = 'foreground'
            },
            BlueStars = 
            {
                sSpritePath = 'Backgrounds/Elements',
                sSpriteName = "starSpatter",
                scale = { 1000.0*5, 800.0*5 },
                offset = { 0.0, 0.0, kFARAWAYPLANE },
                color = { 0.3, .8, 1.0, 0.5 },
                distribution = { 600.0*5, 600.0*5, 0.0 },
                count = 5,
                rotation = 360,
            },
            LightStars = 
            {
                sSpritePath = 'Backgrounds/Elements',
                sSpriteName = "starSpatter",
                scale = { 1000.0*5, 800.0*5 },
                color = { 0.3, .8, 1.0, 1.0 },
                offset = { 0.0, 0.0, kFARAWAYPLANE },
                distribution = { 600.0, 600.0, 0.0 },
                count = 1,
                rotation = 360,
            },
            FlareStar = 
            {
                sSpritePath = 'Backgrounds/Elements',
                sSpriteName = "starGreen",
                scale = { 500*5,500*5 },
                color = { 1.0, 1.0, 1.0, 1.0 },
                offset = { 400.0*5, -30.0*5, kFARAWAYPLANE },

            },
            FlareStarStreak = 
            {
                sSpritePath = 'Backgrounds/Elements',
                sSpriteName = "starGreen",
                scale = { 900*5,60*5 },
                color = { 1.0,1.0,1.0,0.2 },
                offset = { 400.0*5, -30.0*5, kFARAWAYPLANE },
            },            

              BrightStars2 = 
            {
                sSpritePath = 'Backgrounds/Elements',
                sSpriteName = "starBlue",
                scale = { 50.0, 50.0 },
                scaleRange = 0.3,
                --color = { 2.0, 2.0, 0.6, 1.0 },
                offset = { 200.0, 30.0, kFARAWAYPLANE },
                distribution = { 150.0*5, 70.0*5, 500 },
                count = 5,
                rotation = 360,
            },          
            BrightNeb = 
            {
                sSpritePath = 'Backgrounds/Elements',
                sSpriteName = "softCloud",
                scale = { 400.0, 400.0 },

                color = { 1.0, 0.4, 0.3, 0.4 },
                offset = { 270.0, 30.0, 0.0 },
                rotation = 0,
            },            
        },
        flares =
        {
           Flare1 = 
           {
                color = { 0.15, 1.0, 0.0},
                sSpritePath = 'Backgrounds/Backgrounds/Elements',
                sSpriteName = 'bigblob',
                offset = { 0.0, 0.0, kFARAWAYPLANE },
                size = { 0.2, 0.2 },
           }
        },
    },    
}

return EnvironmentData
