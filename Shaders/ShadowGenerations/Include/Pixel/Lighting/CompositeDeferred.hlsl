#ifndef COMPOSITE_DEFERRED_LIGHTING_INCLUDED
#define COMPOSITE_DEFERRED_LIGHTING_INCLUDED

#include "../../ConstantBuffer/World.hlsl"

#include "../../Debug.hlsl"
#include "../../Texture.hlsl"
#include "../../Transform.hlsl"

#include "../EnvironmentBRDF.hlsl"
#include "../ShadowCascade.hlsl"

#include "Struct.hlsl"
#include "SubsurfaceScattering.hlsl"
#include "PositionalLighting.hlsl"
#include "Fog.hlsl"
#include "Light.hlsl"
#include "Ambient.hlsl"
#include "Reflection.hlsl"
#include "Debug.hlsl"

// disabling the SSAO features
#define no_enable_ssao
#define no_enable_noisy_upsample
#include "SSAO.hlsl"

float4 CompositeReflection(LightingParameters parameters)
{
	if(parameters.shading_model.type == ShadingModelType_Hair)
	{
		return float4(0, 0, 0, 1);
	}

	int debug_view = GetDebugView();
	if(debug_view == DebugView_AmbDiffuse
		|| debug_view == DebugView_Ambient
		|| debug_view == DebugView_AmbDiffuseLf
		|| debug_view == DebugView_SggiOnly)
	{
		return float4(0, 0, 0, 1);
	}

	return ComputeReflection(parameters, true);
}

float4 CompositeDeferredLighting(LightingParameters parameters, out float4 ssss_output, out float ssss_mask)
{
	//////////////////////////////////////////////////
	// SSAO & Shadows

	float4 ssao = SampleTextureLevel(s_SSAO, parameters.screen_position, 0);
	ssao.xyz = saturate(ssao.xyz + u_ssao_param.x);
	parameters.shadow = min(parameters.shadow, ssao.w);

	//////////////////////////////////////////////////
	// Emission

	float3 emission_color = parameters.emission;
	if(parameters.shading_model.is_vegetation)
	{
		emission_color *= parameters.shadow * u_lightColor.xyz * parameters.albedo;
	}

	float3 indirect_color = emission_color;

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

	if(parameters.shading_model.type != ShadingModelType_Hair && parameters.typed_occlusion.mode == OcclusionType_AOLightField)
	{
		ambient_color = ComputeAmbientColor(parameters);
		ambient_color *= 1.0 - parameters.metallic;
		ambient_color *= 1.0 - parameters.fresnel_reflectance;
		ambient_color *= parameters.cavity;
	}

	switch(GetDebugView())
	{
		case DebugView_SggiOnly:
			ambient_color = 0.0;
			break;
		case DebugView_AmbDiffuseLf:
			ambient_color = parameters.lightfield_ao;
			break;
	}

	//////////////////////////////////////////////////
	// reflection stuff

	float4 reflections = CompositeReflection(parameters);
	indirect_color += reflections.xyz;
	sunlight_specular *= reflections.w;

	sunlight_specular *= ComputeIBLDirectionalSpecularFactor(parameters);

	//////////////////////////////////////////////////
	// Applying occlusion parameters (?)

	float3 occlusion_capsule_0 = lerp(u_occlusion_capsule_param[0].xyz, 1.0, ssao.x);
	float3 occlusion_capsule_1 = lerp(u_occlusion_capsule_param[1].xyz, 1.0, ssao.y);
	float3 occlusion_capsule_2 = parameters.shading_model.type == ShadingModelType_Hair ? 1.0 : occlusion_capsule_0;

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
		out_direct,
		out_indirect,
		out_alpha
	);

	//////////////////////////////////////////////////
	// shadow cascade debugging

	out_direct *= ComputeShadowCascadeDebugColor(parameters.world_position);

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