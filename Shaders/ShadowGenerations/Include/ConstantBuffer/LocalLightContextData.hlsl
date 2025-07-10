#ifndef LOCALLIGHTCONTEXTDATA_CONSTANTBUFFER_INCLUDED
#define LOCALLIGHTCONTEXTDATA_CONSTANTBUFFER_INCLUDED

cbuffer cb_local_light_context_data : register(b8)
{
    float4 g_local_light_count;
    float4 g_local_light_shadow_param[3];
    row_major float4x4 g_local_light_shadow_matrix[3];
    row_major float4x4 g_local_light_data[1000];
}

struct PositionalLightData
{
	float3 color;
	float3 position;
	float radius_squared;
	float3 direction;
	float factor_offset;
	float factor_strength;
	uint flags;
};

PositionalLightData GetPositionalLightData(int index)
{
	PositionalLightData result;
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

#endif