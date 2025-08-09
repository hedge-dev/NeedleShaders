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

#ifdef add_enable_multi_tangent_space
	#if !defined(enable_multi_tangent_space) && !defined(enable_multi_tangent_space)
		DefineFeature(enable_multi_tangent_space);
	#endif
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

#define UV0 input.uv01.xy
#define UV1 input.uv01.zw
#define UV2 input.uv23.xy
#define UV3 input.uv23.zw

#define SampleUV(name, uv) SampleTextureBiasedGl(name, TexUV(uv, name))
#define SampleUV0(name) SampleUV(name, UV0)
#define SampleUV1(name) SampleUV(name, UV1)
#define SampleUV2(name) SampleUV(name, UV2)
#define SampleUV3(name) SampleUV(name, UV3)

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