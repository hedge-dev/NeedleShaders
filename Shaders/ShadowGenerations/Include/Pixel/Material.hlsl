#ifndef MATERIAL_PIXEL_INCLUDED
#define MATERIAL_PIXEL_INCLUDED

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