#ifndef COMPOSITE_LIGHTING_INCLUDED
#define COMPOSITE_LIGHTING_INCLUDED

#include "../../ConstantBuffer/World.hlsl"
#include "../../ConstantBuffer/SHLightfieldProbes.hlsl"
#include "../../ConstantBuffer/LocalLightContextData.hlsl"

#include "../../Math.hlsl"
#include "../../Debug.hlsl"
#include "../../Texture.hlsl"
#include "../../Transform.hlsl"
#include "../../LightScattering.hlsl"
#include "../../Transform.hlsl"

#include "../Normals.hlsl"
#include "../ShadowCascade.hlsl"

#include "Struct.hlsl"
#include "SubsurfaceScattering.hlsl"
#include "PositionalLighting.hlsl"
#include "Fog.hlsl"
#include "Light.hlsl"
#include "Ambient.hlsl"
#include "Reflection.hlsl"

Texture2D<float4> WithSampler(s_EnvBRDF);
Texture2D<float4> WithSampler(s_SSAO);
Texture2D<float4> WithSampler(s_RLR);
TextureCubeArray<float4> WithSampler(s_IBLProbeArray);

float4 CompositeLighting(LightingParameters parameters)
{
	//////////////////////////////////////////////////
	// Occlusion

	float lf_ambient_occlusion = 1.0;
	float shadow = 1.0;

	if(parameters.occlusion_mode == 0 && shlightfield_param.x > 0)
	{
		// light field AO
		lf_ambient_occlusion = parameters.occlusion_value;
	}
	else
	{
		shadow = parameters.occlusion_value;
	}

	float4 ssao = SampleTextureLevel(s_SSAO, parameters.screen_position, 0);
	ssao.xyz = saturate(ssao.xyz + u_ssao_param.x);
	shadow = min(shadow, ssao.w);

	if(parameters.flags_unk1 != 0)
	{
		parameters.emission *= shadow * u_lightColor.xyz * parameters.albedo;
	}

	//////////////////////////////////////////////////
	// Lighting

	float3 sunlight_diffuse = DiffuseBDRF(parameters, u_lightDirection.xyz, u_lightColor.xyz, shadow);
	float3 sunlight_specular = SpecularBRDF(parameters, u_lightDirection.xyz, u_lightColor.xyz, shadow, parameters.shader_model == ShaderModel_AnisotropicReflection);

	float3 local_light_diffuse;
	float3 local_light_specular;
	ComputePositionalLighting(parameters, local_light_diffuse, local_light_specular);

	float3 ambient_color = ComputeAmbientColor(parameters, lf_ambient_occlusion);
	float ambient_occlusion = GetAmbientOcclusion(parameters);

	//////////////////////////////////////////////////
	// reflection stuff

	ApplyReflection(parameters.emission, sunlight_specular, ambient_occlusion);

	if(!enable_ibl_plus_directional_specular)
	{
		sunlight_specular *= min(1, parameters.occlusion_mode);

		float debug_factor = 0.0;
		switch(GetDebug2Mode())
		{
			case 1:
				debug_factor = 1.0;
				break;
			case 2:
				debug_factor = saturate(u_sggi_param[0].y * (parameters.roughness - u_sggi_param[0].x));
				break;
		}

		sunlight_specular *= debug_factor;
	}

	//////////////////////////////////////////////////
	// Combining lights

	float3 occlusion_capsule_0 = lerp(u_occlusion_capsule_param[0].xyz, 1.0, ssao.x);
	float3 occlusion_capsule_1 = lerp(u_occlusion_capsule_param[1].xyz, 1.0, ssao.y);
	float3 occlusion_capsule_2 = parameters.shader_model == ShaderModel_1 ? 1.0 : occlusion_capsule_0;

	float3 out_dif_amb = sunlight_diffuse * occlusion_capsule_1;
	out_dif_amb += local_light_diffuse * occlusion_capsule_0;
	out_dif_amb = max(0.0, out_dif_amb);
	out_dif_amb /= Pi;
	out_dif_amb += occlusion_capsule_2 * ambient_color;
	out_dif_amb *= parameters.albedo;

	float3 out_spc_ems = sunlight_specular * ssao.x * ssao.z;
	out_spc_ems += local_light_specular * ssao.x * ssao.z;
	out_spc_ems = max(0.0, out_spc_ems);
	out_spc_ems += occlusion_capsule_2 * parameters.emission;


	//////////////////////////////////////////////////
	// Debug switch #1 here;

	float out_alpha = 1.0;

	//////////////////////////////////////////////////
	// shadow cascade (?)

	ApplyShadowCascadeThing(parameters.world_position, out_dif_amb);

	//////////////////////////////////////////////////
	// Light scattering

	if(g_LightScatteringColor.w > 0.001)
	{
		out_dif_amb *= lerp(1.0, parameters.light_scattering_colors.factor, g_LightScatteringColor.w);
		out_spc_ems *= lerp(1.0, parameters.light_scattering_colors.factor, g_LightScatteringColor.w);
		parameters.light_scattering_colors.base *= g_LightScatteringColor.w;
	}
	else
	{
		parameters.light_scattering_colors.base = 0.0;
	}

	//////////////////////////////////////////////////
	// Fog

	FogValues fog_values = ComputeFogValues(parameters);
	out_dif_amb *= (1.0 - fog_values.fog_factor);
	out_spc_ems *= (1.0 - fog_values.fog_factor);

	parameters.light_scattering_colors.base = lerp(
		parameters.light_scattering_colors.base,
		fog_values.fog_color,
		fog_values.fog_factor
	);

	//////////////////////////////////////////////////
	// Debug switch #2 here;

	//////////////////////////////////////////////////
	// final output

	float3 out_color = out_spc_ems + parameters.light_scattering_colors.base;

	WriteSSSOutput(
		parameters.pixel_position,
		parameters.shader_model,
		parameters.world_normal,
		parameters.albedo,
		ambient_color,
		out_dif_amb,
		parameters.sss_param,
		out_color
	);

	return float4(out_color, out_alpha);
}

#endif