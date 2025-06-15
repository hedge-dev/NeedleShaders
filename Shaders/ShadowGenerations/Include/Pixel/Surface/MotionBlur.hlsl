#ifndef MOTION_BLUR_SURFACE_INCLUDED
#define MOTION_BLUR_SURFACE_INCLUDED

#include "../../Transform.hlsl"

float2 ComputeMotionVector(float3 position, float3 previous_position)
{
	float2 current = position.xy - jitter_offset.xy;
	float2 previous = ClipToScreenSpace(previous_position) - jitter_offset.zw;
	return current - previous;
}

#endif