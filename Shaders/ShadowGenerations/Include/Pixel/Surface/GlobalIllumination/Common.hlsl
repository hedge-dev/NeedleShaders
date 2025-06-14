#ifndef COMMON_GI_SURFACE_INCLUDED
#define COMMON_GI_SURFACE_INCLUDED

#include "../../../ConstantBuffer/World.hlsl"
#include "../../../Common.hlsl"


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

#if defined(is_use_gi_prt) || defined(is_use_gi_sg)
	TextureArrayInput(gi_texture)
#else
	TextureInput(gi_texture)
#endif

TextureInput(gi_shadow_texture)


//////////////////////////////////////////////////
// Methods

uint GetGIMode()
{
	return (uint)u_sggi_param[1].z;
}

void ApplyGI(inout float3 emission)
{

}


#endif