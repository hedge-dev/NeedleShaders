#ifndef IBL_LIGHTING_INCLUDED
#define IBL_LIGHTING_INCLUDED

#include "../../Texture.hlsl"
#include "../../Debug.hlsl"
#include "Struct.hlsl"

TextureCube<float4> WithSampler(s_IBL);

float ComputeIBLDirectionalSpecularFactor(LightingParameters parameters)
{
	if(enable_ibl_plus_directional_specular)
	{
		return 1.0;
	}

	return 1.0 - GetDebugAmbientSpecularFactor(parameters.typed_occlusion.mode, parameters.roughness, 1.0);
}

float ComputeIBLOcclusion(LightingParameters parameters)
{
	float result = GetDebugAmbientSpecularFactor(parameters.typed_occlusion.mode, parameters.roughness, parameters.cavity);

	if(parameters.typed_occlusion.mode == OcclusionType_ShadowGI)
	{
		result = lerp(result, 1.0, parameters.metallic);
	}

	return result;
}

float3 ComputeIBLDirection(float3 normal, float3 view_direction, float roughness)
{
	float3 result = normalize(saturate(dot(view_direction, normal)) * 2 * normal - view_direction);

	result -= normal;
	result *= saturate(1.0 - roughness) * (sqrt(saturate(1.0 - roughness)) + roughness);
	result += normal;

	return result;
}

float ComputeIBLLevel(float roughness)
{
	float ibl_probe_lod = 6;
	return sqrt(saturate(roughness)) * ibl_probe_lod;
}

float4 ComputeSkyboxIBLColor(LightingParameters parameters, float ibl_occlusion)
{
	float3 reflection_direction = ComputeIBLDirection(parameters.world_normal, parameters.view_direction, parameters.roughness);
	float ibl_level = ComputeIBLLevel(parameters.roughness);

    float4 ibl_color = SampleTextureLevel(
		s_IBL,
		reflection_direction * float3(1,1,-1),
		ibl_level
	);

	ibl_color.xyz = lerp(
		max(0.0, exp2(log2(max(0.0, ibl_color.xyz + 1.0)) * u_ibl_param.x) - 1.0),
		ibl_color.xyz,
		parameters.shadow * ibl_occlusion
	);

    return ibl_color;
}

#endif