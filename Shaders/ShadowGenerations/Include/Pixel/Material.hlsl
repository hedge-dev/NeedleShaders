#ifndef MATERIAL_PIXEL_INCLUDED
#define MATERIAL_PIXEL_INCLUDED

// Note: When including this, always put it at the very top of your includes, below your shader features

#include "../Common.hlsl"

#if !defined(is_compute_instancing) && !defined(no_is_compute_instancing)
	DefineFeature(is_compute_instancing);
#endif

#if !defined(is_use_tex_srt_anim) && !defined(no_is_use_tex_srt_anim)
	DefineFeature(is_use_tex_srt_anim);
#endif

#if !defined(enable_deferred_rendering) && !defined(no_enable_deferred_rendering)
	DefineFeature(enable_deferred_rendering);
#endif

#if !defined(enable_alpha_threshold) && !defined(no_enable_alpha_threshold)
	DefineFeature(enable_alpha_threshold);
#endif

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