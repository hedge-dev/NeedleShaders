#ifndef LIGHTING_SURFACE_INCLUDED
#define LIGHTING_SURFACE_INCLUDED

#include "Struct.hlsl"

float3 LightSurface(SurfaceData surface)
{
	// TODO only placeholder rn
	return surface.albedo.rgb;
}

#endif