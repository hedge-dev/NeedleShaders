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

Texture2D<float4> WithSampler(s_SSAO);

void DebugBeforeFog(
	LightingParameters parameters,
	float3 out_diffuse,
	float3 out_specular,
	float3 indirect_color,
	float3 ambient_color,
	float shadow,
	inout float3 out_direct,
	inout float3 out_indirect,
	inout float out_alpha)
{
	bool only_direct = true;

	switch(GetDebugMode())
	{
		case DebugMode_DiffuseLighting:
			out_direct = out_diffuse / Pi;
			break;

		case DebugMode_SpecularLighting:
			out_direct = out_specular;
			break;

		case DebugMode_Emission:
			out_direct = indirect_color;
			break;

		case DebugMode_43:
			out_direct = ambient_color;
			break;

		case DebugMode_44:
			out_direct = ambient_color + indirect_color;
			break;

		case DebugMode_Emission2:
			out_direct = indirect_color;
			break;

		case DebugMode_EnvReflections:
		case DebugMode_EnvReflectionsSmooth:
			LightingParameters debug_param = parameters;
			debug_param.fresnel_reflectance = 1.0;
			out_direct = ComputeEnvironmentReflectionColor(debug_param, shadow).xyz;
			break;

		case DebugMode_Shadow:
			out_direct = shadow;
			break;

		case DebugMode_FirstProbe:
			only_direct = false;
			out_alpha = 1.0;

			EnvProbeData debug_probe = GetEnvProbeData(0);
			if(!debug_probe.unk0)
			{
				break;
			}

			float3 debug_probe_local_pos = mul(debug_probe.inv_world_matrix, parameters.world_position);
			debug_probe_local_pos = abs(debug_probe_local_pos);
			float distance = max(max(debug_probe_local_pos.x, debug_probe_local_pos.y), debug_probe_local_pos.z);

			if(distance <= debug_probe.fade_offset
				|| debug_probe_local_pos.x > 0.99
				|| debug_probe_local_pos.y > 0.99
				|| debug_probe_local_pos.z > 0.99)
			{
				out_alpha = 0.0;
			}
			break;

		case DebugMode_35:
			break;
		default:
			only_direct = false;
			break;
	}

	if(only_direct)
	{
		out_indirect = 0.0;
		out_alpha = 0.0;
	}
}

