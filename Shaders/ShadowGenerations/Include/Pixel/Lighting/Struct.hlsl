#ifndef STRUCTS_LIGHTING_INCLUDED
#define STRUCTS_LIGHTING_INCLUDED

#include "../Surface/Struct.hlsl"
#include "../../IOStructs.hlsl"
#include "../../LightScattering.hlsl"
#include "../../Math.hlsl"

struct LightingParameters
{
	// RGB Diffuse color
    float3 albedo;

	// RGB Emission color
    float3 emission;

	// Lighting flags
	uint raw_flags;
	uint shading_mode;
	uint flags_unk1;

	uint2 pixel_position;
	uint2 tile_position;

	// screen space position/uv
	float2 screen_position;

	// world space position
	float4 world_position;

	// World space normal direction
    float3 world_normal;

	// direction from camera position to world position
	float3 view_direction;


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
		{0.0, 0.0, 0.0},
		{0.0, 0.0, 0.0},

		0, 0, 0,

		{0, 0},
		{0, 0},

		{0.0, 0.0},
		{0.0, 0.0, 0.0, 0.0},
		{0.0, 0.0, 0.0},
		{0.0, 0.0, 0.0},

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
	parameters.view_direction = normalize(u_cameraPosition.xyz - parameters.world_position.xyz);
	parameters.world_normal = input.world_normal.xyz;

	parameters.pixel_position = (uint2)(parameters.screen_position * u_screen_info.xy);
	parameters.tile_position = parameters.pixel_position >> 4;

	#ifdef enable_deferred_rendering
		parameters.light_scattering_colors.factor = input.light_scattering_factor;
		parameters.light_scattering_colors.base = input.light_scattering_base;
	#endif
}

void TransferSurfaceData(SurfaceData data, inout LightingParameters parameters)
{
	parameters.albedo = data.albedo.xyz;

	parameters.raw_flags = (uint)(data.albedo.w * 255);
	parameters.shading_mode = UnpackUIntBits(parameters.raw_flags, 4, 0);
	parameters.flags_unk1 = UnpackUIntBits(parameters.raw_flags, 2, 4);

	parameters.world_normal = data.normal * 2.0 - 1.0;

	parameters.emission = data.emission.xyz;
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