#ifndef SGLIGHTFIELD_LIGHTING_INCLUDED
#define SGLIGHTFIELD_LIGHTING_INCLUDED

#include "../../ConstantBuffer/SHLightfieldProbes.hlsl"

#include "../../Texture.hlsl"
#include "../../Math.hlsl"

Texture3D<float4> WithSampler(s_SHLightField0);
Texture3D<float4> WithSampler(s_SHLightField1);
Texture3D<float4> WithSampler(s_SHLightField2);

static const float3 SGLightFieldAxis[6] =
{
	float3(3, 0, 0),
	float3(-3, 0, 0),
	float3(0, 3, 0),
	float3(0, -3, 0),
	float3(0, 0, 3),
	float3(0, 0, -3),
};

struct SGLightFieldInfo
{
	float3 position;
	bool in_field;
	SHLightFieldData data;
	float3 axis_colors[6];
};

SHLightFieldData FindClostestSGLightField(float4 world_position, out bool in_field)
{
	float clostest_dist_sq = -1.0;
	int closest_prob_index = 0;
	in_field = false;

	for(uint i = 0; i < SGLightFieldCount; i++)
	{
		float3 lfp_position = mul(world_position, GetSGLightFieldData(i).inv_world_matrix).xyz;

		if(abs(lfp_position.x) <= 0.5
			&& abs(lfp_position.y) <= 0.5
			&& abs(lfp_position.z) <= 0.5)
		{
			in_field = true;
			closest_prob_index = i;
			break;
		}

		float distance_sq = dot(lfp_position, lfp_position);

		if(clostest_dist_sq < 0.0 || distance_sq < clostest_dist_sq)
		{
			clostest_dist_sq = distance_sq;
			closest_prob_index = i;
		}
	}

	return GetSGLightFieldData(closest_prob_index);
}

SGLightFieldInfo ComputeSGLightFieldInfo(float4 world_position, float3 world_normal)
{
	SGLightFieldInfo result;
	result.data = FindClostestSGLightField(world_position, result.in_field);

	result.position = mul(world_position, result.data.inv_world_matrix).xyz;
	float3 lfp_normal = normalize(mul(world_normal, (float3x3)result.data.inv_world_matrix));

	float3 sample_position = saturate(result.position + 0.5);
	sample_position += lfp_normal * shlightfield_param.z / result.data.scale;

	sample_position = clamp(
		sample_position,
		0.5 / result.data.scale,
		1 - (0.5 / result.data.scale)
	);

	float3 tile_width = float3(1.0 / 9.0, 0.0, 0.0);
	sample_position.x *= tile_width.x;

	SamplerState lf_sampler;
	Texture3D<float4> lf_texture;

	switch(result.data.index)
	{
		case 0:
			for(int i0 = 0; i0 < 6; i0++)
			{
				result.axis_colors[i0] = SampleTextureLevel(s_SHLightField0, sample_position, 0).xyz;
				sample_position += tile_width;
			}
			break;
		case 1:
			for(int i1 = 0; i1 < 6; i1++)
			{
				result.axis_colors[i1] = SampleTextureLevel(s_SHLightField1, sample_position, 0).xyz;
				sample_position += tile_width;
			}
			break;
		default:
			for(int i2 = 0; i2 < 6; i2++)
			{
				result.axis_colors[i2] = SampleTextureLevel(s_SHLightField2, sample_position, 0).xyz;
				sample_position += tile_width;
			}
			break;
	}


	return result;
}

float ComputeSGLightFieldFactor(float3 world_normal, int index)
{
	float3 normal = world_normal * 32.0 / 15.0;
	normal.z = -normal.z;
	normal += SGLightFieldAxis[index];
	float l = length(normal);

	float result = 14.7026539;
	result *= (exp(l) - exp(-l)) * 0.5;
	result /= l * 169.524918;
	return result;
}

float3 ComputeSGLightFieldColor(float3 world_normal, float3 axis_colors[6])
{
	float3 result = 0.0;

	for(int i = 0; i < 6; i++)
	{
		result += axis_colors[i] * ComputeSGLightFieldFactor(world_normal, i);
	}

	return result / Pi;
}

#endif