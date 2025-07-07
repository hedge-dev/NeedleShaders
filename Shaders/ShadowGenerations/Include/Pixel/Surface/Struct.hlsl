#ifndef STRUCT_SURFACE_INCLUDED
#define STRUCT_SURFACE_INCLUDED

#include "../../ConstantBuffer/World.hlsl"
#include "../../IOStructs.hlsl"

#include "../ShadingModel.hlsl"
#include "../TypedOcclusion.hlsl"

//////////////////////////////////////////////////
// Surface parameters (input)

struct SurfaceParameters
{
	ShadingModel shading_model;

	float3 albedo;
	float transparency;
	float3 emission;

	float specular;
	float roughness;
	float metallic;
	float cavity;

	float3 fresnel_reflectance;

	int2 pixel_position;
	float3 previous_position;
	float4 world_position;

	float3 normal;
	float3 debug_normal;

	float2 velocity;

	float2 gi_uv;
	float2 unk_o5;

	TypedOcclusion typed_occlusion;
};

SurfaceParameters InitSurfaceParameters()
{
	SurfaceParameters result = {
		{ 0, false, 0 },

		{0.0, 0.0, 0.0},
		1.0,
		{0.0, 0.0, 0.0},

		0.0, 0.0, 0.0, 0.0,

		{0.0, 0.0, 0.0},

		{0, 0},
		{0.0, 0.0, 0.0},
		{0.0, 0.0, 0.0, 0.0},

		{0.0, 0.0, 0.0},
		{0.0, 0.0, 0.0},

		{0.0, 0.0},

		{0.0, 0.0},
		{0.0, 0.0},

		{ 0.0, 0, false }
	};

	return result;
}

void SetupSurfaceParamFromInput(PixelInput input, inout SurfaceParameters parameters)
{
    parameters.pixel_position = (int2)input.position.xy;

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

SurfaceData SurfaceParamToData(SurfaceParameters parameters)
{
	SurfaceData result;

    result.albedo.xyz = parameters.albedo;
    result.prm = float4(
        parameters.specular,
        parameters.roughness,
        parameters.cavity,
        parameters.metallic
    );

    result.emission.xyz = parameters.emission;
    result.emission.w = EncodTypedOcclusion(parameters.typed_occlusion);

    result.normal = parameters.normal * 0.5 + 0.5;
    result.velocity = parameters.velocity;

    result.albedo.w = (0.5 + ShadingModelToFlags(parameters.shading_model)) / 255.0;

    result.o5.xy = parameters.unk_o5;

	return result;
}

#endif