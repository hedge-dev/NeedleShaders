#ifndef AMBIENT_LIGHTING_INCLUDED
#define AMBIENT_LIGHTING_INCLUDED

#include "../../Common.hlsl"
#if !defined(enable_deferred_ambient) && !defined(no_enable_deferred_ambient)
	DefineFeature(enable_deferred_ambient);
#endif

#include "../../Debug.hlsl"

#include "Struct.hlsl"
#include "SHProbe.hlsl"
#include "SGLightField.hlsl"

float3 ComputeAmbientColor(LightingParameters parameters)
{
	float lf_ambient_occlusion = min(parameters.lightfield_ao, parameters.cavity);

	float3 result = 0.0;

	#ifdef enable_deferred_ambient
		result = ComputeSHProbeColor(parameters.tile_position, parameters.world_position, parameters.world_normal, lf_ambient_occlusion);
	#else
		SGLightFieldInfo light_field = ComputeSGLightFieldInfo(parameters.world_position, parameters.world_normal);

		if(light_field.data.type == SGLightFieldType_AmbientLighting)
		{
			result = ComputeSGLightFieldColor(parameters.world_normal, light_field.axis_colors);

			if(AreSHProbesEnabled())
			{
				result += ComputeSHProbeColor(parameters.tile_position, parameters.world_position, parameters.world_normal, lf_ambient_occlusion);
			}
		}
		else if(AreSHProbesEnabled())
		{
			result = ComputeSHProbeColor(parameters.tile_position, parameters.world_position, parameters.world_normal, lf_ambient_occlusion);
		}
		else if(light_field.data.type == SGLightFieldType_AmbientOcclusion)
		{
			float sglf_ao = 1.0;

			if(light_field.in_field)
			{
				float3 combined_buffer = lerp(
					float3(light_field.axis_colors[1].x, light_field.axis_colors[3].x, light_field.axis_colors[5].x),
					float3(light_field.axis_colors[0].x, light_field.axis_colors[2].x, light_field.axis_colors[4].x),
					parameters.world_normal * 0.5 + 0.5
				);

				sglf_ao = saturate(dot(combined_buffer, parameters.world_normal * parameters.world_normal));
			}

			if(UsingSHProbes)
			{
				sglf_ao = min(lf_ambient_occlusion, sglf_ao);
			}

			result = ComputeSHProbeColor(parameters.tile_position, parameters.world_position, parameters.world_normal, sglf_ao);
		}
	#endif

	result = max(0.0, result);

	result *= lerp(
		shlightfield_multiply_color_down.xyz,
		shlightfield_multiply_color_up.xyz,
		parameters.world_normal.y * 0.5 + 0.5
	);

	result *= shlightfield_param.y;
	return result;
}

#endif