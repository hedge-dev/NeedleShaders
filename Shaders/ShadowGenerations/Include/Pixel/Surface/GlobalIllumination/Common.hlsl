#ifndef COMMON_GI_SURFACE_INCLUDED
#define COMMON_GI_SURFACE_INCLUDED

//////////////////////////////////////////////////
// Shader Features

#include "../../../Common.hlsl"
#if !defined(is_use_gi) && !defined(no_is_use_gi)
	DefineFeature(is_use_gi);
	DefineFeature(is_use_gi_prt);
	DefineFeature(is_use_gi_sg);
#endif

#include "../../../ConstantBuffer/World.hlsl"
#include "../../../Texture.hlsl"
#include "../../../Debug.hlsl"

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

#if defined(is_use_gi)
	#define UsingGI true
#else
	#define UsingGI false
#endif


#if defined(is_use_gi_sg)
	#define UsingSGGI UsingGI
#else
	#define UsingSGGI false
#endif


// Sonic team seemed to disallow combining
// SG with AO when using forward rendering,
// but not when using deferred rendering

#if defined(is_use_gi_prt) && (defined(enable_deferred_rendering) || !defined(is_use_gi_sg))
	#define UsingAOGI UsingGI
#else
	#define UsingAOGI false
#endif


#if !defined(is_use_gi_prt) && !defined(is_use_gi_sg)
	#define UsingDefaultGI UsingGI
#else
	#define UsingDefaultGI false
#endif


bool IsAOGIEnabled()
{
	// Disabled when disable type is
	// - DebugGITex_DISABLE_AO
	// - DebugGITex_DISABLE_ALL
	// - DebugGITex_SGGI_ONLY
	// - DebugGITex_AOLF_OCCRATE

	uint gi_disable_type = GetDebugGITexDisableType();
	return UsingAOGI && (
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
	return UsingSGGI && !(
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
	return UsingGI && !(
		gi_disable_type == DebugGITex_DisableSGGI
		|| gi_disable_type == DebugGITex_DisableAO
		|| gi_disable_type == DebugGITex_DisableAll
		|| gi_disable_type == DebugGITex_AOLF_OCCRATE
		|| IsAOGIEnabled()
	);
}


#endif