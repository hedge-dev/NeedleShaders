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

#endif