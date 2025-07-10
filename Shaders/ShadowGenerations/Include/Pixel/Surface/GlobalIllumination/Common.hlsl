#ifndef COMMON_GI_SURFACE_INCLUDED
#define COMMON_GI_SURFACE_INCLUDED

//////////////////////////////////////////////////
// Shader Features

#include "../../../Common.hlsl"
#if !defined(is_use_gi) && !defined(no_is_use_gi)
	DefineFeature(is_use_gi_prt);
	DefineFeature(is_use_gi_sg);
	DefineFeature(is_use_gi);
#endif

#include "../../../ConstantBuffer/World.hlsl"
#include "../../../Texture.hlsl"
#include "../../../Debug.hlsl"
#include "../../PBRUtils.hlsl"

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


bool IsAOGIEnabled()
{
	// Disabled when disable type is
	// - DebugGITex_DISABLE_AO
	// - DebugGITex_DISABLE_ALL
	// - DebugGITex_SGGI_ONLY
	// - DebugGITex_AOLF_OCCRATE

	uint gi_disable_type = GetDebugGITexDisableType();
	return UsingAOGI() && (
		gi_disable_type == DebugGITex_DisableNone
		|| gi_disable_type == DebugGITex_DisableSGGI
		|| gi_disable_type == DebugGITex_AOGIOnly
	);

}

bool IsSGGIEnabled()
{
	// Disabled when disable type is
	// - DebugGITex_DISABLE_SGGI
	// - DebugGITex_DISABLE_ALL
	// (No idea why the other "only" modes are not included)

	uint gi_disable_type = GetDebugGITexDisableType();
	return UsingSGGI() && !(
		gi_disable_type == DebugGITex_DisableSGGI
		|| gi_disable_type == DebugGITex_DisableAll
	);
}

bool IsShadowGIEnabled()
{
	// Disabled when disable type is
	// - DebugGITex_DISABLE_SGGI
	// - DebugGITex_DISABLE_AO
	// - DebugGITex_DISABLE_ALL
	// - DebugGITex_AOLF_OCCRATE

	uint gi_disable_type = GetDebugGITexDisableType();
	return UsingGI() && !(
		gi_disable_type == DebugGITex_DisableSGGI
		|| gi_disable_type == DebugGITex_DisableAO
		|| gi_disable_type == DebugGITex_DisableAll
		|| gi_disable_type == DebugGITex_AOLF_OCCRATE
		|| IsAOGIEnabled()
	);
}


#endif