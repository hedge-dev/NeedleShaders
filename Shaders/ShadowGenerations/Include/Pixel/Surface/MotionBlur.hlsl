#ifndef MOTION_BLUR_SURFACE_INCLUDED
#define MOTION_BLUR_SURFACE_INCLUDED

#include "../../Transform.hlsl"

float2 ComputeVelocity(int2 pixel_position, float3 previous_position)
{
	float2 current = pixel_position - jitter_offset.xy;
	float2 previous = ClipToPixelSpace(previous_position) - jitter_offset.zw;
	return current - previous;
}

#endif