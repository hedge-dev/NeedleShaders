#ifndef MOTION_BLUR_SURFACE_INCLUDED
#define MOTION_BLUR_SURFACE_INCLUDED

#include "../../ConstantBuffer/World.hlsl"

float2 GetMotionVector(float2 position, float3 prev_position)
{
	float2 start = prev_position.xy / prev_position.z;
	start.y = -start.y;
	start += 1.0;
	start *= u_viewport_info.xy;
	start *= 0.5;
	start -= jitter_offset.zw;

	float2 end = position - jitter_offset.xy;

	return end - start;
}

#endif