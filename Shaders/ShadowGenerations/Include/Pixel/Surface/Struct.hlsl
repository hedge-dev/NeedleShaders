#ifndef STRUCT_SURFACE_INCLUDED
#define STRUCT_SURFACE_INCLUDED

// PBR base data, also directly used for deferred rendering output

struct SurfaceData
{
	// --- Albedo ---
	// XYZ: RGB Diffuse color
	// W: ???
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