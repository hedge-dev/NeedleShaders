#ifndef LIGHTING_SURFACE_INCLUDED
#define LIGHTING_SURFACE_INCLUDED

#include "Struct.hlsl"

float3 LightSurface(SurfaceData surface)
{
	// TODO only placeholder rn
	return saturate(surface.albedo.rgb
		+ surface.emission.rgb
		+ surface.normal.rgb
		+ surface.prm.rgb
		+ surface.o4.rgb
		+ surface.o5.rgb
		+ surface.albedo.www
		+ surface.emission.www
		+ surface.prm.www);
}

#endif