void DebugAfterFog(
	LightingParameters parameters,
	float3 ssao,
	float3 ambient_color,
	float3 emission_color,
	float lf_ambient_occlusion,
	float shadow,
	inout float3 out_direct,
	inout float3 out_indirect,
	inout float3 out_fog,
	inout float out_alpha)
{

	uint debug_mode = GetDebugMode();
	if(debug_mode == 0)
	{
		return;
	}

	float debug_ambient = ComputeAmbientColor(parameters, lf_ambient_occlusion) * ssao.x;

	bool only_direct = true;

	switch(GetDebugMode())
	{
		case DebugMode_10: break;
		case DebugMode_11: break;

		case DebugMode_12:
			out_direct = debug_ambient;
			break;

		case DebugMode_13: break;

		case DebugMode_Albedo:
			out_direct = parameters.albedo;
			break;

		case DebugMode_Albedo2:
			float3 debug_1 = saturate(0.010398 - parameters.albedo);
			float3 debug_2 = saturate(parameters.albedo - 0.899384);
    		out_direct = dot(debug_1, debug_1) != 0.0 || dot(debug_2, debug_2) != 0.0
				? float3(10,0,0)
				: parameters.albedo;
			break;

		case DebugMode_White:
			out_direct = 1.0;
			break;

		case DebugMode_Normal:
			out_direct = saturate(parameters.world_normal * 0.5 + 0.5);
			break;

		case DebugMode_Roughness:
			out_direct = parameters.roughness;
			break;

		case DebugMode_Smoothness:
			out_direct = 1.0 - parameters.roughness;
			break;

		case DebugMode_WeirdIndirect:
			out_direct = debug_ambient + emission_color * ambient_color;
			break;

		case DebugMode_AmbientOcclusion:
			out_direct = parameters.ambient_occlusion;
			break;

		case DebugMode_FresnelReflectance:
			out_direct = parameters.fresnel_reflectance;
			break;

		case DebugMode_Metallic:
			out_direct = parameters.metallic;
			break;

		case DebugMode_23: break;
		case DebugMode_37: break;
		case DebugMode_38: break;

		case DebugMode_SSAO:
			out_direct = ssao.x;
			break;

		case DebugMode_ScreenSpaceReflections:
			out_direct = SampleTextureLevel(s_RLR, parameters.screen_position, 0).xyz;
			break;

		case DebugMode_EnvReflectionNoFogNoFresnel:
			float4 debug_probe_reflection = ComputeReflectionProbeColor(
				parameters.tile_position,
				parameters.world_position,
				parameters.world_normal,
				parameters.view_direction,
				parameters.roughness
			);

			float4 debug_skybox_reflection = ComputeSkyboxReflectionColor(
				parameters.world_normal,
				parameters.view_direction,
				parameters.roughness,
				1.0
			);

			out_direct = debug_probe_reflection.xyz + debug_skybox_reflection.xyz * saturate(1.0 - debug_probe_reflection.w);
			break;

		case DebugMode_EnvReflectionNoFog:
			out_direct = ComputeEnvironmentReflectionColor(parameters, shadow).xyz;
			break;

		case DebugMode_EnvBRDF:
			out_direct = float3(SampleTextureLevel(s_EnvBRDF, float2(parameters.cos_view_normal, parameters.roughness), 0).xy, 0);
			break;

		case DebugMode_Position:
			float3 debug_pos = 0.01 * parameters.world_position.xyz;
			out_direct = 1.0 + frac(abs(debug_pos)) * sign(debug_pos);
			out_direct += out_direct >= 0.0 ? 1.0 : 0.0;
			break;

		case DebugMode_ShaderModel:
			out_direct = (parameters.shader_model & uint3(1, 2, 4)) ? 1.0 : 0.0;
			break;

		case DebugMode_FlagUnk2:
			out_direct = (1 << parameters.flags_unk2) & 2 ? 1.0 : 0.0;
			break;

		case DebugMode_ViewDistance:
			out_direct =
				( parameters.view_distance - g_global_user_param_3.x)
				/ (g_global_user_param_3.y - g_global_user_param_3.x);
			break;

		case DebugMode_ShaderModel2:
			out_direct = (parameters.shader_model & uint3(1, 2, 4)) ? 0.5 : 0.0;
			if(parameters.flags_unk1)
			{
				out_direct *= 3;
			}
			break;

		case DebugMode_FlagUnk2_2:
			out_direct = (parameters.flags_unk2 == int3(1,2,3)) ? 1.0 : 0.0;
			break;

		default:
			only_direct = false;
			break;
	}

	if(only_direct)
	{
		out_indirect = 0.0;
		out_fog = 0.0;
		out_alpha = 1.0;
	}
}

