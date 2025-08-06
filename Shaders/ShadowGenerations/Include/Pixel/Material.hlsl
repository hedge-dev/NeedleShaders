#ifndef MATERIAL_PIXEL_INCLUDED
#define MATERIAL_PIXEL_INCLUDED

// Note: When including this, always put it at the very top of your includes, below your shader features

#include "../Common.hlsl"

#if !defined(enable_deferred_rendering) && !defined(no_enable_deferred_rendering)
	DefineFeature(enable_deferred_rendering);
#endif

#if !defined(is_use_tex_srt_anim) && !defined(no_is_use_tex_srt_anim)
	DefineFeature(is_use_tex_srt_anim);
#endif

#ifndef enable_deferred_rendering
	// Including here to get all the macros set
	#include "Lighting/CompositeMaterial.hlsl"
#endif

// Some more common includes so that we have to do those less

#include "../ConstantBuffer/World.hlsl"
#include "../ConstantBuffer/MaterialImmutable.hlsl"
#include "../ConstantBuffer/MaterialAnimation.hlsl"

#include "../Texture.hlsl"
#include "Surface/AlphaThreshold.hlsl"
#include "Surface/Common.hlsl"

#define SampleUV0(name) SampleTextureBiasedGl(name, TexUV(input.uv01.xy, name))
#define SampleUV1(name) SampleTextureBiasedGl(name, TexUV(input.uv01.zw, name))
#define SampleUV2(name) SampleTextureBiasedGl(name, TexUV(input.uv23.xy, name))
#define SampleUV3(name) SampleTextureBiasedGl(name, TexUV(input.uv23.zw, name))

#ifdef enable_deferred_rendering

	#define ProcessSurface(input, surface) SurfaceParamToData(surface)

#else

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