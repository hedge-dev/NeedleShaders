#ifndef IBL_PROBE_LIGHTING_INCLUDED
#define IBL_PROBE_LIGHTING_INCLUDED

#include "../../Common.hlsl"

#if !defined(enable_para_corr) && !defined(no_enable_para_corr)
	DefineFeature(enable_para_corr);
#endif

#include "Struct.hlsl"
#include "EnvironmentalProbe.hlsl"
#include "LocalLights.hlsl"
#include "IBL.hlsl"

#ifdef enable_para_corr
	#include "../../Texture.hlsl"
	TextureCubeArray<float4> WithSampler(s_IBLProbeArray);
#endif

float4 SampleIBLProbe(EnvProbeData probe, LightingParameters parameters)
{
	#ifndef enable_para_corr
		return 0.0;
	#else
		float3 reflection_direction = ComputeIBLDirection(parameters.world_normal, parameters.view_direction, parameters.roughness);
		float3 probe_offset = parameters.world_position.xyz - probe.position;

		float3 intersection_position;
		switch(probe.type)
		{
			case EnvProbeType_Box_PCR:
				float3 local_pos = mul(probe.inv_world_matrix, parameters.world_position).xyz;
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

		float ibl_level = ComputeIBLLevel(parameters.roughness);

		return SampleTextureLevel(s_IBLProbeArray, sample_pos, ibl_level);
	#endif
}

float4 ComputeIBLProbeColor(LightingParameters parameters)
{
	#ifndef enable_para_corr
		return 0.0;
	#else
		float3 color = 0.0;
		float influence = 0.0;

		LocalLightHeader llh = GetLocalLightHeader(parameters.tile_position);

		float remainder = 1.0;

		for(int i = 0; i < llh.env_probe_count && remainder > 0.0 && influence < 1.0; i++)
		{
			uint probe_index = GetEnvProbeIndex(llh, i);
			EnvProbeData probe_data = GetEnvProbeData(probe_index);

			float ibl_factor = ComputeProbeInfluence(probe_data, parameters.world_position);

			if(ibl_factor <= 0.0)
			{
				continue;
			}

			float4 ibl = SampleIBLProbe(probe_data, parameters);

			ibl_factor = min(ibl_factor, remainder);
			color += ibl.xyz * ibl_factor;

			remainder -= ibl_factor;
			influence += ibl_factor * ibl.w;
		}

		return float4(color, influence);
	#endif
}

void ComputeApplyIBLProbeColor(LightingParameters parameters, inout float4 result)
{
	#ifdef enable_para_corr
		return;
	#endif

	float4 probe_reflection = ComputeIBLProbeColor(parameters);
	result *= saturate(1.0 - probe_reflection.w);
	result.xyz += probe_reflection.xyz;
}

#endif