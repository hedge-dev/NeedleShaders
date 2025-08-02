#ifndef SHADOW_GI_SURFACE_INCLUDED
#define SHADOW_GI_SURFACE_INCLUDED

#include "../../../ConstantBuffer/MaterialDynamic.hlsl"
#include "../../../ConstantBuffer/SHLightFieldProbes.hlsl"
#include "../../../Texture.hlsl"

#include "Common.hlsl"
#include "../../TypedOcclusion.hlsl"

#ifdef is_use_gi
	Texture2D<float4> WithSampler(gi_shadow_texture);
	#define SampleGIShadowTexture(uv) SampleTexture(gi_shadow_texture, gi_uv)
#else
	#define SampleGIShadowTexture(uv) float4(1.0, 1.0, 1.0, 1.0)
#endif

float SampleGIOcclusion(float2 gi_uv)
{
	if(UsingDefaultGI)
	{
		return SampleGIShadowTexture(gi_uv).x
			* SampleGITexture(gi_uv, 0.0).w;
	}
	else if(IsSGGIEnabled())
	{
		return SampleGIShadowTexture(gi_uv).x;
	}
	else
	{
		return 1.0;
	}
}

TypedOcclusion ComputeGIOcclusion(float2 gi_uv)
{
	TypedOcclusion result;
	result.value = SampleGIOcclusion(gi_uv);

	if(IsShadowGIEnabled())
	{
		if(UsingSGGI)
		{
			result.mode = OcclusionType_SGGI;
		}
		else if(UsingAOGI)
		{
			result.mode = OcclusionType_AOGI;
		}
		else
		{
			result.mode = OcclusionType_ShadowGI;
		}
	}
	else
	{
		result.mode = OcclusionType_AOLightField; // just 0

		if(AreSHProbesEnabled())
		{
			result.value = 0.0001;
		}
	}

	result.sign = !enable_shadow_map;

	return result;
}

#endif