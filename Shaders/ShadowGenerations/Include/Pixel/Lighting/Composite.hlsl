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

#include "../ShadowCascade.hlsl"

#include "Struct.hlsl"
#include "SubsurfaceScattering.hlsl"
#include "Lights.hlsl"
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

	//////////////////////////////////////////////////
	// SSS ???

	float3 blue_emission_thing = float3(
		2 * floor(abs(parameters.emission.z)),
		10 * frac(abs(parameters.emission.z)),
		0
	);

	float3 emission_thing = float3(
		parameters.emission.xy,
		sign(parameters.emission.z) * sqrt(1.0 - dot(parameters.emission.xy, parameters.emission.xy))
	);

	float3 emission_normal_thing = normalize(cross(emission_thing, parameters.world_normal));

	if(parameters.shading_mode != 4)
	{
		emission_thing = 0.0;
		emission_normal_thing = 0.0;
		blue_emission_thing = 0.0;
	}

	if(parameters.shading_mode == 3)
	{
		emission_thing = 0.0;
		emission_normal_thing = 0.0;
	}

	if(parameters.shading_mode == 3 || parameters.shading_mode == 4)
	{
		parameters.emission.xyz = 0.0;
	}

	if(parameters.shading_mode == 3)
	{
		// this makes no sense lmao, might as well just set it to 0
		// Maybe there was something between this and the previous if block
		blue_emission_thing = parameters.emission.xyz;
	}

	//////////////////////////////////////////////////
	// Ambient Occlusion

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

	if((parameters.raw_flags & 8) != 0)
	{
		parameters.emission *= ao_3 * u_lightColor.xyz * parameters.albedo;
	}

	//////////////////////////////////////////////////
	// Sunlight stuff

	float light_factor = dot(parameters.world_normal, u_lightDirection.xyz);
	float light_factor_clamped = saturate(light_factor);

	float3 light_camera_direction = normalize(parameters.view_direction + u_lightDirection.xyz);

	float3 albedo_3 = saturate(dot(parameters.fresnel_reflectance, 16.5));

	float light_fac_2 = saturate(dot(light_camera_direction, u_lightDirection.xyz));
	light_fac_2 = pow(1.0 - light_fac_2, 5);

	float3 albedo_4 = lerp(
		parameters.fresnel_reflectance,
		albedo_3,
		light_fac_2
	);

	//////////////////////////////////////////////////
	// SSS ???

	float3 sss_thing = GetCDRF(parameters.shading_mode, light_factor, light_factor_clamped, ao_3, blue_emission_thing);
	sss_thing *= u_lightColor.xyz;
	sss_thing *= 1.0 - parameters.metallic;
	sss_thing *= 1.0 - albedo_4.x;

	float camera_dot = saturate(dot(parameters.world_normal, parameters.view_direction));
	float light_camera_dot = saturate(dot(parameters.world_normal, light_camera_direction));

	float emission_thing_dot = dot(light_camera_direction, emission_thing);
	float emission_normal_thing_dot = dot(light_camera_direction, emission_normal_thing);

	float roughness_sqared = pow(parameters.roughness, 2);
	float blue_emission_thing_2 = Pi
		* blue_emission_thing.x * roughness_sqared
		* blue_emission_thing.y * roughness_sqared;

	float2 t = roughness_sqared * blue_emission_thing.xy + 0.000001;

	float3 t2 = float3(
		light_camera_dot,
		emission_thing_dot / t.x,
		emission_normal_thing_dot / t.y
	);

	float t3 = 1.0 / (blue_emission_thing_2 * pow(dot(t2, t2), 2) + 0.000001);

	float t4 = 0.318309873 * pow(parameters.roughness / (pow(t2.x * parameters.roughness, 2) + (1 - pow(t2.x, 2))), 2);

	if(parameters.shading_mode == 4)
	{
		t4 = t3;
	}

	float t5_1 = pow(1.0 + parameters.roughness, 2) * 0.125;
	float t5_2 = lerp(t5_1, 1.0, camera_dot);
	float t5 = t5_2 * lerp(t5_1, 1.0, light_factor_clamped);
	t5 = (0.25 / t5) * t4;

	float3 albedo_5 = u_lightColor.xyz * saturate(t5 * albedo_4) * light_factor_clamped * ao_3;

	//////////////////////////////////////////////////
	// Lighting

	float3 light_color_1;
	float3 light_color_2;
	GetLightColors(parameters, light_color_1, light_color_2);

	float3 ambient_color = ComputeAmbientColor(parameters.shading_mode, ao_mode);

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

	something(parameters.emission, albedo_5, ambient_color_3.w);

	float ssao_thing = ssao.x * ssao.z;
	float3 occlusion_capsule_0 = lerp(u_occlusion_capsule_param[0].xyz, 1.0, ssao.x);
	float3 occlusion_capsule_1 = lerp(u_occlusion_capsule_param[1].xyz, 1.0, ssao.y);

	float3 oc_thing_1 = parameters.shading_mode == 1 ? 1.0 : occlusion_capsule_0;
	occlusion_capsule_0 *= light_color_1;

	albedo_5 *= ssao_thing;
	float3 oc_thing_4 = albedo_5 * gi_shadow_4;

	float oc_thing_5;
	switch(debug2_mode)
	{
		case 1:
			oc_thing_5 = 1.0;
			break;
		case 2:
			oc_thing_5 = sggi_thing;
			break;
		default:
			oc_thing_5 = 0.0;
			break;
	}

	oc_thing_4 *= oc_thing_5;

	if(enable_ibl_plus_directional_specular)
	{
		oc_thing_4 = albedo_5;
	}

	float3 oc_thing_7 = (max(0.0, sss_thing * occlusion_capsule_1 + occlusion_capsule_0) * 0.318309873 + oc_thing_1 * ambient_color_3.xyz) * parameters.albedo;
	float3 oc_thing_8 = parameters.emission * oc_thing_1 + max(0.0, oc_thing_4 + light_color_2 * ssao_thing);

	float out_alpha = 1.0;

	// Debug switch #1 here;

	ApplyShadowCascadeThing(parameters.world_position, oc_thing_7);

	if(g_LightScatteringColor.w > 0.001)
	{
		oc_thing_7 *= lerp(1.0, parameters.light_scattering_colors.factor, g_LightScatteringColor.w);
		oc_thing_8 *= lerp(1.0, parameters.light_scattering_colors.factor, g_LightScatteringColor.w);
		parameters.light_scattering_colors.base *= g_LightScatteringColor.w;
	}
	else
	{
		parameters.light_scattering_colors.base = 0.0;
	}

	FogValues fog_values = ComputeFogValues(parameters);
	oc_thing_7 *= (1.0 - fog_values.fog_factor);
	oc_thing_8 *= (1.0 - fog_values.fog_factor);

	parameters.light_scattering_colors.base = lerp(
		parameters.light_scattering_colors.base,
		fog_values.fog_color,
		fog_values.fog_factor
	);

	// Debug switch #2 here;

	float3 out_color = oc_thing_8 + parameters.light_scattering_colors.base;

	WriteSSSOutput(
		parameters.pixel_position,
		parameters.shading_mode,
		parameters.world_normal,
		parameters.albedo,
		ambient_color_3.xyz,
		oc_thing_7,
		blue_emission_thing,
		out_color
	);

	return float4(out_color, out_alpha);
}

#endif