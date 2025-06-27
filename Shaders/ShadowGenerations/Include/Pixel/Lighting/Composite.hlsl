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
#include "LocalLights.hlsl"
#include "Fog.hlsl"
#include "Ambient.hlsl"

Texture2D<float4> WithSampler(s_EnvBRDF);
Texture2D<float4> WithSampler(s_SSAO);
Texture2D<float4> WithSampler(s_RLR);
TextureCubeArray<float4> WithSampler(s_IBLProbeArray);

void something(inout float3 emission, inout float3 albedo_5, float sggi_thing_w)
{
	if(sggi_thing_w <= 0.00001)
	{
		return;
	}

	//TODO
}

float4 CompositeLighting(LightingParameters parameters)
{
	//////////////////////////////////////////////////
	// Ambient Occlusion

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

	if(parameters.flags_unk1 != 0)
	{
		parameters.emission *= shadow * u_lightColor.xyz * parameters.albedo;
	}

	//////////////////////////////////////////////////
	// Lighting

	float3 sunlight_diffuse = DiffuseBDRF(parameters, u_lightDirection.xyz, u_lightColor.xyz, shadow);
	float3 sunlight_specular = SpecularBRDF(parameters, u_lightDirection.xyz, u_lightColor.xyz, shadow, parameters.shader_model == ShaderModel_AnisotropicReflection);

	float3 local_light_diffuse;
	float3 local_light_specular;
	GetLightColors(parameters, local_light_diffuse, local_light_specular);

	float3 ambient_color = ComputeAmbientColor(parameters, lf_ambient_occlusion);
	float ambient_occlusion = GetAmbientOcclusion(parameters);

	//////////////////////////////////////////////////

	something(parameters.emission, sunlight_specular, ambient_occlusion);

	float ssao_thing = ssao.x * ssao.z;
	float3 occlusion_capsule_0 = lerp(u_occlusion_capsule_param[0].xyz, 1.0, ssao.x);
	float3 occlusion_capsule_1 = lerp(u_occlusion_capsule_param[1].xyz, 1.0, ssao.y);

	float3 occlusion_capsule_3 = parameters.shader_model == ShaderModel_1 ? 1.0 : occlusion_capsule_0;

	if(!enable_ibl_plus_directional_specular)
	{
		sunlight_specular *= min(1, parameters.occlusion_mode);

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

		sunlight_specular *= debug_factor;
	}

	float3 out_diffuse = sunlight_diffuse * occlusion_capsule_1;
	out_diffuse += local_light_diffuse * occlusion_capsule_0;
	out_diffuse = max(0.0, out_diffuse);
	out_diffuse /= Pi;
	out_diffuse += occlusion_capsule_3 * ambient_color;
	out_diffuse *= parameters.albedo;

	float3 out_specular = sunlight_specular * ssao_thing;
	out_specular += local_light_specular * ssao_thing;
	out_specular = max(0.0, out_specular);
	out_specular += occlusion_capsule_3 * parameters.emission;

	float out_alpha = 1.0;

	// Debug switch #1 here;

	ApplyShadowCascadeThing(parameters.world_position, out_diffuse);

	if(g_LightScatteringColor.w > 0.001)
	{
		out_diffuse *= lerp(1.0, parameters.light_scattering_colors.factor, g_LightScatteringColor.w);
		out_specular *= lerp(1.0, parameters.light_scattering_colors.factor, g_LightScatteringColor.w);
		parameters.light_scattering_colors.base *= g_LightScatteringColor.w;
	}
	else
	{
		parameters.light_scattering_colors.base = 0.0;
	}

	FogValues fog_values = ComputeFogValues(parameters);
	out_diffuse *= (1.0 - fog_values.fog_factor);
	out_specular *= (1.0 - fog_values.fog_factor);

	parameters.light_scattering_colors.base = lerp(
		parameters.light_scattering_colors.base,
		fog_values.fog_color,
		fog_values.fog_factor
	);

	// Debug switch #2 here;

	float3 out_color = out_specular + parameters.light_scattering_colors.base;

	WriteSSSOutput(
		parameters.pixel_position,
		parameters.shader_model,
		parameters.world_normal,
		parameters.albedo,
		ambient_color,
		out_diffuse,
		parameters.sss_param,
		out_color
	);

	return float4(out_color, out_alpha);
}

#endif