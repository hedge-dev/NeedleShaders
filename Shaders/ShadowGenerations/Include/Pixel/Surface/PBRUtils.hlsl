#ifndef PBR_UTILS_SURFACE_INCLUDED
#define PBR_UTILS_SURFACE_INCLUDED

#include "Struct.hlsl"

void ApplyPRM(inout SurfaceParameters parameters, float4 prm)
{
	parameters.specular = prm.x;
	parameters.roughness = max(0.01, 1.0 - prm.y);
	parameters.metallic = prm.z;
	parameters.cavity = prm.w;

	parameters.fresnel_reflectance = lerp(
		parameters.specular,
		parameters.albedo,
		parameters.metallic
	);
}

#define ApplyPRMTexture(parameters, prm) ApplyPRM(parameters, prm * float4(0.25, 1.0, 1.0, 1.0))
#define ApplyPBRFactor(parameters, prm) ApplyPRM(parameters, float4(prm.xyz, 1.0))

#endif