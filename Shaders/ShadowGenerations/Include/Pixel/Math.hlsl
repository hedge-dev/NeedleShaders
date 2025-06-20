#ifndef MATH_PIXEL_INCLUDED
#define MATH_PIXEL_INCLUDED

#include "../ConstantBuffer/World.hlsl"

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

#endif