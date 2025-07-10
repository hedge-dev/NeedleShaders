#ifndef LOCAL_LIGHTS_LIGHTING_INCLUDED
#define LOCAL_LIGHTS_LIGHTING_INCLUDED

#include "../../ConstantBuffer/World.hlsl"

static const uint max_light_count = 64;
StructuredBuffer<int> s_LocalLightIndexData;

// the regular _count is for lights/probes that have been masked to the tiles they are applied on,
// while _vol_count is for where they are spatially (to see the room they occupy), even if not applied

struct LocalLightHeader
{
	int positional_light_count;
	int positional_light_vol_count;
	int positional_light_data_offset;

	int occlusion_capsule_count;
	int occlusion_capsule_vol_count;
	int occlusion_capsule_data_offset;

	int env_probe_count;
	int env_probe_vol_count;
	int env_probe_data_offset;
};

LocalLightHeader GetLocalLightHeader(uint2 tile_position)
{
	LocalLightHeader result = {
		0, 0, 0,
		0, 0, 0,
		0, 0, 0,
	};

	uint2 tile_resolution = ((uint2)u_tile_info.zw + 0xF) >> 4;

	if(tile_position.x >= tile_resolution.x
		|| tile_position.y >= tile_resolution.y)
	{
		return result;
	}

	int tile_index = (tile_position.y * (int)u_tile_info.x + tile_position.x) * 3;

	result.positional_light_count = min(max_light_count, s_LocalLightIndexData[tile_index] & 0xFFFF);
	result.positional_light_vol_count = min(max_light_count, s_LocalLightIndexData[tile_index] >> 16);
	result.positional_light_data_offset = (tile_index * max_light_count) + (int)u_tile_info.y;

	tile_index++;

	result.occlusion_capsule_count = min(max_light_count, s_LocalLightIndexData[tile_index] & 0xFFFF);
	result.occlusion_capsule_vol_count = min(max_light_count, s_LocalLightIndexData[tile_index] >> 16);
	result.occlusion_capsule_data_offset = (tile_index * max_light_count) + (int)u_tile_info.y;

	tile_index++;

	result.env_probe_count = min(max_light_count, s_LocalLightIndexData[tile_index] & 0xFFFF);
	result.env_probe_vol_count = min(max_light_count, s_LocalLightIndexData[tile_index] >> 16);
	result.env_probe_data_offset = (tile_index * max_light_count) + (int)u_tile_info.y;

	return result;
}

int GetPositionalLightIndex(LocalLightHeader header, int index)
{
	return s_LocalLightIndexData[header.positional_light_data_offset + index] & 0xFFFF;
}

int GetOcclusionCapsuleIndex(LocalLightHeader header, int index)
{
	return s_LocalLightIndexData[header.occlusion_capsule_data_offset + index] & 0xFFFF;
}

int GetEnvProbeIndex(LocalLightHeader header, int index)
{
	return s_LocalLightIndexData[header.env_probe_data_offset + index] & 0xFFFF;
}

#endif