#ifndef ENV_BRDF_PIXEL_INCLUDED
#define ENV_BRDF_PIXEL_INCLUDED

#include "../Texture.hlsl"
#include "ShaderModel.hlsl"

Texture2D<float4> WithSampler(s_EnvBRDF);

float2 ApproximateEnvironmentBRDF(float cos_view_normal, float roughness)
{
	float4 remap = roughness
		* float4(-1.0, -0.275, -0.572, 0.022)
		+ float4( 1.0, 0.0425, 1.04, -0.04);

	float value = min(
		exp2(cos_view_normal * -9.28),
		pow(remap.x, 2)
	);

	value *= remap.x;
	value += remap.y;

	return value * float2(-1.04, 1.04) + remap.zw;
}

float2 ComputeEnvironmentBRDF(uint shader_model, float cos_view_normal, float roughness)
{
	if(shader_model == ShaderModel_2)
	{
		return ApproximateEnvironmentBRDF(cos_view_normal, roughness);
	}
	else
	{
		return SampleTextureLevel(s_EnvBRDF, float2(cos_view_normal, roughness), 0).xy;
	}
}

#endif