#ifndef SHPROBE_LIGHTING_INCLUDED
#define SHPROBE_LIGHTING_INCLUDED

#include "../../ConstantBuffer/World.hlsl"
#include "LocalLights.hlsl"
#include "../../Math.hlsl"

float3 ComputeSHColor(float3 world_normal, SHColors sh_colors)
{
	float sh_factors[9] = {
		0.886227667,
		-1.02381635 *  world_normal.y,
		-1.02381635 *  world_normal.z,
		-1.02381635 *  world_normal.x,
		0.858085036 *  world_normal.x * world_normal.y,
		0.858085036 *  world_normal.z * world_normal.y,
		0.247708231 * (world_normal.z * world_normal.z * 3 - 1),
		0.858085036 *  world_normal.z * world_normal.x,
		0.429042518 * (world_normal.x * world_normal.x - world_normal.y * world_normal.y)
	};

	float3 result = 0.0;

	for(int i = 0; i < 9; i++)
	{
		result += sh_colors.colors[i] * sh_factors[i];
	}

	return result / Pi;
}

float3 ComputeSHProbeColor(uint2 tile_position, float4 world_position, float3 world_normal, float ambient_occlusion)
{
	LocalLightHeader llh = GetLocalLightHeader(tile_position);

	float shprobe_remainder = 1.0;
	float3 shprobe_colors = 0.0;

	for(int i = 0; i < llh.shprobe_count && shprobe_remainder > 0.0; i++)
	{
		uint probe_index = GetSHProbeIndex(llh, i);
		SHProbeData probe_data = GetSHProbeData(probe_index);

		float probe_factor;

		if (probe_data.type == 3 || probe_data.type == 2)
		{
			probe_factor = length(world_position.xyz - probe_data.position) / probe_data.unk2;
		}
		else
		{
			float3 probe_pos = mul(probe_data.inv_world_matrix, world_position);
			probe_factor = max(max(abs(probe_pos.x), abs(probe_pos.y)), abs(probe_pos.z));
		}

		if(probe_factor > 0.99)
		{
			continue;
		}

		float t = (1.0 - clamp(g_probe_param[probe_index].y, 0.01, 0.99));

		probe_factor -= g_probe_param[probe_index].y;
		probe_factor = saturate(1 - probe_factor / t);

		if (probe_factor <= 0.0)
		{
			continue;
		}

		float3 probe_color = ComputeSHColor(world_normal, probe_data.sh_colors);

		probe_factor = min(probe_factor, shprobe_remainder);
		shprobe_colors += probe_color * probe_factor;

		shprobe_remainder -= probe_factor;
	}

	float3 result = ComputeSHColor(world_normal, GetSkySHColors());
	result *= ambient_occlusion;
	result += shprobe_colors * u_sggi_param[1].w * (1.0 - ambient_occlusion);

	return result;
}

#endif