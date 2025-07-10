#ifndef PBR_UTILS_PIXEL_INCLUDED
#define PBR_UTILS_PIXEL_INCLUDED

#include "Surface/Struct.hlsl"

void ProcessPRM(inout SurfaceParameters parameters, float4 prm, float specular_modifier)
{
	parameters.specular = prm.x * specular_modifier;
	parameters.roughness = max(0.01, 1.0 - prm.y);
	parameters.metallic = prm.z;
	parameters.cavity = prm.w;

	parameters.fresnel_reflectance = lerp(
		parameters.specular,
		parameters.albedo,
		parameters.metallic
	);
}

#define ProcessPRMTexture(parameters, prm) ProcessPRM(parameters, prm, 0.25)

#endif