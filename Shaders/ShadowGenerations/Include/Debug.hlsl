#ifndef DEBUG_PIXEL_INCLUDED
#define DEBUG_PIXEL_INCLUDED

#include "ConstantBuffer/World.hlsl"

//////////////////////////////////////////////////
// First debug modes

#define DefineDebugMode(num, name) static const int DebugMode_##name = num
#define DefineDebugModeUnk(num) static const int DebugMode_##num = num

DefineDebugMode(1, DiffuseLighting);
DefineDebugMode(2, SpecularLighting);
DefineDebugMode(3, Emission);
DefineDebugMode(4, Emission2);
DefineDebugMode(5, EnvReflections);
DefineDebugMode(6, EnvReflectionsSmooth);
DefineDebugMode(7, Shadow);
DefineDebugMode(8, NoAlbedo);
DefineDebugMode(9, NoAlbedoNoAO);
DefineDebugModeUnk(10);
DefineDebugModeUnk(11);
DefineDebugModeUnk(12);
DefineDebugModeUnk(13);
DefineDebugMode(14, Albedo);
DefineDebugMode(15, Albedo2);
DefineDebugMode(16, White);
DefineDebugMode(17, Normal);
DefineDebugMode(18, Roughness);
DefineDebugMode(19, WeirdIndirect);
DefineDebugMode(20, AmbientOcclusion);
DefineDebugMode(21, FresnelReflectance);
DefineDebugMode(22, Metallic);
DefineDebugModeUnk(23);
DefineDebugModeUnk(37);
DefineDebugModeUnk(38);
DefineDebugMode(26, SSAO);
DefineDebugMode(27, ScreenSpaceReflections);
DefineDebugMode(28, EnvReflectionNoFogNoFresnel);
DefineDebugMode(29, EnvReflectionNoFog);
DefineDebugMode(30, EnvBRDF);
DefineDebugMode(31, Position);
DefineDebugMode(32, ShaderModel);
DefineDebugMode(33, FirstProbe);
DefineDebugModeUnk(35);
DefineDebugMode(36, Smoothness);
DefineDebugMode(39, FlagUnk2);
DefineDebugMode(40, ViewDistance);
DefineDebugMode(41, ShaderModel2);
DefineDebugMode(42, FlagUnk2_2);
DefineDebugModeUnk(43);
DefineDebugModeUnk(44);

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