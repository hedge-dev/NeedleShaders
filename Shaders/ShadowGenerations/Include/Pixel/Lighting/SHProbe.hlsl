#ifndef SHPROBE_LIGHTING_INCLUDED
#define SHPROBE_LIGHTING_INCLUDED

#include "../../ConstantBuffer/World.hlsl"
#include "../../ConstantBuffer/SHLightFieldProbes.hlsl"
#include "../../Math.hlsl"

#include "LocalLights.hlsl"
#include "EnvironmentalProbe.hlsl"

bool UsingSHProbes()
{
	#ifdef disable_sh_probes
		return false;
	#else
		return true;
	#endif
}

bool AreSHProbesEnabled()
{
	return UsingSHProbes() && shlightfield_param.x > 0;
}

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

	float remainder = 1.0;
	float3 probes_color = 0.0;

	for(int i = 0; i < llh.env_probe_count && remainder > 0.0; i++)
	{
		uint probe_index = GetEnvProbeIndex(llh, i);
		EnvProbeData probe_data = GetEnvProbeData(probe_index);

		float probe_factor = ComputeProbeInfluence(probe_data, world_position);

		if (probe_factor <= 0.0)
		{
			continue;
		}

		float3 probe_color = ComputeSHColor(world_normal, probe_data.sh_colors);

		probe_factor = min(probe_factor, remainder);
		probes_color += probe_color * probe_factor;

		remainder -= probe_factor;
	}

	float3 result = ComputeSHColor(world_normal, GetSkySHColors());
	result *= ambient_occlusion;
	result += probes_color * u_sggi_param[1].w * (1.0 - ambient_occlusion);

	return result;
}

#endif