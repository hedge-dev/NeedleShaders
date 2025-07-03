#ifndef STRUCTS_LIGHTING_INCLUDED
#define STRUCTS_LIGHTING_INCLUDED

#include "../../IOStructs.hlsl"
#include "../../LightScattering.hlsl"
#include "../../Math.hlsl"
#include "../../Transform.hlsl"

#include "../Surface/Struct.hlsl"

#include "../Normals.hlsl"
#include "../ShadingModel.hlsl"

struct LightingParameters
{
	ShadingModel shading_model;

    float3 albedo;
    float3 emission;

	float3 sss_param;
	float2 anisotropy;

	uint2 pixel_position;
	uint2 tile_position;

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

	uint occlusion_mode;
	int occlusion_sign;
	float occlusion_value;

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
		{0.0, 0.0},
		{0.0, 0.0, 0.0, 0.0},

		{0.0, 0.0, 0.0},
		{0.0, 0.0, 0.0},
		{0.0, 0.0, 0.0},

		{0.0, 0.0, 0.0},
		0.0,

		0.0, 0.0, 0.0, 0.0,
		{0.0, 0.0, 0.0},

		0, 0, 0.0,

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
		parameters.light_scattering_colors.factor = input.light_scattering_factor;
		parameters.light_scattering_colors.base = input.light_scattering_base;
	#endif
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

	parameters.occlusion_sign = sign(data.emission.w);
	parameters.occlusion_mode = (uint)trunc(0.1 * abs(data.emission.w));
	parameters.occlusion_value = abs(data.emission.w) - parameters.occlusion_mode * 10;

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

void TransferPixelData(uint2 pixel_position, float depth, inout LightingParameters parameters)
{
	parameters.view_distance = DepthToViewDistance(depth);

	parameters.pixel_position = pixel_position;
	parameters.tile_position = pixel_position.xy >> 4;

	parameters.screen_position = PixelToScreen(pixel_position);
	parameters.world_position = ScreenDepthToWorldPosition(parameters.screen_position, depth);

	parameters.view_direction = normalize(u_cameraPosition.xyz - parameters.world_position.xyz);
	parameters.cos_view_normal = saturate(dot(parameters.view_direction, parameters.world_normal));
	parameters.light_scattering_colors = ComputeLightScatteringColors(parameters.view_distance, parameters.view_direction);
}

#endif