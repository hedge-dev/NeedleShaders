#ifndef DEBUG_PIXEL_INCLUDED
#define DEBUG_PIXEL_INCLUDED

#include "ConstantBuffer/World.hlsl"

//////////////////////////////////////////////////
// First debug modes

#define DefineDebugView(num, name) static const int DebugView_##name = num

DefineDebugView( 1, DirDiffuse);
DefineDebugView( 2, DirSpecular);
DefineDebugView( 3, AmbDiffuse);
DefineDebugView( 4, AmbSpecular);
DefineDebugView( 5, OnlyIbl);
DefineDebugView( 6, OnlyIblSurfNormal);
DefineDebugView( 7, Shadow);
DefineDebugView( 8, WhiteAlbedo);
DefineDebugView( 9, WhiteAlbedoNoAo);
DefineDebugView(10, User0);
DefineDebugView(11, User1);
DefineDebugView(12, User2);
DefineDebugView(13, User3);
DefineDebugView(14, Albedo);
DefineDebugView(15, AlbedoCheckOutlier);
DefineDebugView(16, Opacity);
DefineDebugView(17, Normal);
DefineDebugView(18, Roughness);
DefineDebugView(19, Ambient);
DefineDebugView(20, Cavity);
DefineDebugView(21, Reflectance);
DefineDebugView(22, Metallic);
DefineDebugView(23, LocalLight);
DefineDebugView(24, ScatteringFex);
DefineDebugView(25, ScatteringLin);
DefineDebugView(26, SSAO);
DefineDebugView(27, RLR);
DefineDebugView(28, IblDiffuse);
DefineDebugView(29, IblSpecular);
DefineDebugView(30, EnvBRDF);
DefineDebugView(31, WorldPosition);
DefineDebugView(32, ShadingModelId);
DefineDebugView(33, IblCapture);
DefineDebugView(34, IblSkyTerrain);
DefineDebugView(35, WriteDepthToAlpha);
DefineDebugView(36, Smoothness);
DefineDebugView(37, OcclusionCapsule);
DefineDebugView(38, Probe);
DefineDebugView(39, CharacterMask);
DefineDebugView(40, Distance);
DefineDebugView(41, ShadingModel);
DefineDebugView(42, ShadingKind);
DefineDebugView(43, AmbDiffuseLf);
DefineDebugView(44, SggiOnly);

//////////////////////////////////////////////////
// Second debug modes

static const int Debug2Mode_1 = 1;
static const int Debug2Mode_2 = 2;
static const int Debug2Mode_3 = 3;

//////////////////////////////////////////////////
// Methods

int GetDebugView()
{
	return (int)round(g_debug_option.x);
}

int GetDebug2Mode()
{
	return (int)round(g_debug_option.y);
}

#endif