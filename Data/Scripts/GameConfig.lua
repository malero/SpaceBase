-- $Id$
-- Copyright 2013 Double Fine Productions
-- All rights reserved.  Proprietary and Confidential.
--
-- Game-specific global config.
-- Put global data and config bools here; anything that needs to be set up even
-- if main.lua isn't executed.

-- No texture spam by default
MOAILogMgr.registerLogMessage ( MOAILogMgr.MOAITexture_MemoryUse_SDFS, '' )

-- For example, from Reds
 g_bDisableMusic = true
-- g_bDisableSound = false

g_nMinAspectRatio = 50 -- 400 / 3
g_nMaxAspectRatio = 500--1600 / 9
