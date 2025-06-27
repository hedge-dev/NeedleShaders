#ifndef STRUCT_SURFACE_INCLUDED
#define STRUCT_SURFACE_INCLUDED

//////////////////////////////////////////////////
// Surface parameters (input)

struct SurfaceParameters
{
	float3 albedo;
	float3 emission;

	float specular;
	float roughness;
	float metallic;
	float ambient_occlusion;

	float3 fresnel_reflectance;

	float3 screen_position;
	float2 screen_tile;
	float3 previous_position;
	float4 world_position;

	float3 normal;
	float3 debug_normal;

	float2 gi_uv;

	uint shader_model;
};

SurfaceParameters InitSurfaceParameters()
{
	SurfaceParameters result = {
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

		{0.0, 0.0},

		0
	};

	return result;
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
	// W: GI Shadow
    float4 emission : SV_Target2;

	// --- Physical rendering parameters ---
	// X: Specularity
	// Y: Roughness
	// Z: Ambient Occlusion
	// W: Metallic
    float4 prm : SV_Target3;

	// --- Motion Vector ---
	// XY: Motion vector direction
    float2 motion_vector : SV_Target4;

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