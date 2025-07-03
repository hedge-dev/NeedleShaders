#ifndef STRUCT_SURFACE_INCLUDED
#define STRUCT_SURFACE_INCLUDED

#include "../../ConstantBuffer/World.hlsl"

#include "../../IOStructs.hlsl"
#include "../../Math.hlsl"

#include "../ShadingModel.hlsl"

//////////////////////////////////////////////////
// Surface parameters (input)

struct SurfaceParameters
{
	ShadingModel shading_model;

	float3 albedo;
	float3 emission;

	float specular;
	float roughness;
	float metallic;
	float cavity;

	float3 fresnel_reflectance;

	float3 screen_position;
	float2 screen_tile;
	float3 previous_position;
	float4 world_position;

	float3 normal;
	float3 debug_normal;

	float2 gi_uv;
};

SurfaceParameters InitSurfaceParameters()
{
	SurfaceParameters result = {
		{ 0, false, 0 },

		{0.0, 0.0, 0.0},
		{0.0, 0.0, 0.0},

		0.0, 0.0, 0.0, 0.0,

		{0.0, 0.0, 0.0},

		{0.0, 0.0, 0.0},
		{0.0, 0.0},
		{0.0, 0.0, 0.0},
		{0.0, 0.0, 0.0, 0.0},

		{0.0, 0.0, 0.0},
		{0.0, 0.0, 0.0},

		{0.0, 0.0}
	};

	return result;
}

void SetupSurfaceParamFromInput(PixelInput input, inout SurfaceParameters parameters)
{
    parameters.screen_position = input.position.xyz;
    parameters.screen_tile = uint2(input.position.xy * u_screen_info.zw * u_screen_info.xy) >> 4;

    parameters.world_position = WorldPosition4(input);
    parameters.previous_position = input.previous_position.xyz;

    parameters.gi_uv = input.uv01.zw;
}

//////////////////////////////////////////////////
// Surface data (output)

struct SurfaceData
{
	// --- Albedo ---
	// XYZ: RGB Diffuse color
	// W: Shading model flags
    float4 albedo : SV_Target0;

	// --- Normal ---
	// XYZ: Normalized world space normal
    float3 normal : SV_Target1;

	// --- Emission --
	// XYZ: RGB Emission color
	// W: Occlusion + occlusion mode * 10
    float4 emission : SV_Target2;

	// --- Physical rendering parameters ---
	// X: Specularity
	// Y: Roughness
	// Z: Ambient Occlusion
	// W: Metallic
    float4 prm : SV_Target3;

	// --- Motion Vector ---
	// XY: Motion vector direction
    float2 velocity : SV_Target4;

	// ???
    float2 o5 : SV_Target5;
};

SurfaceData InitSurfaceData()
{
	SurfaceData result = {
		{0.0, 0.0, 0.0, 0.0},
		{0.0, 0.0, 0.0},
		{0.0, 0.0, 0.0, 0.0},
		{0.0, 0.0, 0.0, 0.0},
		{0.0, 0.0},
		{0.0, 0.0},
	};

	return result;
}

#endif