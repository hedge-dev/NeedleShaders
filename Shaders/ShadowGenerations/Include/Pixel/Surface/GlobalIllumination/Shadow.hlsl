#ifndef SHADOW_GI_SURFACE_INCLUDED
#define SHADOW_GI_SURFACE_INCLUDED

#include "../../../ConstantBuffer/MaterialDynamic.hlsl"
#include "../../../ConstantBuffer/SHLightFieldProbes.hlsl"

#include "Common.hlsl"

TextureInput(gi_shadow_texture)

float GetGIShadow(float2 gi_uv)
{
	bool disable_gi_shadow = true;
	float gi_shadow = 1.0;

	#ifdef is_use_gi

		uint gi_mode = GetGIMode();

		#if defined(is_use_gi_sg)

			if (gi_mode != 1 && gi_mode != 3)
			{
				gi_shadow = SampleTexture(gi_shadow_texture, gi_uv).x;
			}

		#elif !defined(is_use_gi_prt)

			gi_shadow =
				SampleTexture(gi_shadow_texture, gi_uv).x
				* SampleTexture(gi_texture, gi_uv).w;

		#endif

		disable_gi_shadow =
			gi_mode == GIMode1
			|| gi_mode == GIMode2
			|| gi_mode == GIMode3
			|| gi_mode == GIMode6;

		#ifdef is_use_gi_prt
			disable_gi_shadow = disable_gi_shadow
				|| gi_mode == GIMode0;

			#ifndef is_use_gi_sg
				disable_gi_shadow = disable_gi_shadow
					|| gi_mode == GIMode5;
			#endif
		#endif

	#endif

	float result = shlightfield_param.x > 0 && disable_gi_shadow ? 0.0001 : gi_shadow;

	if(!disable_gi_shadow)
	{
		#if defined(is_use_gi_sg)
			result += 30.0;
		#elif defined(is_use_gi_prt)
			result += 20.0;
		#else
			result += 10.0;
		#endif
	}

	return enable_shadow_map
		? result
		: -result;
}

#endif