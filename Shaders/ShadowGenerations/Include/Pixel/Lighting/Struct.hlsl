#ifndef STRUCTS_LIGHTING_INCLUDED
#define STRUCTS_LIGHTING_INCLUDED

#include "../../IOStructs.hlsl"
#include "../../LightScattering.hlsl"
#include "../../Math.hlsl"

#include "../Surface/Struct.hlsl"

#include "../Normals.hlsl"
#include "../ShaderModel.hlsl"

struct LightingParameters
{
	uint shader_model;
	bool flags_unk1;
	uint flags_unk2; // affects weather

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
	float ambient_occlusion;
	float3 fresnel_reflectance;

	uint occlusion_mode;
	int occlusion_sign;
	float occlusion_value;

	LightScatteringColors light_scattering_colors;
};

LightingParameters InitLightingParameters()
{
	LightingParameters result = {
		0, false, 0,

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

void TransferInputData(PixelInput input, inout LightingParameters parameters)
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
	uint flags = (uint)(data.albedo.w * 255);
	parameters.shader_model = UnpackUIntBits(flags, 3, 0);
	parameters.flags_unk1 = (bool)UnpackUIntBits(flags, 1, 3);
	parameters.flags_unk2 = UnpackUIntBits(flags, 2, 4);

	parameters.albedo = data.albedo.xyz;

	parameters.world_normal = data.normal * 2.0 - 1.0;
	parameters.cos_view_normal = saturate(dot(parameters.view_direction, parameters.world_normal));

	switch(parameters.shader_model)
	{
		case ShaderModel_SSS:
			parameters.sss_param = data.emission.xyz;
			break;

		case ShaderModel_AnisotropicReflection:
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
	parameters.ambient_occlusion = data.prm.z;
	parameters.metallic = data.prm.w;

	parameters.fresnel_reflectance = lerp(
		parameters.specular,
		parameters.albedo,
		parameters.metallic
	);


}

#endif