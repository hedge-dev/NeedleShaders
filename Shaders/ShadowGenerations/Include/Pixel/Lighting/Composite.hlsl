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

	switch(GetDebugView())
	{
		case DebugView_DirDiffuse:
			out_direct = out_diffuse / Pi;
			break;

		case DebugView_DirSpecular:
			out_direct = out_specular;
			break;

		case DebugView_AmbDiffuse:
			out_direct = indirect_color;
			break;

		case DebugView_AmbDiffuseLf:
			out_direct = ambient_color;
			break;

		case DebugView_SggiOnly:
			out_direct = ambient_color + indirect_color;
			break;

		case DebugView_AmbSpecular:
			out_direct = indirect_color;
			break;

		case DebugView_OnlyIbl:
		case DebugView_OnlyIblSurfNormal:
			LightingParameters debug_param = parameters;
			debug_param.fresnel_reflectance = 1.0;
			debug_param.roughness = 0.0;
			out_direct = ComputeEnvironmentReflectionColor(debug_param, shadow, true).xyz;
			break;

		case DebugView_Shadow:
			out_direct = shadow;
			break;

		case DebugView_IblCapture:
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

		case DebugView_WriteDepthToAlpha:
			// the way its implemented here is different from the original...
			// Because here it will actually work lol.
			// In the original, it statically writes 0.

			// Its also not actually part of tiled_deferred_rendering.cso,
			// for some reason but imma include it anyway. (not like it gets used,
			// since debugging uses the pixel shader...)
			// ~ Justin113D

			out_alpha = parameters.depth;
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

void DebugLocalLight(LightingParameters parameters, int type, inout float3 out_direct)
{
	#ifdef IS_COMPUTE_SHADER
		return;
	#endif

	LocalLightHeader pos_header = GetLocalLightHeader(parameters.tile_position);

	uint2 count;

	if(type == 0)
	{
		count = uint2(
			pos_header.positional_light_count,
			pos_header.positional_light_vol_count
		);
	}
	else if(type == 1)
	{
		count = uint2(
			pos_header.occlusion_capsule_count,
			pos_header.occlusion_capsule_vol_count
		);
	}
	else
	{
		count = uint2(
			pos_header.env_probe_count,
			pos_header.env_probe_vol_count
		);
	}

	out_direct = DebugTile_UInt2(
		parameters.pixel_position,
		count,
		out_direct
	);

	#ifndef enable_local_light_shadow
		out_direct = DebugTile_NumText(parameters.pixel_position, count.x, out_direct);
	#endif
}

void DebugAfterFog(
	LightingParameters parameters,
	float3 ssao,
	float3 ambient_color,
	float3 emission_color,
	float lf_ambient_occlusion,
	inout float3 out_direct,
	inout float3 out_indirect,
	inout float3 out_fog,
	inout float out_alpha)
{

	uint debug_mode = GetDebugView();
	if(debug_mode == 0)
	{
		return;
	}

	float debug_ambient = ComputeAmbientColor(parameters, lf_ambient_occlusion) * ssao.x;

	bool only_direct = true;

	switch(GetDebugView())
	{
		case DebugView_User0:
			// User0 is not actually used, so i repurposed it for debugging shadow cascades
			// ~ Justin113D
			out_direct = 1.0;
			ApplyShadowCascadeThing(parameters.world_position, out_direct);
			break;

		case DebugView_User1: break;

		case DebugView_User2:
			out_direct = debug_ambient;
			break;

		case DebugView_User3: break;

		case DebugView_Albedo:
			out_direct = parameters.albedo;
			break;

		case DebugView_AlbedoCheckOutlier:
			float3 debug_1 = saturate(0.010398 - parameters.albedo);
			float3 debug_2 = saturate(parameters.albedo - 0.899384);
    		out_direct = dot(debug_1, debug_1) != 0.0 || dot(debug_2, debug_2) != 0.0
				? float3(10,0,0)
				: parameters.albedo;
			break;

		case DebugView_Opacity:
			out_direct = 1.0;
			break;

		case DebugView_Normal:
			out_direct = saturate(parameters.world_normal * 0.5 + 0.5);
			break;

		case DebugView_Roughness:
			out_direct = parameters.roughness;
			break;

		case DebugView_Smoothness:
			out_direct = 1.0 - parameters.roughness;
			break;

		case DebugView_Ambient:
			out_direct = debug_ambient + emission_color * ambient_color;
			break;

		case DebugView_Cavity:
			out_direct = parameters.cavity;
			break;

		case DebugView_Reflectance:
			out_direct = parameters.fresnel_reflectance;
			break;

		case DebugView_Metallic:
			out_direct = parameters.metallic;
			break;

		case DebugView_LocalLight:
			DebugLocalLight(parameters, 0, out_direct);
			break;

		case DebugView_OcclusionCapsule:
			DebugLocalLight(parameters, 1, out_direct);
			break;
		case DebugView_Probe:
			DebugLocalLight(parameters, 2, out_direct);
			break;

		case DebugView_SSAO:
			out_direct = ssao.x;
			break;

		case DebugView_RLR:
			out_direct = SampleTextureLevel(s_RLR, parameters.screen_position, 0).xyz;
			break;

		case DebugView_IblDiffuse:
			LightingParameters debug_param = parameters;
			debug_param.roughness = 1.0;
			debug_param.cavity = 1.0;
			out_direct = ComputeEnvironmentReflectionColor(debug_param, 1.0, false).xyz;
			break;

		case DebugView_IblSpecular:
			out_direct = ComputeEnvironmentReflectionColor(parameters, 1.0, true).xyz;
			break;

		case DebugView_EnvBRDF:
			out_direct = float3(SampleTextureLevel(s_EnvBRDF, float2(parameters.cos_view_normal, parameters.roughness), 0).xy, 0);
			break;

		case DebugView_WorldPosition:
			float3 debug_pos = 0.01 * parameters.world_position.xyz;
			out_direct = 1.0 + frac(abs(debug_pos)) * sign(debug_pos);
			out_direct += out_direct >= 0.0 ? 1.0 : 0.0;
			break;

		case DebugView_ShadingModelId:
			out_direct = (parameters.shading_model.type & uint3(1, 2, 4)) ? 1.0 : 0.0;
			break;

		case DebugView_CharacterMask:
			out_direct = parameters.shading_model.kind == ShadingModelKind_Character ? 1.0 : 0.0;
			break;

		case DebugView_Distance:
			out_direct =
				( parameters.view_distance - g_global_user_param_3.x)
				/ (g_global_user_param_3.y - g_global_user_param_3.x);
			break;

		case DebugView_ShadingModel:
			out_direct = (parameters.shading_model.type & uint3(1, 2, 4)) ? 0.5 : 0.0;
			if(parameters.shading_model.unknown)
			{
				out_direct *= 3;
			}
			break;

		case DebugView_ShadingKind:
			out_direct = (parameters.shading_model.kind == int3(1,2,3)) ? 1.0 : 0.0;
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

float4 CompositeLighting(LightingParameters parameters, out float4 ssss_output, out float ssss_mask)
{
	//////////////////////////////////////////////////
	// Occlusion

	float lf_ambient_occlusion = 1.0;
	float shadow = 1.0;

	if(parameters.occlusion_mode == OcclusionMode_AOLightField && shlightfield_param.x > 0)
	{
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
	// Emission

	float3 emission_color = parameters.emission;
	if(parameters.shading_model.unknown)
	{
		emission_color *= shadow * u_lightColor.xyz * parameters.albedo;
	}

	//////////////////////////////////////////////////
	// Lighting

	float3 sunlight_diffuse = DiffuseBDRF(parameters, u_lightDirection.xyz, u_lightColor.xyz, shadow);
	float3 sunlight_specular = SpecularBRDF(parameters, u_lightDirection.xyz, u_lightColor.xyz, shadow, parameters.shading_model.type == ShadingModelType_AnisotropicReflection);

	float3 positional_light_diffuse;
	float3 positional_light_specular;
	ComputePositionalLighting(parameters, positional_light_diffuse, positional_light_specular);

	//////////////////////////////////////////////////
	// Ambient Lighting

	float3 ambient_color = 0.0;

	if(parameters.shading_model.type != ShadingModelType_1 && parameters.occlusion_mode == OcclusionMode_AOLightField)
	{
		ambient_color = ComputeAmbientColor(parameters, lf_ambient_occlusion);
		ambient_color *= 1.0 - parameters.metallic;
		ambient_color *= 1.0 - parameters.fresnel_reflectance;
		ambient_color *= parameters.cavity;
	}

	switch(GetDebugView())
	{
		case DebugView_AmbSpecular:
		case DebugView_SggiOnly:
			ambient_color = 0.0;
			break;
		case DebugView_AmbDiffuseLf:
			ambient_color = lf_ambient_occlusion;
			break;
	}

	//////////////////////////////////////////////////
	// reflection stuff

	float4 reflection_color = ComputeReflectionColor(parameters, shadow);

    float3 indirect_color = emission_color + reflection_color.xyz;
	sunlight_specular *= reflection_color.w;

	if(!enable_ibl_plus_directional_specular)
	{
		switch(GetDebug2Mode())
		{
			case 1:
				sunlight_specular *= min(1, parameters.occlusion_mode);
				break;
			case 2:
				sunlight_specular *= min(1, parameters.occlusion_mode);
				sunlight_specular *= saturate(u_sggi_param[0].y * (parameters.roughness - u_sggi_param[0].x));
				break;
			default:
				sunlight_specular = 0.0;
				break;
		}
	}

	//////////////////////////////////////////////////
	// Applying occlusion parameters (?)

	float3 occlusion_capsule_0 = lerp(u_occlusion_capsule_param[0].xyz, 1.0, ssao.x);
	float3 occlusion_capsule_1 = lerp(u_occlusion_capsule_param[1].xyz, 1.0, ssao.y);
	float3 occlusion_capsule_2 = parameters.shading_model.type == ShadingModelType_1 ? 1.0 : occlusion_capsule_0;

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
		out_direct,
		out_indirect,
		out_fog,
		out_alpha
	);

	//////////////////////////////////////////////////
	// Subsurface scattering

	ComputeSSSSOutput(
		parameters,
		ambient_color,
		u_lightColor.xyz,
		out_direct,
		ssss_output,
		ssss_mask
	);

	//////////////////////////////////////////////////
	// final output

	return float4(
		out_direct + out_indirect + out_fog,
		out_alpha
	);
}

#endif