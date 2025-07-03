#ifndef DEFERRED_PIXEL_INCLUDED
#define DEFERRED_PIXEL_INCLUDED

#include "Surface/Struct.hlsl"

struct DeferredData
{
	SurfaceData surface;
	float depth;
};

Texture2D<float4> s_GBuffer0;
Texture2D<float4> s_GBuffer1;
Texture2D<float4> s_GBuffer2;
Texture2D<float4> s_GBuffer3;
Texture2D<float4> s_Velocity;

Texture2D<float4> s_DepthBuffer;

DeferredData LoadDeferredData(uint2 pixel_position)
{
	DeferredData result;
	uint3 load_pos = int3(pixel_position, 0);

	result.surface.albedo = s_GBuffer0.Load(load_pos);
	result.surface.normal = s_GBuffer1.Load(load_pos).xyz;
	result.surface.emission = s_GBuffer2.Load(load_pos);
	result.surface.prm = s_GBuffer3.Load(load_pos);
	result.surface.velocity = s_Velocity.Load(load_pos);
	result.surface.o5 = 0.0; // no idea what the texture for this would be called yet

	result.depth = s_DepthBuffer.Load(load_pos).xy;

	return result;
}

#endif