float4 CompositeLighting(LightingParameters parameters, out float4 ssss_output)
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


	//////////////////////////////////////////////////
	// Lighting

	float3 sunlight_diffuse = DiffuseBDRF(parameters, u_lightDirection.xyz, u_lightColor.xyz, shadow);
	float3 sunlight_specular = SpecularBRDF(parameters, u_lightDirection.xyz, u_lightColor.xyz, shadow, parameters.shader_model == ShaderModel_AnisotropicReflection);

	float3 positional_light_diffuse;
	float3 positional_light_specular;
	ComputePositionalLighting(parameters, positional_light_diffuse, positional_light_specular);

	//////////////////////////////////////////////////
	// Ambient Lighting

	float3 ambient_color = ComputeAmbientColor(parameters, lf_ambient_occlusion);
	ambient_color *= 1.0 - parameters.metallic;
	ambient_color *= 1.0 - parameters.fresnel_reflectance;
	ambient_color *= parameters.ambient_occlusion;

	switch(GetDebugMode())
	{
		case DebugMode_Emission2:
		case DebugMode_44:
			ambient_color = 0.0;
			break;
		case DebugMode_43:
			ambient_color = lf_ambient_occlusion;
			break;
	}

	if(parameters.shader_model == ShaderModel_1 || parameters.occlusion_mode != 0)
	{
		ambient_color = 0.0;
	}

	float ambient_occlusion = GetAmbientOcclusion(parameters);

	//////////////////////////////////////////////////
	// Emission

	float3 emission_color = parameters.emission;
	if(parameters.flags_unk1 != 0)
	{
		emission_color *= shadow * u_lightColor.xyz * parameters.albedo;
	}

	//////////////////////////////////////////////////
	// reflection stuff

	float4 reflection_color = ComputeReflectionColor(parameters, ambient_occlusion, shadow);

    float3 indirect_color = emission_color + reflection_color.xyz;
	sunlight_specular *= reflection_color.w;

	//////////////////////////////////////////////////
	// Applying occlusion capsules(?)

	float3 occlusion_capsule_0 = lerp(u_occlusion_capsule_param[0].xyz, 1.0, ssao.x);
	float3 occlusion_capsule_1 = lerp(u_occlusion_capsule_param[1].xyz, 1.0, ssao.y);
	float3 occlusion_capsule_2 = parameters.shader_model == ShaderModel_1 ? 1.0 : occlusion_capsule_0;

	float3 out_diffuse = sunlight_diffuse * occlusion_capsule_1
		+ positional_light_diffuse * occlusion_capsule_0;

	float3 out_specular = (sunlight_specular + positional_light_specular) * ssao.x * ssao.z;

	indirect_color *= occlusion_capsule_2;
	ambient_color *= occlusion_capsule_2;

	//////////////////////////////////////////////////
	// Combining lights

	float3 out_direct = max(0.0, out_diffuse) / Pi;
	out_direct += ambient_color;
	out_direct *= parameters.albedo;

	float3 out_indirect = max(0.0, out_specular) + indirect_color;

	//////////////////////////////////////////////////
	// Debug switch #1

	float out_alpha = 1.0;
	DebugBeforeFog(
		parameters,
		out_diffuse,
		out_specular,
		indirect_color,
		ambient_color,
		shadow,
		out_direct,
		out_indirect,
		out_alpha
	);

	//////////////////////////////////////////////////
	// shadow cascade (?)

	ApplyShadowCascadeThing(parameters.world_position, out_direct);

	//////////////////////////////////////////////////
	// Light scattering

	float3 out_fog = 0.0;

	if(g_LightScatteringColor.w > 0.001)
	{
		out_direct *= lerp(1.0, parameters.light_scattering_colors.factor, g_LightScatteringColor.w);
		out_indirect *= lerp(1.0, parameters.light_scattering_colors.factor, g_LightScatteringColor.w);
		out_fog = parameters.light_scattering_colors.base * g_LightScatteringColor.w;
	}

	//////////////////////////////////////////////////
	// Fog

	FogValues fog_values = ComputeFogValues(parameters);
	out_direct *= (1.0 - fog_values.fog_factor);
	out_indirect *= (1.0 - fog_values.fog_factor);

	out_fog = lerp(
		out_fog,
		fog_values.fog_color,
		fog_values.fog_factor
	);

	//////////////////////////////////////////////////
	// Debug switch #2

	DebugAfterFog(
		parameters,
		ssao.xyz,
		ambient_color,
		emission_color,
		lf_ambient_occlusion,
		shadow,
		out_direct,
		out_indirect,
		out_fog,
		out_alpha
	);

	//////////////////////////////////////////////////
	// Subsurface scattering

	ComputeSSSOutput(parameters, ambient_color, u_lightColor.xyz, out_direct, ssss_output);

	//////////////////////////////////////////////////
	// final output

	return float4(
		out_direct + out_indirect + out_fog,
		out_alpha
	);
}

#endif