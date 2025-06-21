#ifndef TRANSFORM_INCLUDED
#define TRANSFORM_INCLUDED

#include "ConstantBuffer/World.hlsl"

float2 ClipToScreenSpace(float3 position)
{
	float2 result = position.xy / position.z;
	result.y = -result.y;
	result += 1.0;
	result *= u_viewport_info.xy;
	result *= 0.5;

	return result;
}

float4 ScreenDepthToWorldPosition(float2 screen_uv, float depth)
{
	float4 projection_position = float4(
		u_viewport_info.zw * screen_uv * float2(2.0,-2.0) + float2(-1.0,1.0),
		depth,
		1.0
	);

	float4 world_position = mul(projection_position, inv_view_proj_matrix);
	return float4(world_position.xyz / world_position.w, 1.0);
}

float2 PixelToScreen(uint2 pixel_index)
{
	// Making sure the pixel is in bounds
	pixel_index = min((uint2)u_viewport_info.xy, pixel_index);
	return (pixel_index + 0.5) / u_screen_info.xy;
}

#endif