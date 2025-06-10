#ifndef COMMON_PIXEL_INCLUDED
#define COMMON_PIXEL_INCLUDED

#include "../IOStructs.hlsl"

#ifdef enable_deferred_rendering

	#define ProcessSurface(surface) surface

#else

	#include "Surface/Lighting.hlsl"
	PixelOutput ProcessSurface(SurfaceData surface)
	{
		PixelOutput result;
		result.Color.xyz = LightSurface(surface);
		result.Color.w = 1.0f;
		return result;
	}

#endif

#endif