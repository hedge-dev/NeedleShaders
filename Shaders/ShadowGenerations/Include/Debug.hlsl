#ifndef DEBUG_PIXEL_INCLUDED
#define DEBUG_PIXEL_INCLUDED

#include "ConstantBuffer/World.hlsl"

//////////////////////////////////////////////////
// First debug modes

static const int DebugMode_2 = 2;
static const int DebugMode_3 = 3;
static const int DebugMode_4 = 4;
static const int DebugMode_NoNormalMap = 6;
static const int DebugMode_NoAlbedo = 8;
static const int DebugMode_NoAlbedoNoAO = 9;
static const int DebugMode_12 = 12;
static const int DebugMode_19 = 19;
static const int DebugMode_43 = 43;
static const int DebugMode_44 = 44;

//////////////////////////////////////////////////
// Second debug modes

static const int Debug2Mode_1 = 1;
static const int Debug2Mode_2 = 2;
static const int Debug2Mode_3 = 3;

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