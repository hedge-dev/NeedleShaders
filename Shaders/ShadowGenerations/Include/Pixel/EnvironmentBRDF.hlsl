#ifndef ENV_BRDF_PIXEL_INCLUDED
#define ENV_BRDF_PIXEL_INCLUDED

#include "../Texture.hlsl"
Texture2D<float4> WithSampler(s_EnvBRDF);

float2 ApproximateEnvironmentBRDF(float cos_view_normal, float roughness)
{
	float4 remap = roughness
		* float4(-1.0, -0.0275, -0.572, 0.022)
		+ float4( 1.0, 0.0425, 1.04, -0.04);

	float value = min(
		pow(remap.x, 2),
		exp2(cos_view_normal * -9.28)
	);

	value *= remap.x;
	value += remap.y;

	return value * float2(-1.04, 1.04) + remap.zw;
}

float2 ComputeEnvironmentBRDF(bool approximate, float cos_view_normal, float roughness)
{
	if(approximate)
	{
		return ApproximateEnvironmentBRDF(cos_view_normal, roughness);
	}
	else
	{
		return SampleTextureLevel(s_EnvBRDF, float2(cos_view_normal, roughness), 0).xy;
	}
}

void ComputeApplyEnvironmentBRDF(bool approximate, float cos_view_normal, float roughness, float3 reflectance, inout float3 result)
{
	float2 env_bdrf = ComputeEnvironmentBRDF(approximate, cos_view_normal, roughness);
    float3 fresnel_color = reflectance * env_bdrf.x + env_bdrf.y;
	result = max(0.0, result * fresnel_color);
}

#endif