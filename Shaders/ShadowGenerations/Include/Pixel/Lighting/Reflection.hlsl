#ifndef REFLECTION_LIGHTING_INCLUDED
#define REFLECTION_LIGHTING_INCLUDED

#include "../../Common.hlsl"

#if !defined(enable_para_corr) && !defined(no_enable_para_corr)
	DefineFeature(enable_para_corr);
#endif

#include "../../Texture.hlsl"
#include "../../Debug.hlsl"

#include "../EnvironmentBRDF.hlsl"

#include "Struct.hlsl"
#include "LocalLights.hlsl"
#include "EnvironmentalProbe.hlsl"

TextureCubeArray<float4> WithSampler(s_IBLProbeArray);
TextureCube<float4> WithSampler(s_IBL);
Texture2D<float4> WithSampler(s_RLR);

float ComputeReflectioOcclusion(LightingParameters parameters)
{
	if(parameters.shading_model.type == ShadingModelType_1)
	{
		return 0.0;
	}

	int debug_view = GetDebugView();
	if(debug_view == DebugView_AmbDiffuse
		|| debug_view == DebugView_Ambient
		|| debug_view == DebugView_AmbDiffuseLf
		|| debug_view == DebugView_SggiOnly)
	{
		return 0.0;
	}

	float result = parameters.cavity;

	switch(GetDebug2Mode())
	{
		case Debug2Mode_1:
			result = 1.0 - min(1, parameters.occlusion_mode);
			break;
		case Debug2Mode_2:
			result = 1.0;
			break;
		case Debug2Mode_3:
			result = 1.0 - min(1, parameters.occlusion_mode) * saturate(u_sggi_param[0].y * (parameters.roughness - u_sggi_param[0].x));
			break;
	}

	if(parameters.occlusion_mode == OcclusionMode_ShadowGI)
	{
		result = lerp(result, 1.0, parameters.metallic);
	}

	return result;
}

float3 ComputeReflectionDirection(float3 normal, float3 view_direction, float roughness)
{
	float3 result = normalize(saturate(dot(view_direction, normal)) * 2 * normal - view_direction);

	result -= normal;
	result *= saturate(1.0 - roughness) * (sqrt(saturate(1.0 - roughness)) + roughness);
	result += normal;

	return result;
}

float ComputeIBLLevel(float roughness)
{
	float ibl_probe_lod = 6;
	return sqrt(saturate(roughness)) * ibl_probe_lod;
}

float4 SampleReflectionProbe(EnvProbeData probe, float4 position, float3 normal, float3 view_direction, float roughness)
{
	float3 reflection_direction = ComputeReflectionDirection(normal, view_direction, roughness);
	float3 probe_offset = position.xyz - probe.position;

	float3 intersection_position;
	switch(probe.type)
	{
		case EnvProbeType_Box_PCR:
			float3 local_pos = mul(probe.inv_world_matrix, position).xyz;
			float3 local_refl_dir = mul((float3x3)probe.inv_world_matrix, reflection_direction);

			float3 unitary = 1.0f;
			float3 firstPlaneIntersect = (unitary - local_pos) / local_refl_dir;
			float3 secondPlaneIntersect = (-unitary - local_pos) / local_refl_dir;

			float3 furthestPlane = max(firstPlaneIntersect, secondPlaneIntersect);
			float distance = min(furthestPlane.x, min(furthestPlane.y, furthestPlane.z));

			intersection_position = reflection_direction * distance + probe_offset;
			break;

		case EnvProbeType_Sphere_PCR:
			float3 probe_direction = normalize(probe_offset);
			float cos_probe_refl = dot(probe_direction, -reflection_direction);
			float cos_probe_refl_2 = pow(cos_probe_refl * length(probe_offset), 2);

			float t2 = dot(probe_offset, probe_offset);
			t2 -= cos_probe_refl_2;
			t2 = sqrt(t2);
			t2 = probe.radius * probe.radius - t2 * t2;
			t2 = sqrt(t2);
			t2 += cos_probe_refl_2;

			intersection_position = reflection_direction * t2 + probe_offset;
			break;

		default:
			intersection_position = reflection_direction;
			break;
	}

	float4 sample_pos = float4(
		intersection_position * float3(1,1,-1),
		probe.ibl_index
	);

	float ibl_level = ComputeIBLLevel(roughness);

	return SampleTextureLevel(s_IBLProbeArray, sample_pos, ibl_level);
}

float4 ComputeReflectionProbeColor(uint2 tile_position, float4 position, float3 normal, float3 view_direction, float roughness)
{
	#ifndef enable_para_corr
		return 0.0;
	#endif

	float3 color = 0.0;
	float influence = 0.0;

	LocalLightHeader llh = GetLocalLightHeader(tile_position);

	float remainder = 1.0;

	for(int i = 0; i < llh.env_probe_count && remainder > 0.0 && influence < 1.0; i++)
	{
		uint probe_index = GetEnvProbeIndex(llh, i);
		EnvProbeData probe_data = GetEnvProbeData(probe_index);

		float ibl_factor = ComputeProbeInfluence(probe_data, position);

		if(ibl_factor <= 0.0)
		{
			continue;
		}

        float4 ibl = SampleReflectionProbe(
			probe_data,
			position,
			normal,
			view_direction,
			roughness
		);

		ibl_factor = min(ibl_factor, remainder);
        color += ibl.xyz * ibl_factor;

        remainder -= ibl_factor;
        influence += ibl_factor * ibl.w;
	}

	return float4(color, influence);
}

