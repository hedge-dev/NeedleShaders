#ifndef DEBUG_LIGHTING_INCLUDED
#define DEBUG_LIGHTING_INCLUDED

#include "../../Debug.hlsl"
#include "Struct.hlsl"
#include "Reflection.hlsl"
#include "Ambient.hlsl"

void DebugBeforeFog(
	LightingParameters parameters,
	float3 out_diffuse,
	float3 out_specular,
	float3 indirect_color,
	float3 ambient_color,
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
			out_direct = ComputeEnvironmentReflectionColor(debug_param, true).xyz;
			break;

		case DebugView_Shadow:
			out_direct = parameters.shadow;
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

float3 GetShadowCascadeDebugColor(int level)
{
	switch(level)
	{
		case 0:
			return float3(1.0, 0, 0.0);
			break;
		case 1:
			return float3(1.0, 1.0, 0.0);
			break;
		case 2:
			return float3(0.0, 1.0, 0.0);
			break;
		case 3:
			return float3(0.0, 1.0, 1.0);
			break;
		default:
			return float3(0.0, 0.0, 1.0);
			break;
	}
}

void DebugAfterFog(
	LightingParameters parameters,
	float3 ssao,
	float3 ambient_color,
	float3 emission_color,
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

	float3 debug_ambient = ComputeAmbientColor(parameters) * ssao.x;

	bool only_direct = true;

	switch(GetDebugView())
	{
		case DebugView_User0: break;
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
			debug_param.shadow = 1.0;
			out_direct = ComputeEnvironmentReflectionColor(debug_param, false).xyz;
			break;

		case DebugView_IblSpecular:
			LightingParameters debug_param_2 = parameters;
			debug_param_2.shadow = 1.0;
			out_direct = ComputeEnvironmentReflectionColor(debug_param_2, true).xyz;
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

#endif