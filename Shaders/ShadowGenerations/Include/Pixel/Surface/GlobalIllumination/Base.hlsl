#ifndef BASE_GI_SURFACE_INCLUDED
#define BASE_GI_SURFACE_INCLUDED

#include "../../../Debug.hlsl"

#include "../Struct.hlsl"

#include "Common.hlsl"
#include "SphericalGaussian.hlsl"

void ApplyGlobalIllumination(inout SurfaceParameters parameters)
{
	int debug_mode = GetDebugView();
	int gi_disable_type = GetDebugGITexDisableType();

	float3 gi_diffuse = 0.0;
	float3 gi_specular = 0.0;

	if(UsingDefaultGI)
	{
		gi_diffuse = SampleGITexture(parameters.gi_uv, 0.0).xyz;
	}
	else if(UsingSGGI)
	{
		ComputeSGGIColors(
			parameters,
			gi_diffuse,
			gi_specular
		);
	}

	float3 color_1 = 0.0;

	if(!IsAOGIEnabled())
	{
		color_1 = gi_diffuse;
		color_1 *= 1.0 - parameters.metallic;
		color_1 *= 1.0 - parameters.fresnel_reflectance;
	}

	if(debug_mode == DebugView_User2 || debug_mode == DebugView_Ambient)
	{
		parameters.emission.xyz = color_1;
		return;
	}

	float3 color_2 = color_1 * parameters.albedo;
	float3 color_3 = gi_specular;

	if(GetDebugAmbientSpecularType() == DebugAmbientSpecularType_Blend)
	{
		color_3 *= saturate(u_sggi_param[0].y * (parameters.roughness - u_sggi_param[0].x));
	}

	if(gi_disable_type == DebugGITex_DisableSGGI || gi_disable_type == DebugGITex_DisableAll)
	{
		color_3 = gi_specular;
	}

	color_2 *= parameters.cavity;
	color_3 *= parameters.cavity;

	// Note: This is probably something else that gets added together with emission,
	// but it has yet to be found where this would happen.
	float3 color_4 = parameters.emission;

	switch(debug_mode)
	{
		case DebugView_AmbDiffuse:
		case DebugView_AmbDiffuseLf:
			color_2 = color_1;
			color_3 = 0.0;
			color_4 = parameters.emission;
			break;

		case DebugView_AmbSpecular:
			color_2 = 0.0;
			color_3 = gi_specular;
			color_4 = parameters.emission;
			break;

		case DebugView_SggiOnly:
			color_4 = 0.0;
			break;
	}

	parameters.emission.xyz = color_2 + color_3 + color_4;
}

#endif