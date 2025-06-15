#ifndef PBR_UTILS_PIXEL_INCLUDED
#define PBR_UTILS_PIXEL_INCLUDED

struct PBRParameters
{
	float specular;
	float roughness;
	float metallic;
	float ambient_occlusion;
};

PBRParameters ProcessPRM(float4 prm, float specular_modifier, float3 albedo)
{
	PBRParameters result;

	result.specular = prm.x * specular_modifier;
	result.roughness = max(0.01, 1.0 - prm.y);
	result.metallic = prm.z;
	result.ambient_occlusion = prm.w;

	return result;
}

#define ProcessPRMTexture(prm, albedo) ProcessPRM(prm, 0.25, albedo)

#endif