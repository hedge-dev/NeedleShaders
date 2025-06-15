#ifndef STRUCT_SURFACE_INCLUDED
#define STRUCT_SURFACE_INCLUDED

// TODO figure out what these do
// Notes:
// 2 = Approximate Environment BRDF
static const uint ShadingMode2 = 2;

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
	float3 previous_position;
	float3 world_position;

	float3 normal;
	float3 debug_normal;

	float2 gi_uv;

	uint deferred_flags;
};

SurfaceParameters InitSurfaceParameters()
{
	SurfaceParameters result = {
		{0.0, 0.0, 0.0},
		{0.0, 0.0, 0.0},

		0.0, 0.0, 0.0, 0.0,

		{0.0, 0.0, 0.0},

		{0.0, 0.0, 0.0},
		{0.0, 0.0, 0.0},
		{0.0, 0.0, 0.0},

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

#endif