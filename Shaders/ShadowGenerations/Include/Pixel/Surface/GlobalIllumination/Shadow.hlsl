#ifndef SHADOW_GI_SURFACE_INCLUDED
#define SHADOW_GI_SURFACE_INCLUDED

#include "../../../ConstantBuffer/MaterialDynamic.hlsl"
#include "../../../ConstantBuffer/SHLightFieldProbes.hlsl"

#include "Common.hlsl"

TextureInput(gi_shadow_texture)

float SampleGIShadow(float2 gi_uv)
{
	if(UsingDefaultGI())
	{
		return SampleTexture(gi_shadow_texture, gi_uv).x
			* SampleTexture(gi_texture, gi_uv).w;
	}
	else if(IsSGGIEnabled())
	{
		return SampleTexture(gi_shadow_texture, gi_uv).x;
	}
	else
	{
		return 1.0;
	}
}

float ComputeGIShadow(float2 gi_uv)
{
	bool enable_shadows = AreBakedShadowsEnabled();

	float result = shlightfield_param.x <= 0 || enable_shadows
		? SampleGIShadow(gi_uv)
		: 0.0001;

	if(enable_shadows)
	{
		if(UsingSGGI())
		{
			result += 30.0;
		}
		else if(UsingAOGI())
		{
			result += 20.0;
		}
		else
		{
			result += 10.0;
		}
	}

	return enable_shadow_map
		? result
		: -result;
}

#endif