#ifndef DEBUG_PIXEL_INCLUDED
#define DEBUG_PIXEL_INCLUDED

#include "ConstantBuffer/World.hlsl"

//////////////////////////////////////////////////
// First debug modes

static const int DebugMode3 = 3;
static const int DebugMode4 = 4;
static const int DebugModeNoNormalMap = 6;
static const int DebugModeNoAlbedo = 8;
static const int DebugModeNoAlbedoNoAO = 9;
static const int DebugMode12 = 12;
static const int DebugMode19 = 19;
static const int DebugMode43 = 43;
static const int DebugMode44 = 44;

//////////////////////////////////////////////////
// Second debug modes

static const int Debug2Mode3 = 3;

//////////////////////////////////////////////////
// Methods

int GetDebugMode()
{
	return (int)round(g_debug_option.x);
}

int GetDebug2Mode()
{
	return (int)round(g_debug_option.y);
}

#endif