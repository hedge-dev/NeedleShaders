#ifndef TRANSFORM_INCLUDED
#define TRANSFORM_INCLUDED

#include "ConstantBuffer/World.hlsl"

int2 ClipToPixelSpace(float3 position)
{
	float2 result = position.xy / position.z;
	result.y = -result.y;
	result *= 0.5;
	result += 0.5;
	result *= u_viewport_info.xy;

	return (int2)result;
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

float DepthToViewDistance(float depth)
{
	return -u_view_param.x / (depth * u_view_param.w - u_view_param.z);
}

float ViewDistanceToDepth(float view_distance)
{
	// has to be verified!
	return (view_distance * -u_view_param.x + u_view_param.z) / u_view_param.w;
}

float3 RotateX(float3 position, float angle)
{
	float sin, cos;
	sincos(angle, sin, cos);

	return float3(
		position.x,
		cos * position.y - sin * position.z,
		sin * position.y + cos * position.z
	);

}

float3 RotateY(float3 position, float angle)
{
	float sin, cos;
	sincos(angle, sin, cos);

	return float3(
		sin * position.z + cos * position.x,
		position.y,
		cos * position.z - sin * position.x
	);
}

float3 RotateZ(float3 position, float angle)
{
	float sin, cos;
	sincos(angle, sin, cos);

	return float3(
		cos * position.x - sin * position.y,
		sin * position.x + cos * position.y,
		position.z
	);
}

#endif