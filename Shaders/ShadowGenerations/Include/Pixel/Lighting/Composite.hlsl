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

	float3 local_light_diffuse;
	float3 local_light_specular;
	ComputePositionalLighting(parameters, local_light_diffuse, local_light_specular);

	float3 ambient_color = ComputeAmbientColor(parameters, lf_ambient_occlusion);
	float ambient_occlusion = GetAmbientOcclusion(parameters);

	float3 emission_color = parameters.emission;
	if(parameters.flags_unk1 != 0)
	{
		emission_color *= shadow * u_lightColor.xyz * parameters.albedo;
	}

	//////////////////////////////////////////////////
	// reflection stuff

	float4 reflection_color = ComputeReflectionColor(parameters, ambient_occlusion, shadow);

    emission_color += reflection_color.xyz;
	sunlight_specular *= reflection_color.w;

	//////////////////////////////////////////////////
	// Applying occlusion capsules(?)

	float3 occlusion_capsule_0 = lerp(u_occlusion_capsule_param[0].xyz, 1.0, ssao.x);
	float3 occlusion_capsule_1 = lerp(u_occlusion_capsule_param[1].xyz, 1.0, ssao.y);
	float3 occlusion_capsule_2 = parameters.shader_model == ShaderModel_1 ? 1.0 : occlusion_capsule_0;

	sunlight_diffuse *= occlusion_capsule_1;
	sunlight_specular *= ssao.x * ssao.z;

	local_light_diffuse *= occlusion_capsule_0;
	local_light_specular *= ssao.x * ssao.z;

	emission_color *= occlusion_capsule_2;
	ambient_color = occlusion_capsule_2;

	//////////////////////////////////////////////////
	// Combining lights

	float3 out_direct = sunlight_diffuse;
	out_direct += local_light_diffuse;
	out_direct = max(0.0, out_direct);
	out_direct /= Pi;
	out_direct += ambient_color;
	out_direct *= parameters.albedo;

	float3 out_indirect = sunlight_specular;
	out_indirect += local_light_specular;
	out_indirect = max(0.0, out_indirect);
	out_indirect += emission_color;


	//////////////////////////////////////////////////
	// Debug switch #1

	float out_alpha = 1.0;

	switch(GetDebugMode())
	{
		case DebugMode_DiffuseLighting:
			out_direct = (sunlight_diffuse + local_light_diffuse ) / Pi;
			out_indirect = 0.0;
			out_alpha = 0.0;
			break;

		case DebugMode_SpecularLighting:
			out_direct = sunlight_specular + local_light_specular;
			out_indirect = 0.0;
			out_alpha = 0.0;
			break;

		case DebugMode_Emission:
			out_direct = emission_color;
			out_indirect = 0.0;
			out_alpha = 0.0;
			break;

		case DebugMode_43:
			out_direct = ambient_color;
			out_indirect = 0.0;
			out_alpha = 0.0;
			break;

		case DebugMode_44:
			out_direct = ambient_color + emission_color;
			out_indirect = 0.0;
			out_alpha = 0.0;
			break;

		case DebugMode_Emission2:
			out_direct = emission_color;
			out_indirect = 0.0;
			out_alpha = 0.0;
			break;

		case DebugMode_EnvReflections:
		case DebugMode_EnvReflectionsSmooth:
			out_direct = ComputeEnvironmentReflectionColor(parameters, shadow).xyz;
			out_indirect = 0.0;
			out_alpha = 0.0;
			break;

		case DebugMode_Shadow:
			out_direct = shadow;
			out_indirect = 0.0;
			out_alpha = 0.0;
			break;

		case DebugMode_FirstProbe:
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
			out_alpha = 0.0;
			break;
	}

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
	// Debug switch #2 here;

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