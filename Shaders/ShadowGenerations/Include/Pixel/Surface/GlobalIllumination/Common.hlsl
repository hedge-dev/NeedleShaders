#ifndef COMMON_GI_SURFACE_INCLUDED
#define COMMON_GI_SURFACE_INCLUDED

#include "../../../ConstantBuffer/World.hlsl"
#include "../../../Common.hlsl"
#include "../../../Debug.hlsl"
#include "../../PBRUtils.hlsl"

//////////////////////////////////////////////////
// Shader Features

static const uint FEATURE_is_use_gi_prt;
static const uint FEATURE_is_use_gi_sg;
static const uint FEATURE_is_use_gi;


//////////////////////////////////////////////////
// Constants
// TODO document their function

static const uint GIMode0 = 0;
static const uint GIMode1 = 1;
static const uint GIMode2 = 2;
static const uint GIMode3 = 3;
static const uint GIMode5 = 5;
static const uint GIMode6 = 6;


//////////////////////////////////////////////////
// Textures

TextureInput(gi_texture)
Texture2DArray<float4> gi_texture;

//////////////////////////////////////////////////
// Methods

bool UsingGI()
{
	#if defined(is_use_gi)
		return true;
	#else
		return false;
	#endif
}

bool UsingSGGI()
{
	#if defined(is_use_gi_sg)
		return UsingGI();
	#else
		return false;
	#endif
}

bool UsingAOGI()
{
	#if defined(is_use_gi_prt)
		return UsingGI();
	#else
		return false;
	#endif
}

bool UsingDefaultGI()
{
	return UsingGI()
		&& !UsingAOGI()
		&& !UsingSGGI();
}


uint GetGIMode()
{
	return (uint)u_sggi_param[1].z;
}

bool IsAOGIEnabled()
{
	uint gi_mode = GetGIMode();
	return UsingAOGI() && (
		gi_mode == GIMode0
		|| gi_mode == GIMode1
		|| gi_mode == GIMode5
	);
}

bool IsSGGIEnabled()
{
	uint gi_mode = GetGIMode();
	return UsingSGGI() && !(
		gi_mode == GIMode1
		|| gi_mode == GIMode3
	);
}

bool AreBakedShadowsEnabled()
{
	uint gi_mode = GetGIMode();
	return UsingGI() && !(
		gi_mode == GIMode1
		|| gi_mode == GIMode2
		|| gi_mode == GIMode3
		|| gi_mode == GIMode6
		|| IsAOGIEnabled()
	);
}


#endif