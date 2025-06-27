#ifndef STRUCTS_LIGHTING_INCLUDED
#define STRUCTS_LIGHTING_INCLUDED

#include "../Surface/Struct.hlsl"
#include "../../IOStructs.hlsl"
#include "../../LightScattering.hlsl"
#include "../../Math.hlsl"
#include "../Normals.hlsl"

static const uint ShadingMode_0 = 0;
static const uint ShadingMode_1 = 1;
static const uint ShadingMode_2 = 2;
static const uint ShadingMode_SSS = 3; // related to SSS
static const uint ShadingMode_AnisotropicReflection = 4;
static const uint ShadingMode_5 = 5;
static const uint ShadingMode_6 = 6;
static const uint ShadingMode_7 = 7;

struct LightingParameters
{
	// Lighting flags
	uint shading_mode;
	bool flags_unk1;
	uint flags_unk2;

    float3 albedo;
    float3 emission;

	float3 sss_param;
	float2 anisotropy;

	uint2 pixel_position;
	uint2 tile_position;

	float2 screen_position;
	float4 world_position;

    float3 world_normal;
	float3 anisotropic_tangent;
	float3 anisotropic_binormal;

	float3 view_direction;
	float cos_view_normal;


	// -- Mode dependent ambient occlusion --
	// Mode is set by the 10s (i.e. adding 10, 20 or 30 to the actual AO)
	// (lots of unknown properties here)
	float moded_ambient_occlusion;

	// Standard PBR properties
	float specular;
	float roughness;
	float metallic;
	float ambient_occlusion;
	float3 fresnel_reflectance;

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

		{0.0, 0.0},
		{0.0, 0.0, 0.0, 0.0},

		{0.0, 0.0, 0.0},
		{0.0, 0.0, 0.0},
		{0.0, 0.0, 0.0},

		{0.0, 0.0, 0.0},
		0.0,

		0.0,
		0.0, 0.0, 0.0, 0.0,
		{0.0, 0.0, 0.0},

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
	parameters.shading_mode = UnpackUIntBits(flags, 3, 0);
	parameters.flags_unk1 = (bool)UnpackUIntBits(flags, 1, 3);
	parameters.flags_unk2 = UnpackUIntBits(flags, 2, 4);

	parameters.albedo = data.albedo.xyz;

	parameters.world_normal = data.normal * 2.0 - 1.0;
	parameters.cos_view_normal = saturate(dot(parameters.view_direction, parameters.world_normal));

	if(parameters.shading_mode == ShadingMode_SSS)
	{
		parameters.sss_param = data.emission.xyz;
	}
	else if(parameters.shading_mode == ShadingMode_AnisotropicReflection)
	{
		parameters.anisotropy = float2(
			2 * floor(abs(data.emission.z)),
			10 * frac(abs(data.emission.z))
		);

		parameters.anisotropic_tangent = CorrectedZNormal(data.emission.xyz);
		parameters.anisotropic_binormal = ComputeBinormal(parameters.anisotropic_tangent, parameters.world_normal);
	}
	else
	{
		parameters.emission = data.emission.xyz;
	}

	parameters.moded_ambient_occlusion = data.emission.w;

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