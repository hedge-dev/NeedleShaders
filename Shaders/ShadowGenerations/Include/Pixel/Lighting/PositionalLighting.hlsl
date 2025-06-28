#ifndef POSITIONAL_LIGHTING_INCLUDED
#define POSITIONAL_LIGHTING_INCLUDED

#include "../../ConstantBuffer/World.hlsl"
#include "../../ConstantBuffer/LocalLightContextData.hlsl"

#include "../../Transform.hlsl"
#include "../../Texture.hlsl"

#include "Struct.hlsl"
#include "SubsurfaceScattering.hlsl"
#include "Light.hlsl"
#include "LocalLights.hlsl"

TextureCubeArray<float4> WithSamplerComparison(s_LocalShadowMap);

static const float2 shadow_angles[5] = {
	{ 0.0, 0.0 },
	{ 1.0, 1.0 },
	{ 1.0, -1.0 },
	{ -1.0, 1.0 },
	{ -1.0, -1.0 }
};

float ComputeShadowSomething(LightingParameters parameters, uint index)
{
	float4 shadow_param = g_local_light_shadow_param[index];

	if(index < 0 || abs(shadow_param.w) <= 0.01)
	{
		return 1.0;
	}

	float3 shadow_offset = parameters.world_position.xyz - shadow_param.xyz;
	float shadow_distance = length(shadow_offset);

	float4x4 shadow_matrix = g_local_light_shadow_matrix[index];

	float compare_value;

	if(shadow_param.w < 0.0)
	{
		float4 shadow_offset_2 = mul(parameters.world_position, shadow_matrix);
		shadow_offset_2 /= shadow_offset_2.w;

		compare_value = shadow_offset_2.z;
		shadow_offset = shadow_distance * normalize(float3(1, shadow_offset_2.y, -shadow_offset_2.x));
	}
	else
	{
		float max_dist = max(max(abs(shadow_offset.x), abs(shadow_offset.y)), abs(shadow_offset.z));
		float2 t2 = shadow_matrix._m32_m33 - shadow_matrix._m22_m23 * max_dist;
		compare_value = t2.x / t2.y;
	}

	float result;

	for(int i = 0; i < 5; i++)
	{
		float3 rotated_offset = shadow_offset;
		rotated_offset = RotateX(rotated_offset, shadow_angles[i].x * 0.002);
		rotated_offset = RotateY(rotated_offset, shadow_angles[i].y * 0.002);

		result += SampleTextureCmpLevelZero(
			s_LocalShadowMap,
			float4(rotated_offset, index),
			compare_value - 0.001
		).x;
	}

	result *= 0.2;
	result += smoothstep(0.0, 1.0, -2.5 * (shadow_distance - 1.0));
	result = min(result, 0.1);

	return lerp(1.0, result, abs(shadow_param.w));
}

void CalculateLight(LightingParameters parameters, PositionalLightData light_data, out float3 out_diffuse, out float3 out_specular)
{
	out_diffuse = 0.0;
	out_specular = 0.0;

	if(!(light_data.flags & (1 << parameters.flags_unk2)))
	{
		return;
	}

	float3 light_offset = light_data.position - parameters.world_position.xyz;
	float light_distance_squared = dot(light_offset, light_offset);

	if(light_distance_squared >= light_data.radius_squared
		&& abs(light_data.color.x + light_data.color.y + light_data.color.z) >= 0.000001)
	{
		return;
	}

	float3 light_direction = normalize(light_offset);

	float light_base = 1.0;

	if(0x100 & light_data.flags)
	{
		light_base = dot(light_data.direction, -light_direction);
		light_base -= light_data.factor_offset;
		light_base *= light_data.factor_strength;
		light_base = saturate(light_base);
		light_base *= light_base;

		if(light_base < 0.000001)
		{
			return;
		}
	}

	float light_mask = light_distance_squared / light_data.radius_squared;
	light_mask = saturate(1 - light_mask * light_mask);
	light_mask *= light_mask;

	float light_attenuation = light_base / max(1.0, light_distance_squared);
	light_attenuation *= light_mask;

	float3 light_color = light_data.color / (Pi * 4.0);

	uint shadow_index = UnpackUIntBits(light_data.flags, 3, 16) - 1;
	light_attenuation *= ComputeShadowSomething(parameters, shadow_index);

	if(light_data.flags & 0x10)
	{
		out_diffuse = DiffuseBDRF(parameters, light_direction, light_color, 1.0) * light_attenuation;
	}

	if(light_data.flags & 0x20)
	{
		out_specular = SpecularBRDF(parameters, light_direction, light_color, 1.0, false) * light_attenuation;
	}
}

void ComputePositionalLighting(LightingParameters parameters, out float3 out_diffuse, out float3 out_specular)
{
	out_diffuse = 0.0;
	out_specular = 0.0;

	if(g_local_light_count.x == 0)
	{
		return;
	}

	LocalLightHeader llh = GetLocalLightHeader(parameters.tile_position);

	for(int i = 0; i < llh.positional_light_count; i++)
	{
		uint light_index = GetLightIndex(llh, i);
		PositionalLightData light_data = GetPositionalLightData(light_index);

		float3 light_diffuse, light_specular;
		CalculateLight(parameters, light_data, light_diffuse, light_specular);

		out_diffuse += light_diffuse;
		out_specular += light_specular;
	}
}

#endif