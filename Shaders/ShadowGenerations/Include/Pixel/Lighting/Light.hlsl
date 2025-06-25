#ifndef LIGHT_LIGHTING_INCLUDED
#define LIGHT_LIGHTING_INCLUDED

#include "../../Math.hlsl"
#include "Struct.hlsl"


//////////////////////////////////////////////////
// Basic Light Functions

float3 FresnelSchlick(float3 f0, float cos_theta)
{
    float p = pow(1.0 - cos_theta, 5.0);
	float f90 = saturate(dot(f0, 16.5));

	return lerp(f0, f90, p );
}

// GGX normal distribution function
float NdfGGX(float cos_lh, float roughness)
{
    float alpha = roughness * roughness;
    float alphaSq = alpha * alpha;

    float denom = (cos_lh * alphaSq - cos_lh) * cos_lh + 1;
    return alphaSq / (Pi * denom * denom);
}

float VisSchlick(float roughness, float cos_lo, float cos_li)
{
    float r = roughness + 1;
    float k = (r * r) / 8;
    float schlick_v = cos_lo * (1 - k) + k;
    float schlick_l = cos_li * (1 - k) + k;
    return 0.25 / (schlick_v * schlick_l);
}


//////////////////////////////////////////////////
// Full color functions

float3 ComputeFresnelColor(LightingParameters parameters, float3 light_direction)
{
    float3 halfway_direction = normalize(light_direction + parameters.view_direction);
	float cos_halfway_light = saturate(dot(halfway_direction, light_direction));
	return FresnelSchlick(parameters.fresnel_reflectance, cos_halfway_light);
}

float3 SpecularBRDF(LightingParameters parameters, float3 light_direction, float3 light_color)
{
    float3 halfway_direction = normalize(light_direction + parameters.view_direction);

	float cos_light_normal = saturate(dot(light_direction, parameters.world_normal));
	float cos_halfway_normal = saturate(dot(halfway_direction, parameters.world_normal));
    float cos_halfway_light = saturate(dot(halfway_direction, light_direction));

    float3 fresnel = FresnelSchlick(parameters.fresnel_reflectance, cos_halfway_light);
    float distribution = NdfGGX(cos_halfway_normal, parameters.roughness);
    float visibility = VisSchlick(parameters.roughness, parameters.cos_view_normal, cos_light_normal);

    return saturate(fresnel * distribution * visibility);
}

#endif