float4 ComputeSkyboxReflectionColor(float3 normal, float3 view_direction, float roughness, float occlusion)
{
	float3 reflection_direction = ComputeReflectionDirection(normal, view_direction, roughness);
	float ibl_level = ComputeIBLLevel(roughness);

    float4 ibl_color = SampleTextureLevel(
		s_IBL,
		reflection_direction * float3(1,1,-1),
		ibl_level
	);

	ibl_color.xyz = lerp(
		max(0.0, exp2(log2(max(0.0, ibl_color.xyz + 1.0)) * u_ibl_param.x) - 1.0),
		ibl_color.xyz,
		occlusion
	);

    return ibl_color;
}

float4 ComputeEnvironmentReflectionColor(LightingParameters parameters, float skybox_occlusion, bool specular)
{
	float4 probe_reflection = ComputeReflectionProbeColor(
		parameters.tile_position,
		parameters.world_position,
		parameters.world_normal,
		parameters.view_direction,
		parameters.roughness
	);

	#ifdef enable_para_corr
		skybox_occlusion *= parameters.cavity;
	#endif

	float4 skybox_reflection = ComputeSkyboxReflectionColor(
		parameters.world_normal,
		parameters.view_direction,
		parameters.roughness,
		skybox_occlusion
	);

	float4 result = skybox_reflection;
	result *= saturate(1.0 - probe_reflection.w);
	result.xyz += probe_reflection.xyz;

	if(specular)
	{
		float2 env_brdf = ComputeEnvironmentBRDF(parameters.shading_model.type, parameters.cos_view_normal, parameters.roughness);
		float3 fresnel_color = parameters.fresnel_reflectance * env_brdf.x + env_brdf.y;
		result.xyz *= fresnel_color;
		result.xyz = max(0.0, result.xyz);
	}

	return result;
}

float2 ComputeRLRPosition(float2 screen_position, float3 position, float3 normal, float3 view_direction)
{
	#ifdef IS_COMPUTE_SHADER
		return screen_position;
	#else
		float3 ddx = ddx_coarse(position);
		float3 ddy = ddy_coarse(position);
		float3 geo_normal = normalize(cross(ddx, ddy));

		float3 ref_view_geonrm = reflect(view_direction, geo_normal);
		float3 ref_view_nrm = view_direction - normal * saturate(dot(view_direction, normal)) * 2;

		float cos_view_geonrm_raw = dot(view_direction, ref_view_geonrm);
		float cos_view_geonrm = abs(cos_view_geonrm_raw);
		float asin_view_geonrm = asin_view_geonrm = min(1.0, asin(cos_view_geonrm) * 0.9);

		float3 reflection_dir = lerp(ref_view_geonrm, ref_view_nrm, asin_view_geonrm) - ref_view_nrm;

		float2 result = mul(reflection_dir, (float3x3)view_matrix).xy;
		result.y = abs(result.y);

		result *= u_rlr_param[0].z;
		result = clamp(result, -u_rlr_param[0].w, u_rlr_param[0].w);
		result += screen_position;
		return min(u_rlr_param[0].xy, result);
	#endif
}

float4 ComputeScreenSpaceReflectionColor(LightingParameters parameters)
{
	if(!enable_rlr)
	{
		return 0.0;
	}

	float2 sample_pos = ComputeRLRPosition(
		parameters.screen_position,
		parameters.world_position.xyz,
		parameters.world_normal,
		parameters.view_direction
	);

	float4 rlr_color = SampleTextureLevel(
		s_RLR,
		sample_pos,
		u_rlr_param[1].w * parameters.roughness
	);

	float2 env_bdrf = ComputeEnvironmentBRDF(parameters.shading_model.type, parameters.cos_view_normal, parameters.roughness);
    float3 fresnel_color = parameters.fresnel_reflectance * env_bdrf.x + env_bdrf.y;

	return float4(
		max(0.0, fresnel_color * rlr_color.xyz),
		smoothstep(1.0 - u_sggi_param[1].x, 1.0001, rlr_color.w)
	);
}

float4 ComputeReflectionColor(LightingParameters parameters, float shadow)
{
	float reflection_occlusion = ComputeReflectioOcclusion(parameters);

	if(reflection_occlusion <= 0.00001)
	{
		return float4(0, 0, 0, 1);
	}

	float4 environment_reflection = ComputeEnvironmentReflectionColor(parameters, shadow, true);
	float4 ssr = ComputeScreenSpaceReflectionColor(parameters);

	//////////////////////////////////////////////////

	float4 result = environment_reflection;

	result.xyz *= reflection_occlusion;

	result = lerp(result, float4(ssr.xyz, 1.0), ssr.w);
	result.w *= (1.0 - ssr.w);

	result.xyz *= parameters.cavity;

	return result;
}


#endif