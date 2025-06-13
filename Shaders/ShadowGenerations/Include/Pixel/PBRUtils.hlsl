#ifndef PBR_UTILS_PIXEL_INCLUDED
#define PBR_UTILS_PIXEL_INCLUDED

struct PBRParameters
{
	float specular;
	float roughness;
	float metallic;
	float ambient_occlusion;
	float3 specular_color;
	float metallic_inv;
};

PBRParameters ProcessPRM(float4 prm, float specular_modifier, float3 albedo)
{
	PBRParameters result;

	result.specular = prm.x * specular_modifier;
	result.roughness = max(0.01, 1.0 - prm.y);
	result.metallic = prm.z;
	result.ambient_occlusion = prm.w;

	result.specular_color = result.metallic * (albedo - result.specular) + result.specular;
	result.metallic_inv = 1.0 - result.metallic;

	return result;
}

#define ProcessPRMTexture(prm, albedo) ProcessPRM(prm, 0.25, albedo)

#endif