#ifndef REFLECTION_LIGHTING_INCLUDED
#define REFLECTION_LIGHTING_INCLUDED

#include "../../Texture.hlsl"
#include "../../Debug.hlsl"

#include "../EnvironmentBRDF.hlsl"

#include "Struct.hlsl"
#include "LocalLights.hlsl"
#include "EnvironmentalProbe.hlsl"

TextureCubeArray<float4> WithSampler(s_IBLProbeArray);
TextureCube<float4> WithSampler(s_IBL);
Texture2D<float4> WithSampler(s_RLR);

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

float4 ComputeEnvironmentReflectionColor(LightingParameters parameters, float shadow)
{
	float4 probe_reflection = ComputeReflectionProbeColor(
		parameters.tile_position,
		parameters.world_position,
		parameters.world_normal,
		parameters.view_direction,
		parameters.roughness
	);

	float4 skybox_reflection = ComputeSkyboxReflectionColor(
		parameters.world_normal,
		parameters.view_direction,
		parameters.roughness,
		parameters.ambient_occlusion * shadow
	);

	float2 env_bdrf = ComputeEnvironmentBRDF(parameters.shader_model, parameters.cos_view_normal, parameters.roughness);
    float3 fresnel_color = parameters.fresnel_reflectance * env_bdrf.x + env_bdrf.y;

	float4 result = skybox_reflection;
	result *= saturate(1.0 - probe_reflection.w);
	result.xyz += probe_reflection.xyz;
	result.xyz *= fresnel_color;
	result.xyz = max(0.0, result.xyz);

	return result;
}

float4 ComputeScreenSpaceReflectionColor(LightingParameters parameters)
{
	if(!enable_ibl_plus_directional_specular)
	{
		return 0.0;
	}

	float4 rlr_color = SampleTextureLevel(
		s_RLR,
		parameters.screen_position,
		u_rlr_param[1].w * parameters.roughness
	);

	float2 env_bdrf = ComputeEnvironmentBRDF(parameters.shader_model, parameters.cos_view_normal, parameters.roughness);
    float3 fresnel_color = parameters.fresnel_reflectance * env_bdrf.x + env_bdrf.y;

	float3 result_color = max(0.0, rlr_color.xyz * fresnel_color);
	float result_influence = smoothstep(0.0, 1.0, (rlr_color.w - 1.0 + u_sggi_param[1].x) / (u_sggi_param[1].x + 0.0001));

	return float4(result_color, result_influence);
}

float4 ComputeReflectionColor(LightingParameters parameters, float ambient_occlusion, float shadow)
{
	if(ambient_occlusion <= 0.00001)
	{
		return float4(0, 0, 0, 1);
	}

	float4 environment_reflection = ComputeEnvironmentReflectionColor(parameters, shadow);
	float4 ssr = ComputeScreenSpaceReflectionColor(parameters);

	//////////////////////////////////////////////////

	float4 result = environment_reflection;

	result.xyz *= ambient_occlusion;

	result = lerp(result, float4(ssr.xyz, 1.0), ssr.w);
	result.w *= (1.0 - ssr.w);

	result.xyz *= parameters.ambient_occlusion;

	//////////////////////////////////////////////////
	// Debug stuff

	if(!enable_ibl_plus_directional_specular)
	{
		result.w *= min(1, parameters.occlusion_mode);

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

		result.w *= debug_factor;
	}

	return result;
}


#endif