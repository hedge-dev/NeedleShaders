#ifndef MATERIAL_PIXEL_INCLUDED
#define MATERIAL_PIXEL_INCLUDED

#include "../IOStructs.hlsl"
#include "Surface/Struct.hlsl"

#ifdef enable_deferred_rendering

	#define ProcessSurface(input, surface) SurfaceParamToData(surface)

#else

	#define shadow_as_pcf
	#define no_enable_ssss
	#define enable_local_light_shadow
	#define disable_sh_probes
	#define no_enable_deferred_ambient
	#define enable_para_corr

	#include "Lighting/Shadow.hlsl"
	#include "Lighting/Composite.hlsl"

	float3 Something(float2 pixel_position, float3 out_color)
	{
		float2 some_pos = pixel_position * u_screen_info.zw - g_global_user_param_2.zw;
		some_pos.x *= g_global_user_param_2.y;

		if(length(some_pos) > g_global_user_param_2.x)
		{
			return out_color;
		}

		uint t = (uint)floor(g_global_user_param_3.y);

		switch(t)
		{
			case 0:
			case 2:
				float t2 = dot(out_color, float3(0.2125,0.7154,0.0721));
				return lerp(out_color, t2, g_global_user_param_3.x);;
			case 1:
				float t4 = max(out_color.x, max(out_color.y, out_color.z));
				return lerp(out_color, t4 - out_color, g_global_user_param_3.x);
			default:
				return out_color;
		}
	}

	PixelOutput ProcessSurface(PixelInput input, SurfaceParameters surface)
	{
		LightingParameters parameters = InitLightingParameters();
		TransferVertexData(input, parameters);
		TransferSurfaceParameters(surface, parameters);

		//////////////////////////////////////////////////
		// Shadows

		if(enable_shadow_map)
		{
			parameters.shadow *= ComputeShadowValue(parameters.shadow_position, parameters.shadow_depth, parameters.screen_position);
		}

		ComputeVolShadowValue(parameters.world_position.xyz, parameters.shadow);

		//////////////////////////////////////////////////
		// Lighting

		float3 sunlight_diffuse = DiffuseBDRF(parameters, u_lightDirection.xyz, u_lightColor.xyz);
		float3 sunlight_specular = SpecularBRDF(parameters, u_lightDirection.xyz, u_lightColor.xyz, parameters.shading_model.type == ShadingModelType_AnisotropicReflection);

		float3 positional_light_diffuse;
		float3 positional_light_specular;
		ComputePositionalLighting(parameters, positional_light_diffuse, positional_light_specular);

		//////////////////////////////////////////////////
		// Ambient Lighting

		float3 ambient_color = 0.0;

		if(parameters.shading_model.type != ShadingModelType_1 && parameters.typed_occlusion.mode == OcclusionType_AOLightField)
		{
			ambient_color = ComputeAmbientColor(parameters);
			ambient_color *= 1.0 - parameters.metallic;
			ambient_color *= 1.0 - parameters.fresnel_reflectance;
			ambient_color *= parameters.cavity;
		}

		//////////////////////////////////////////////////
		// Reflections

		float reflection_occlusion = ComputeReflectionOcclusion(parameters, parameters.shadow);
		float4 reflection_color = ComputeReflectionColor(parameters, reflection_occlusion, true);

		sunlight_specular *= ComputeIBLDirectionalSpecularFactor(parameters);

		//////////////////////////////////////////////////
		// Combining lights

		float3 out_diffuse = sunlight_diffuse * parameters.shadow + positional_light_diffuse;
		float3 out_specular = sunlight_specular * parameters.shadow + positional_light_specular;
		ambient_color *= parameters.cavity;

		float3 out_direct = max(0.0, out_diffuse) / Pi;
		out_direct += ambient_color;
		out_direct *= parameters.albedo;

		float3 out_indirect = max(0.0, out_specular);
		out_indirect += reflection_color.xyz;

		//////////////////////////////////////////////////
		// debug switch 1

		//////////////////////////////////////////////////
		// shadow cascade (?)

		out_direct *= ComputeShadowCascadeColor(parameters.world_position);

		//////////////////////////////////////////////////
		// Output composition

		float3 out_color = (out_direct + out_indirect + parameters.emission) * u_modulate_color.xyz;
		float out_alpha = u_modulate_color.w * surface.transparency;

		//////////////////////////////////////////////////
		// Light scattering

		switch (GetDebugView()) {
			case DebugView_ScatteringFex:
				out_color = parameters.light_scattering_colors.factor;
				break;
			case DebugView_ScatteringLin:
				out_color = parameters.light_scattering_colors.base;
				break;
			default :
				out_color = lerp(out_color, out_color * parameters.light_scattering_colors.factor + parameters.light_scattering_colors.base, g_LightScatteringColor.w);
				break;
		}

		//////////////////////////////////////////////////
		// ???

		out_color = Something(parameters.pixel_position, out_color);

		//////////////////////////////////////////////////
		// Fog

		FogValues fog_values = ComputeFogValues(parameters);
		out_color = lerp(out_color, fog_values.fog_color, fog_values.fog_factor);

		//////////////////////////////////////////////////
		// Output

		PixelOutput result;
		result.Color.xyz = out_color;
		result.Color.w = out_alpha;
		return result;
	}

#endif

#endif