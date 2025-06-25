#ifndef LIGHT_LIGHTING_INCLUDED
#define LIGHT_LIGHTING_INCLUDED

#include "../../Math.hlsl"

float3 FresnelSchlick(float3 fresnel_reflectance, float cos_theta)
{
    float p = pow(1.0 - cos_theta, 5.0);
	float f90 = saturate(dot(fresnel_reflectance, 16.5));

	return lerp(fresnel_reflectance, f90, p );
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

#endif