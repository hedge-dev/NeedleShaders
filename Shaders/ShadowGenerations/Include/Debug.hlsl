#ifndef DEBUG_PIXEL_INCLUDED
#define DEBUG_PIXEL_INCLUDED

#include "ConstantBuffer/World.hlsl"

#define DEBUG_MODE ((int)round(g_debug_option.x))

#define DEBUG_MODE_3 3
#define DEBUG_MODE_4 4
#define DEBUG_MODE_NO_NORMAL_MAP 6
#define DEBUG_MODE_NO_ALBEDO 8
#define DEBUG_MODE_NO_ALBEDO_NO_AO 9
#define DEBUG_MODE_12 12
#define DEBUG_MODE_19 19
#define DEBUG_MODE_43 43
#define DEBUG_MODE_44 44

#endif