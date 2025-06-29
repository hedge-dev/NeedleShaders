#ifndef COMMON_GI_SURFACE_INCLUDED
#define COMMON_GI_SURFACE_INCLUDED

//////////////////////////////////////////////////
// Shader Features

#include "../../../Common.hlsl"
DefineFeature(is_use_gi_prt);
DefineFeature(is_use_gi_sg);
DefineFeature(is_use_gi);

#include "../../../ConstantBuffer/World.hlsl"
#include "../../../Texture.hlsl"
#include "../../../Debug.hlsl"
#include "../../PBRUtils.hlsl"

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

#ifdef is_use_gi_sg
	Texture2DArray<float4> WithSampler(gi_texture);
	#define SampleGITexture(xy, z) SampleTexture(gi_texture, float3(xy, z))
	#define SampleGITextureLevel(xy, z, level) SampleTextureLevel(gi_texture, float3(xy, z), level)
#else
	Texture2D<float4> WithSampler(gi_texture);
	#define SampleGITexture(xy, z) SampleTexture(gi_texture, xy)
	#define SampleGITextureLevel(xy, z, level) SampleTextureLevel(gi_texture, xy, level)
#endif

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
	// Sonic team seemed to disallow combining
	// SG with AO when using forward rendering,
	// but not when using deferred rendering

	#if defined(is_use_gi_prt) && (defined(enable_deferred_rendering) || !defined(is_use_gi_sg))
		return UsingGI();
	#else
		return false;
	#endif
}

bool UsingDefaultGI()
{
	#if !defined(is_use_gi_prt) && !defined(is_use_gi_sg)
		return UsingGI();
	#else
		return false;
	#endif
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