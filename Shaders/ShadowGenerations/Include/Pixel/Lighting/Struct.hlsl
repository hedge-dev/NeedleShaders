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

    float3 albedo;
    float3 emission;

	float3 sss_param;
	float2 anisotropy;

	uint2 pixel_position;
	uint2 tile_position;

	float depth;
	float view_distance;
	float2 screen_position;
	float4 world_position;

    float3 world_normal;
	float3 anisotropic_tangent;
	float3 anisotropic_binormal;

	float3 view_direction;
	float cos_view_normal;

	// Standard PBR properties
	float specular;
	float roughness;
	float metallic;
	float cavity;
	float3 fresnel_reflectance;

	float3 shadow_position;
	float shadow_depth;

	float lightfield_ao;
	float shadow;

	TypedOcclusion typed_occlusion;
	LightScatteringColors light_scattering_colors;
};

LightingParameters InitLightingParameters()
{
	LightingParameters result = {
		{ 0, false, 0 },

		{0.0, 0.0, 0.0},
		{0.0, 0.0, 0.0},

		{0.0, 0.0, 0.0},
		{0.0, 0.0},

		{0, 0},
		{0, 0},

		0.0,
		0.0,
		{0.0, 0.0},
		{0.0, 0.0, 0.0, 0.0},

		{0.0, 0.0, 0.0},
		{0.0, 0.0, 0.0},
		{0.0, 0.0, 0.0},

		{0.0, 0.0, 0.0},
		0.0,

		0.0, 0.0, 0.0, 0.0,
		{0.0, 0.0, 0.0},

		{0.0, 0.0, 0.0}, 0.0,

		0.0, 0.0,

		{ 0.0, 0, false },
		{ {0.0, 0.0, 0.0}, {0.0, 0.0, 0.0} }
	};

	return result;
}

void TransferVertexData(PixelInput input, inout LightingParameters parameters)
{
	parameters.screen_position = input.position.xy * u_screen_info.zw;
	parameters.world_position = WorldPosition4(input);
	parameters.world_normal = input.world_normal.xyz;
	parameters.view_direction = normalize(u_cameraPosition.xyz - parameters.world_position.xyz);
	parameters.cos_view_normal = saturate(dot(parameters.view_direction, parameters.world_normal));

	parameters.pixel_position = (uint2)(parameters.screen_position * u_screen_info.xy);
	parameters.tile_position = parameters.pixel_position >> 4;

	#ifdef enable_deferred_rendering
		parameters.shadow_position = input.shadow_position;
		parameters.shadow_depth = input.shadow_depth;
		parameters.light_scattering_colors.factor = input.light_scattering_factor;
		parameters.light_scattering_colors.base = input.light_scattering_base;
	#endif
}

void TransferSurfaceParameters(SurfaceParameters in_param, inout LightingParameters out_param)
{
	out_param.shading_model = in_param.shading_model;

	out_param.albedo = in_param.albedo;

	out_param.world_normal = in_param.normal;
	out_param.cos_view_normal = saturate(dot(out_param.view_direction, out_param.world_normal));

	switch(out_param.shading_model.type)
	{
		case ShadingModelType_SSS:
			out_param.sss_param = in_param.emission;
			break;

		case ShadingModelType_AnisotropicReflection:
			out_param.anisotropy = float2(
				2 * floor(abs(in_param.emission.z)),
				10 * frac(abs(in_param.emission.z))
			);

			out_param.anisotropic_tangent = CorrectedZNormal(in_param.emission);
			out_param.anisotropic_binormal = ComputeBinormal(out_param.anisotropic_tangent, out_param.world_normal);
			break;

		default:
			out_param.emission = in_param.emission;
			break;
	}

	out_param.typed_occlusion = in_param.typed_occlusion;

	out_param.specular = in_param.specular;
	out_param.roughness = in_param.roughness;
	out_param.cavity = in_param.cavity;
	out_param.metallic = in_param.metallic;

	out_param.fresnel_reflectance = lerp(
		out_param.specular,
		out_param.albedo,
		out_param.metallic
	);
}

void TransferSurfaceData(SurfaceData data, inout LightingParameters parameters)
{
	parameters.shading_model = ShadingModelFromFlags((uint)(data.albedo.w * 255));

	parameters.albedo = data.albedo.xyz;

	parameters.world_normal = data.normal * 2.0 - 1.0;
	parameters.cos_view_normal = saturate(dot(parameters.view_direction, parameters.world_normal));

	switch(parameters.shading_model.type)
	{
		case ShadingModelType_SSS:
			parameters.sss_param = data.emission.xyz;
			break;

		case ShadingModelType_AnisotropicReflection:
			parameters.anisotropy = float2(
				2 * floor(abs(data.emission.z)),
				10 * frac(abs(data.emission.z))
			);

			parameters.anisotropic_tangent = CorrectedZNormal(data.emission.xyz);
			parameters.anisotropic_binormal = ComputeBinormal(parameters.anisotropic_tangent, parameters.world_normal);
			break;

		default:
			parameters.emission = data.emission.xyz;
			break;
	}

	parameters.typed_occlusion = DecodeTypedOcclusion(data.emission.w);

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

	parameters.specular = data.prm.x;
	parameters.roughness = data.prm.y;
	parameters.cavity = data.prm.z;
	parameters.metallic = data.prm.w;

	parameters.fresnel_reflectance = lerp(
		parameters.specular,
		parameters.albedo,
		parameters.metallic
	);
}

void TransferPixelData(uint2 pixel_position, float2 screen_position, float depth, inout LightingParameters parameters)
{
	parameters.depth = depth;
	parameters.view_distance = DepthToViewDistance(depth);

	parameters.pixel_position = pixel_position;
	parameters.tile_position = pixel_position.xy >> 4;

	parameters.screen_position = screen_position;
	parameters.world_position = ScreenDepthToWorldPosition(parameters.screen_position, depth);

	parameters.view_direction = normalize(u_cameraPosition.xyz - parameters.world_position.xyz);
	parameters.cos_view_normal = saturate(dot(parameters.view_direction, parameters.world_normal));

	parameters.shadow_position = ComputeShadowPosition(parameters.world_position).xyz;
	parameters.shadow_depth = ComputeShadowDepth(parameters.world_position);

	parameters.light_scattering_colors = ComputeLightScatteringColors(parameters.view_distance, parameters.view_direction);
}

#endif