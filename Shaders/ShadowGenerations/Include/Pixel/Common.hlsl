#ifndef COMMON_PIXEL_INCLUDED
#define COMMON_PIXEL_INCLUDED

#include "../IOStructs.hlsl"

#ifdef enable_deferred_rendering

	#define ProcessSurface(surface) surface

#else

	#include "Surface/Struct.hlsl"
	PixelOutput ProcessSurface(SurfaceData surface)
	{
		PixelOutput result;

		// placeholder until lighting code is done
		result.Color.xyz = saturate(surface.albedo.rgb
			+ surface.emission.rgb
			+ surface.normal.rgb
			+ surface.prm.rgb
			+ surface.velocity.rgg
			+ surface.o5.rgg
			+ surface.albedo.www
			+ surface.emission.www
			+ surface.prm.www
		);

		result.Color.w = 1.0f;
		return result;
	}

#endif

#endif