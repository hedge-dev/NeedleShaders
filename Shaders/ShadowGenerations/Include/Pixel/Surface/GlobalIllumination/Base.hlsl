#ifndef BASE_GI_SURFACE_INCLUDED
#define BASE_GI_SURFACE_INCLUDED

#include "../../../Debug.hlsl"
#include "../../PBRUtils.hlsl"

#include "Common.hlsl"
#include "SphericalGaussian.hlsl"

float3 ComputeIllumination(
	float2 gi_uv,
	float3 world_position,
	float3 albedo,
	float3 emission,
	PBRParameters pbrParameters)
{
	int debug_mode = GetDebugMode();
	int debug2_mode = GetDebug2Mode();
	int gi_mode = GetGIMode();

	float3 gi_color = 0.0;
	float3 gi_color_2 = 0.0;

	#ifdef is_use_gi
		#if defined(is_use_gi_sg)
			GetSphericalGaussianGI(
				gi_uv,
				world_position,
				gi_color_2,
				gi_color
			);
		#elif !defined(is_use_gi_prt)
			gi_color = SampleTexture(gi_texture, gi_uv).xyz;
		#endif
	#endif

	float3 color_1 = 0.0;

	if(!IsAOGIEnabled())
	{
		color_1 = gi_color;
		color_1 *= 1.0 - pbrParameters.metallic;
		color_1 *= 1.0 - lerp(
			pbrParameters.specular,
			albedo,
			pbrParameters.metallic
		);
	}

	if(debug_mode == DebugMode12 || debug_mode == DebugMode19)
	{
		return color_1;
	}

	float3 color_2 = color_1 * albedo;
	float3 color_3 = gi_color_2;

	if(debug2_mode == Debug2Mode3)
	{
		color_3 *= saturate(u_sggi_param[0].y * (pbrParameters.roughness - u_sggi_param[0].x));
	}

	if(gi_mode == 1 || gi_mode == 3)
	{
		color_3 = gi_color_2;
	}

	color_2 *= pbrParameters.ambient_occlusion;
	color_3 *= pbrParameters.ambient_occlusion;

	// Note: This is probably something else that gets added together with emission,
	// but it has yet to be found where this would happen.
	float3 color_4 = emission;

	switch(debug_mode)
	{
		case DebugMode3:
		case DebugMode43:
			color_2 = color_1;
			color_3 = 0.0;
			color_4 = emission;
			break;

		case DebugMode4:
			color_2 = 0.0;
			color_3 = gi_color_2;
			color_4 = emission;
			break;

		case DebugMode44:
			color_4 = 0.0;
			break;
	}

	return color_2 + color_3 + color_4;
}

#endif