#ifndef AMBIENT_LIGHTING_INCLUDED
#define AMBIENT_LIGHTING_INCLUDED

//#include "../../Common.hlsl"
//DefineFeature(enable_deferred_ambient);
static const uint FEATURE_enable_deferred_ambient;

#include "../../Debug.hlsl"

#include "Struct.hlsl"
#include "SHProbe.hlsl"
#include "SGLightField.hlsl"

float3 ComputeAmbientColor(LightingParameters parameters, float lf_ambient_occlusion)
{
	switch(GetDebugMode())
	{
		case DebugMode_4:
			// replaces parameters.ambient_occlusion with 0
			return 0.0;
		case DebugMode_43:
			return lf_ambient_occlusion;
		case DebugMode_44:
			return 0.0;
	}

	if(parameters.shader_model == ShaderModel_1 || parameters.occlusion_mode != 0)
	{
		return 0.0;
	}

	lf_ambient_occlusion = min(lf_ambient_occlusion, parameters.ambient_occlusion);

	float3 result = 0.0;

	#ifdef enable_deferred_ambient
		result = ComputeSHProbeColor(parameters.tile_position, parameters.world_position, parameters.world_normal, lf_ambient_occlusion);
	#else
		SGLightFieldInfo light_field = ComputeSGLightFieldInfo(parameters.world_position, parameters.world_normal);

		if(light_field.data.unk2 == 0)
		{
			result = ComputeSGLightFieldColor(parameters.world_normal, light_field.axis_colors);

			if(shlightfield_param.x > 0)
			{
				result += ComputeSHProbeColor(parameters.tile_position, parameters.world_position, parameters.world_normal, lf_ambient_occlusion);
			}
		}
		else if(shlightfield_param.x > 0)
		{
			result = ComputeSHProbeColor(parameters.tile_position, parameters.world_position, parameters.world_normal, lf_ambient_occlusion);
		}
		else if(light_field.data.unk2 == 2)
		{
			if(light_field.in_field)
			{
				float3 combined_buffer = lerp(
					float3(light_field.axis_colors[1].x, light_field.axis_colors[3].x, light_field.axis_colors[5].x),
					float3(light_field.axis_colors[0].x, light_field.axis_colors[2].x, light_field.axis_colors[4].x),
					parameters.world_normal * 0.5 + 0.5
				);

				float sglf_ao = saturate(dot(combined_buffer, parameters.world_normal * parameters.world_normal));
				lf_ambient_occlusion = min(lf_ambient_occlusion, sglf_ao);
			}

			result = ComputeSHProbeColor(parameters.tile_position, parameters.world_position, parameters.world_normal, lf_ambient_occlusion);
		}
	#endif

	result = max(0.0, result);

	result *= lerp(
		shlightfield_multiply_color_down.xyz,
		shlightfield_multiply_color_up.xyz,
		parameters.world_normal.y * 0.5 + 0.5
	);

	result *= shlightfield_param.y;
	result *= 1.0 - parameters.metallic;
	result *= 1.0 - parameters.fresnel_reflectance;
	result *= parameters.ambient_occlusion;

	return result;
}

float GetAmbientOcclusion(LightingParameters parameters)
{
	if(parameters.shader_model == ShaderModel_1)
	{
		return 0.0;
	}

	int debug_mode = GetDebugMode();
	if(debug_mode == DebugMode_3
		|| debug_mode == DebugMode_19
		|| debug_mode == DebugMode_43
		|| debug_mode == DebugMode_44)
	{
		return 0.0;
	}

	float result = parameters.ambient_occlusion;

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

	if(parameters.occlusion_mode == 1)
	{
		result = lerp(result, 1.0, parameters.metallic);
	}

	return result;
}

#endif