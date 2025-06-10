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
	// W: ???
    float4 normal : SV_Target1;

	// --- Emission --
	// XYZ: RGB Emission color
	// W: ???
    float4 emission : SV_Target2;

	// --- Physical rendering parameters ---
	// X: Specularity
	// Y: Roughness
	// Z: Metallic
	// W: Ambient Occlusion
    float4 prm : SV_Target3;

	// ???
    float4 o4 : SV_Target4;

	// ???
    float4 o5 : SV_Target5;
};

#endif