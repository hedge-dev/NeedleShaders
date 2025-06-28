#ifndef LOCAL_LIGHTS_LIGHTING_INCLUDED
#define LOCAL_LIGHTS_LIGHTING_INCLUDED

#include "../../ConstantBuffer/World.hlsl"

static const uint max_light_count = 64;
StructuredBuffer<int> s_LocalLightIndexData;

struct LocalLightHeader
{
	int positional_light_count;
	int shprobe_count;
	int data_offset;
};

LocalLightHeader GetLocalLightHeader(uint2 tile_position)
{
	LocalLightHeader result = { 0, 0, 0 };

	uint2 tile_resolution = ((uint2)u_tile_info.zw + 15) >> 4;

	if(tile_position.x >= tile_resolution.x
		|| tile_position.y >= tile_resolution.y)
	{
		return result;
	}

	int tile_index = (tile_position.y * (int)u_tile_info.x + tile_position.x) * 3;

	result.positional_light_count = min(max_light_count, s_LocalLightIndexData[tile_index] & 0xFFFF);
	result.shprobe_count = min(max_light_count, s_LocalLightIndexData[tile_index + 2] & 0xFFFF);
	result.data_offset = (tile_index * max_light_count) + (int)u_tile_info.y;

	return result;
}

int GetLightIndex(LocalLightHeader header, int index)
{
	return s_LocalLightIndexData[header.data_offset + index] & 0xFFFF;
}

#endif