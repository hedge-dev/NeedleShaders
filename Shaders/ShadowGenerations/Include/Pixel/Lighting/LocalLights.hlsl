#ifndef LOCALLIGHTS_LIGHTING_INCLUDED
#define LOCALLIGHTS_LIGHTING_INCLUDED

#include "../../ConstantBuffer/World.hlsl"
#include "../../ConstantBuffer/LocalLightContextData.hlsl"

#include "../../Transform.hlsl"
#include "../../Texture.hlsl"

#include "Struct.hlsl"
#include "SubsurfaceScattering.hlsl"
#include "Light.hlsl"

StructuredBuffer<int> s_LocalLightIndexData;
TextureCubeArray<float4> WithSamplerComparison(s_LocalShadowMap);

static const uint max_light_count = 64;

static const float2 shadow_angles[5] = {
	{ 0.0, 0.0 },
	{ 1.0, 1.0 },
	{ 1.0, -1.0 },
	{ -1.0, 1.0 },
	{ -1.0, -1.0 }
};

struct LightInfo
{
	float3 color;
	float3 position;
	float radius_squared;
	float3 direction;
	float factor_offset;
	float factor_strength;
	uint flags;
};

LightInfo GetLightInfo(int index)
{
	LightInfo result;
	float4x4 data = g_local_light_data[index];

	result.color = data._m00_m01_m02;
	// m03 missing

	result.position = data._m10_m11_m12;
	result.radius_squared = data._m13;

	result.direction = data._m20_m21_m22;
	// m23 missing

	result.factor_offset = data._m30;
	result.factor_strength = data._m31;
	// m32 missing
	result.flags = asuint(data._m33);

	return result;
}

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

void CalculateLight(LightingParameters parameters, LightInfo light_info, float3 blue_emission_thing, out float3 out_light_color, out float3 out_sss_color)
{
	out_light_color = 0.0;
	out_sss_color = 0.0;

	if(!(light_info.flags & (1 << parameters.flags_unk2)))
	{
		return;
	}

	float3 light_offset = light_info.position - parameters.world_position.xyz;
	float light_distance_squared = dot(light_offset, light_offset);

	if(light_distance_squared >= light_info.radius_squared
		&& abs(light_info.color.x + light_info.color.y + light_info.color.z) >= 0.000001)
	{
		return;
	}

	float3 light_direction = normalize(light_offset);

	float light_base = 1.0;

	if(0x100 & light_info.flags)
	{
		light_base = dot(light_info.direction, -light_direction);
		light_base -= light_info.factor_offset;
		light_base *= light_info.factor_strength;
		light_base = saturate(light_base);
		light_base *= light_base;

		if(light_base < 0.000001)
		{
			return;
		}
	}

	float light_mask = light_distance_squared / light_info.radius_squared;
	light_mask = saturate(1 - light_mask * light_mask);
	light_mask *= light_mask;

	float light_attenuation = light_base / max(1.0, light_distance_squared);
	light_attenuation *= light_mask;

	float cos_light_direction = saturate(dot(light_direction, parameters.world_normal));

	float3 light_color = light_info.color / (Pi * 4.0);


	uint shadow_index = UnpackUIntBits(light_info.flags, 3, 16) - 1;
	float shadow_something = ComputeShadowSomething(parameters, shadow_index);

	if(light_info.flags & 0x20)
	{
		out_light_color = light_color
			* cos_light_direction
			* light_attenuation
			* SpecularBRDF(parameters, light_direction, light_color)
			* shadow_something;
	}

	if(light_info.flags & 0x10)
	{
		float3 cld3 = cos_light_direction;

		#ifndef enable_ssss
			if (parameters.shading_mode == 3)
			{
				float t = saturate(dot(light_direction, parameters.world_normal) * 0.5 + 0.5);
				cld3 = SampleTextureLevel(s_Common_CDRF, float3(t, blue_emission_thing.x, blue_emission_thing.y), 0).xyz;
			}
		#endif

		float3 fresnel = ComputeFresnelColor(parameters, light_direction);

		out_sss_color = cld3
			* (1.0 - fresnel.x)
			* (1.0 - parameters.metallic)
			* light_attenuation
			* shadow_something;
	}
}

void GetLightColors(LightingParameters parameters, float3 blue_emission_thing, out float3 out_light_color, out float3 out_sss_color)
{
	out_light_color = 0.0;
	out_sss_color = 0.0;

	uint light_count = g_local_light_count.x;
	if(light_count == 0)
	{
		return;
	}

	uint2 tile_resolution = ((uint2)u_tile_info.zw + 15) >> 4;

	if(parameters.tile_position.x >= tile_resolution.x
		|| parameters.tile_position.y >= tile_resolution.y)
	{
		return;
	}

	int tile_index = (parameters.tile_position.y * (int)u_tile_info.x + parameters.tile_position.x) * 3;
	int tile_light_count = min(max_light_count, s_LocalLightIndexData[tile_index] & 0xFFFF);
	int tile_light_data_offset = (tile_index * max_light_count) + (int)u_tile_info.y;

	for(int i = 0; i < tile_light_count; i++)
	{
		uint light_index = s_LocalLightIndexData[tile_light_data_offset + i] & 0xFFFF;
		LightInfo light_info = GetLightInfo(light_index);

		float3 light_color, sss_color;
		CalculateLight(parameters, light_info, blue_emission_thing, light_color, sss_color);

		out_light_color += light_color;
		out_sss_color += sss_color;
	}
}

#endif