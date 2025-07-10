#ifndef MATERIAL_PIXEL_INCLUDED
#define MATERIAL_PIXEL_INCLUDED

// Note: When including this, always put it at the very top of your includes, below your shader features

#include "../IOStructs.hlsl"
#include "Surface/Struct.hlsl"

#ifdef enable_deferred_rendering

	#define ProcessSurface(input, surface) SurfaceParamToData(surface)

#else

	#include "Lighting/CompositeMaterial.hlsl"
	PixelOutput ProcessSurface(PixelInput input, SurfaceParameters surface)
	{
		LightingParameters parameters = LightingParametersFromSurface(input, surface);
		parameters.approximate_env_brdf = false;

		PixelOutput result;
		result.Color = CompositeMaterialLighting(parameters, surface.transparency);
		return result;
	}

#endif

#endif