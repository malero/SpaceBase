local World = {
    VISIBILITY_HIDDEN = 1,
    VISIBILITY_DIM = 2,
    VISIBILITY_FULL = 3,
}

-- Color constants for building and whatnot
-- scaling colors b/c of premul alpha
World.prebuiltColor={.25*.5,.25*.5,1*.5,.5}
World.dimColor={0,0,.1*.4,.4}
World.rightFacingColor={1,1,1,1}
World.leftFacingColor={.85,.85,.85,1}

World.TILE_STARTING_HIT_POINTS = 100
World.TILE_DAMAGE_HEALTHY = 4
World.TILE_DAMAGE_LIGHT_DAMAGE = 3
World.TILE_DAMAGE_HEAVY_DAMAGE = 2
World.TILE_DAMAGE_DESTROYED = 1
World.TILE_HEAL_OVER_TIME = 0.05

World.CHARACTER_SAFETY_TOLERANCE = 2 -- Don't allow most actions within this close of a boundary. This gives us room to path around the edge of bases for construction, mining and the like

World.directions = {
    SAME = 1,
    NW = 2,
    NE = 3,
    SW = 4,
    SE = 5,
    N = 6,
    E = 7,
    S = 8,
    W = 9,
}

World.oppositeDirections={
    [1]=World.directions.SAME,
    [2]=World.directions.SE,
    [3]=World.directions.SW,
    [4]=World.directions.NE,
    [5]=World.directions.NW,
    [6]=World.directions.S,
    [7]=World.directions.W,
    [8]=World.directions.N,
    [9]=World.directions.E,
    SAME=World.directions.SAME,
    NW=World.directions.SE,
    NE=World.directions.SW,
    SW=World.directions.NE,
    SE=World.directions.NW,
    N=World.directions.S,
    E=World.directions.W,
    S=World.directions.N,
    W=World.directions.E,
}
World.wallDirections={
    INVALID=-1,
    NWSE=1,
    NESW=2,
    V=3,
    CARAT=4,
    LESSTHAN=5,
    GREATERTHAN=6,
    X=7,
    PILLAR=8,
	T_NE=9,
	T_SE=10,
	T_SW=11,
	T_NW=12,
}
World.directionVectors = {
    {0,0},
    {-.70711,.70711},
    {.70711,.70711},
    {-.70711,-.70711},
    {.70711,-.70711},
    {0,1},
    {1,0},
    {0,-1},
    {-1,0},
}

-- lookup table for the direction a given wall should be receiving light
World.wallLightDirections={}
World.wallLightDirections[World.wallDirections.NWSE] = World.directions.SW
World.wallLightDirections[World.wallDirections.NESW] = World.directions.SE
World.wallLightDirections[World.wallDirections.V] = World.directions.SW
World.wallLightDirections[World.wallDirections.CARAT] = World.directions.S
World.wallLightDirections[World.wallDirections.LESSTHAN] = World.directions.SW
World.wallLightDirections[World.wallDirections.GREATERTHAN] = World.directions.SE
World.wallLightDirections[World.wallDirections.X] = World.directions.S
World.wallLightDirections[World.wallDirections.PILLAR] = World.directions.S
World.wallLightDirections[World.wallDirections.T_NE] = World.directions.SW
World.wallLightDirections[World.wallDirections.T_SE] = World.directions.S
World.wallLightDirections[World.wallDirections.T_SW] = World.directions.S
World.wallLightDirections[World.wallDirections.T_NW] = World.directions.SE

World.logicalTiles = {
    -- Don't insert/renumber this list or you'll invalidate savegames
    -- and saved layouts
    SPACE = 1,    
    WALL = 4,
    DOOR = 5, 
    WALL_DESTROYED = 6,

    -- list of zones starts at this value.
    ZONE_LIST_START=8,

    -- a full asteroid has this value; it increases as the asteroid gets mined out
    -- until it gets turned to space.
    ASTEROID_VALUE_START=1024,
    ASTEROID_VALUE_END=1124,
}

return World
