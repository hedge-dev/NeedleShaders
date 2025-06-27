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
#include "LocalLights.hlsl"
#include "Fog.hlsl"
#include "Ambient.hlsl"

Texture2D<float4> WithSampler(s_EnvBRDF);
Texture2D<float4> WithSampler(s_SSAO);
Texture2D<float4> WithSampler(s_RLR);
TextureCubeArray<float4> WithSampler(s_IBLProbeArray);

void something(inout float3 emission, inout float3 albedo_5, float sggi_thing_w)
{
	if(sggi_thing_w <= 0.00001)
	{
		return;
	}

	//TODO
}

float4 CompositeLighting(LightingParameters parameters)
{
	//////////////////////////////////////////////////
	// Ambient Occlusion

	float ao_1 = 0.1 * abs(parameters.moded_ambient_occlusion);
	uint ao_mode = (uint)trunc(ao_1);
	ao_1 = 10 * (ao_1 - ao_mode);

	float ao_3 = 1.0;

	if(shlightfield_param.x <= 0 || ao_mode != 0)
	{
		float t = ao_3;
		ao_3 = ao_1;
		ao_1 = t;
	}

	float4 ssao = SampleTextureLevel(s_SSAO, parameters.screen_position, 0);
	ssao.xyz = saturate(ssao.xyz + u_ssao_param.x);

	ao_3 = min(ao_3, ssao.w);

	if(parameters.flags_unk1 != 0)
	{
		parameters.emission *= ao_3 * u_lightColor.xyz * parameters.albedo;
	}

	//////////////////////////////////////////////////
	// Lighting

	float3 sunlight_diffuse = DiffuseBDRF(parameters, u_lightDirection.xyz, u_lightColor.xyz, ao_3);
	float3 sunlight_specular = SpecularBRDF(parameters, u_lightDirection.xyz, u_lightColor.xyz, ao_3, parameters.shading_mode == ShadingMode_AnisotropicReflection);

	float3 local_light_diffuse;
	float3 local_light_specular;
	GetLightColors(parameters, local_light_diffuse, local_light_specular);

	float3 ambient_color = ComputeAmbientColor(parameters.shading_mode, ao_mode);

	//////////////////////////////////////////////////

	int gi_shadow_4 = min(1, ao_mode);

	int debug_mode = GetDebugMode();
	int debug2_mode = GetDebug2Mode();

	float sggi_thing = saturate(u_sggi_param[0].y * (parameters.roughness - -u_sggi_param[0].x));

	float sggi_thing_2;

	switch(debug2_mode)
	{
		case 1:
			sggi_thing_2 = 1.0 - gi_shadow_4;
			break;
		case 2:
			sggi_thing_2 = 1.0;
			break;
		case 3:
			sggi_thing_2 = 1.0 - sggi_thing * gi_shadow_4;
			break;
		default:
			sggi_thing_2 = parameters.ambient_occlusion;
			break;
	}

	if(ao_mode == 1)
	{
		sggi_thing_2 = lerp(sggi_thing_2, 1.0, parameters.metallic);
	}

	if(parameters.shading_mode == 1)
	{
		sggi_thing_2 = 0.0;
	}

	float4 ambient_color_2 = 0.0;
	switch(debug_mode)
	{
		case 43:
			ambient_color_2.xyz = ao_1;
			break;
		case 44:
			ambient_color_2.xyz = 0.0;
			break;
		default:
			ambient_color_2.xyz = ambient_color;
			break;
	}

	float4 ambient_color_3;
	if(debug_mode == 3 || debug_mode == 43 || debug_mode == 19 || debug_mode == 44)
	{
		ambient_color_3 = ambient_color_2;
	}
	else
	{
		ambient_color_3 = float4(ambient_color, sggi_thing_2);
	}

	something(parameters.emission, sunlight_specular, ambient_color_3.w);

	float ssao_thing = ssao.x * ssao.z;
	float3 occlusion_capsule_0 = lerp(u_occlusion_capsule_param[0].xyz, 1.0, ssao.x);
	float3 occlusion_capsule_1 = lerp(u_occlusion_capsule_param[1].xyz, 1.0, ssao.y);

	float3 oc_thing_1 = parameters.shading_mode == 1 ? 1.0 : occlusion_capsule_0;

	sunlight_specular *= ssao_thing;
	float3 sunlight_specular_2 = sunlight_specular * gi_shadow_4;

	float sunlight_specular_factor;
	switch(debug2_mode)
	{
		case 1:
			sunlight_specular_factor = 1.0;
			break;
		case 2:
			sunlight_specular_factor = sggi_thing;
			break;
		default:
			sunlight_specular_factor = 0.0;
			break;
	}

	sunlight_specular_2 *= sunlight_specular_factor;

	if(enable_ibl_plus_directional_specular)
	{
		sunlight_specular_2 = sunlight_specular;
	}

	float3 out_diffuse = (max(0.0, sunlight_diffuse * occlusion_capsule_1 + local_light_diffuse * occlusion_capsule_0) / Pi + oc_thing_1 * ambient_color_3.xyz) * parameters.albedo;
	float3 out_specular = parameters.emission * oc_thing_1 + max(0.0, sunlight_specular_2 + local_light_specular * ssao_thing);

	float out_alpha = 1.0;

	// Debug switch #1 here;

	ApplyShadowCascadeThing(parameters.world_position, out_diffuse);

	if(g_LightScatteringColor.w > 0.001)
	{
		out_diffuse *= lerp(1.0, parameters.light_scattering_colors.factor, g_LightScatteringColor.w);
		out_specular *= lerp(1.0, parameters.light_scattering_colors.factor, g_LightScatteringColor.w);
		parameters.light_scattering_colors.base *= g_LightScatteringColor.w;
	}
	else
	{
		parameters.light_scattering_colors.base = 0.0;
	}

	FogValues fog_values = ComputeFogValues(parameters);
	out_diffuse *= (1.0 - fog_values.fog_factor);
	out_specular *= (1.0 - fog_values.fog_factor);

	parameters.light_scattering_colors.base = lerp(
		parameters.light_scattering_colors.base,
		fog_values.fog_color,
		fog_values.fog_factor
	);

	// Debug switch #2 here;

	float3 out_color = out_specular + parameters.light_scattering_colors.base;

	WriteSSSOutput(
		parameters.pixel_position,
		parameters.shading_mode,
		parameters.world_normal,
		parameters.albedo,
		ambient_color_3.xyz,
		out_diffuse,
		parameters.sss_param,
		out_color
	);

	return float4(out_color, out_alpha);
}

#endif