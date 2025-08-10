#ifndef STRUCTS_LIGHTING_INCLUDED
#define STRUCTS_LIGHTING_INCLUDED

#include "../../IOStructs.hlsl"
#include "../../LightScattering.hlsl"
#include "../../Math.hlsl"
#include "../../Transform.hlsl"

#include "../Surface/Struct.hlsl"

#include "../Normals.hlsl"
#include "../ShadingModel.hlsl"
#include "../ShadowCascade.hlsl"
#include "../TypedOcclusion.hlsl"

#include "SHprobe.hlsl"

struct LightingParameters
{
	ShadingModel shading_model;

	// Geometry properties

	float2 screen_position;
	uint2 pixel_position;
	uint2 tile_position;

	float4 world_position;

	float depth;
	float view_distance;

    float3 world_normal;
	float3 anisotropic_tangent;
	float3 anisotropic_binormal;

	float3 view_direction;
	float cos_view_normal;

	float3 shadow_position;
	float shadow_depth;

	// Surface properties

    float3 albedo;

    float3 emission;
	float3 sss_param;
	float2 anisotropy;

	float specular;
	float roughness;
	float metallic;
	float cavity;
	float3 fresnel_reflectance;
	bool approximate_env_brdf;

	float lightfield_ao;
	float shadow;

	TypedOcclusion typed_occlusion;
	LightScatteringColors light_scattering_colors;
};

LightingParameters InitLightingParameters()
{
	LightingParameters result = {
		{ 0, false, 0, 0},

		{0.0, 0.0},
		{0, 0},
		{0, 0},

		{0.0, 0.0, 0.0, 0.0},

		0.0, 0.0,

		{0.0, 0.0, 0.0},
		{0.0, 0.0, 0.0},
		{0.0, 0.0, 0.0},

		{0.0, 0.0, 0.0},
		0.0,

		{0.0, 0.0, 0.0},
		0.0,

		{0.0, 0.0, 0.0},

		{0.0, 0.0, 0.0},
		{0.0, 0.0, 0.0},
		{0.0, 0.0},

		0.0, 0.0, 0.0, 0.0,
		{0.0, 0.0, 0.0},
		false,

		0.0, 0.0,

		{ 0.0, 0, false },
		{ {0.0, 0.0, 0.0}, {0.0, 0.0, 0.0} }
	};

	return result;
}

void LightingParametersCommonSetup(inout LightingParameters parameters)
{
	parameters.tile_position = parameters.pixel_position >> 4;

	if(parameters.shading_model.type == ShadingModelType_AnisotropicReflection)
	{
		parameters.anisotropic_tangent = CorrectedZNormal(parameters.emission);
		parameters.anisotropic_binormal = ComputeBinormal(parameters.anisotropic_tangent, parameters.world_normal);
	}

	parameters.view_direction = normalize(u_cameraPosition.xyz - parameters.world_position.xyz);
	parameters.cos_view_normal = saturate(dot(parameters.view_direction, parameters.world_normal));

	switch(parameters.shading_model.type)
	{
		case ShadingModelType_SSS:
			parameters.sss_param = parameters.emission;
			parameters.emission = 0.0;
			break;

		case ShadingModelType_AnisotropicReflection:
			parameters.anisotropy = float2(
				2 * floor(abs(parameters.emission.z)),
				10 * frac(abs(parameters.emission.z))
			);

			parameters.emission = 0.0;
			break;
	}

	parameters.fresnel_reflectance = lerp(
		parameters.specular,
		parameters.albedo,
		parameters.metallic
	);

	parameters.approximate_env_brdf = parameters.shading_model.type == ShadingModelType_Default;

	parameters.lightfield_ao = 1.0;
	parameters.shadow = 1.0;

	if(parameters.typed_occlusion.mode == OcclusionType_AOLightField && AreSHProbesEnabled())
	{
		parameters.lightfield_ao = parameters.typed_occlusion.value;
	}
	else
	{
		parameters.shadow = parameters.typed_occlusion.value;
	}
}

LightingParameters LightingParametersFromSurface(PixelInput input, SurfaceParameters surface)
{
	LightingParameters result = InitLightingParameters();

	result.shading_model = surface.shading_model;

	// Geometry properties

	result.screen_position = input.position.xy * u_screen_info.zw;
	result.pixel_position = (uint2)(result.screen_position * u_screen_info.xy);

	result.world_position = surface.world_position;

	// Unknown whether these 2 are correct, as they are never actually used like this
	result.view_distance = mul(result.world_position, view_matrix).z;
	result.depth = ViewDistanceToDepth(result.view_distance);

	result.world_normal = surface.normal;

	#ifdef enable_deferred_rendering
		result.shadow_position = ComputeShadowPosition(result.world_position).xyz;
		result.shadow_depth = ComputeShadowDepth(result.world_position);
	#else
		result.shadow_position = input.shadow_position.xyz;
		result.shadow_depth = input.shadow_depth;
	#endif

	// Surface properties

	result.albedo = surface.albedo;
	result.emission = surface.emission;

	result.specular = surface.specular;
	result.roughness = surface.roughness;
	result.cavity = surface.cavity;
	result.metallic = surface.metallic;

	result.typed_occlusion = surface.typed_occlusion;

	#ifdef enable_deferred_rendering
		result.light_scattering_colors = ComputeLightScatteringColors(result.view_distance, result.view_direction);
	#else
		result.light_scattering_colors.factor = input.light_scattering_factor;
		result.light_scattering_colors.base = input.light_scattering_base;
	#endif

	LightingParametersCommonSetup(result);

	return result;
}

LightingParameters LightingParametersFromDeferred(SurfaceData data, uint2 pixel_position, float2 screen_position, float depth)
{
	LightingParameters result = InitLightingParameters();

	result.shading_model = ShadingModelFromFlags((uint)(data.albedo.w * 255));

	// Geometry properties

	result.screen_position = screen_position;
	result.pixel_position = pixel_position;

	result.world_position = ScreenDepthToWorldPosition(result.screen_position, depth);

	result.depth = depth;
	result.view_distance = DepthToViewDistance(depth);

	result.world_normal = data.normal * 2.0 - 1.0;

	result.shadow_position = ComputeShadowPosition(result.world_position).xyz;
	result.shadow_depth = ComputeShadowDepth(result.world_position);

	// Surface properties

	result.albedo = data.albedo.xyz;
	result.emission = data.emission.xyz;

	result.specular = data.prm.x;
	result.roughness = data.prm.y;
	result.cavity = data.prm.z;
	result.metallic = data.prm.w;

	result.typed_occlusion = DecodeTypedOcclusion(data.emission.w);

	result.light_scattering_colors = ComputeLightScatteringColors(result.view_distance, result.view_direction);

	LightingParametersCommonSetup(result);

	return result;
}


#endif