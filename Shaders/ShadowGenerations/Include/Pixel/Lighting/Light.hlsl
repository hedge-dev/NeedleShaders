#ifndef LIGHT_LIGHTING_INCLUDED
#define LIGHT_LIGHTING_INCLUDED

#include "../../Math.hlsl"
#include "Struct.hlsl"
#include "SubsurfaceScattering.hlsl"

//////////////////////////////////////////////////
// Basic Light Functions

float3 FresnelSchlick(float3 f0, float cos_theta)
{
    float p = pow(1.0 - cos_theta, 5.0);
	float f90 = saturate(dot(f0, 16.5));

	return lerp(f0, f90, p );
}

// GGX normal distribution function
float NdfGGX(float3 halfway, float3 normal, float roughness)
{
    float cos_halfway_normal = saturate(dot(halfway, normal));

    float alpha = roughness * roughness;

    float denom = (cos_halfway_normal * alpha - cos_halfway_normal) * cos_halfway_normal + 1;
    return alpha / (Pi * denom * denom);
}

float DGGXAniso(float3 halfway, float3 normal, float3 tangent, float3 binormal, float roughness, float2 anisotropy)
{
    anisotropy *= roughness * roughness;
    anisotropy = max(anisotropy, 0.000001);
    float a2 = anisotropy.x * anisotropy.y;

    float3 v = float3(
        dot(halfway, tangent) * anisotropy.x,
        dot(halfway, binormal) * anisotropy.y,
        dot(halfway, normal) * a2
    );

    float v2 = dot(v, v);
    float w2 = a2 / v2;

    return (a2 * w2 * w2) / Pi;
}

float VisSchlick(float roughness, float cos_view_normal, float cos_light_normal)
{
    float r = roughness + 1;
    float k = (r * r) / 8;
    float schlick_v = cos_view_normal * (1 - k) + k;
    float schlick_l = cos_light_normal * (1 - k) + k;
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

float3 DiffuseBDRF(LightingParameters parameters, float3 light_direction, float3 light_color, float shadow)
{
    float3 cos_light_normal = saturate(dot(light_direction, parameters.world_normal)) * shadow;

	if (parameters.shading_model.type == ShadingModelType_SSS)
	{
		SampleCDRF(parameters, light_direction, shadow, cos_light_normal);
	}

    float3 fresnel = ComputeFresnelColor(parameters, light_direction);

    return light_color
        * cos_light_normal
        * (1.0 - fresnel.x)
        * (1.0 - parameters.metallic);
}

float3 SpecularBRDF(LightingParameters parameters, float3 light_direction, float3 light_color, float shadow, bool enable_anisotropy)
{
    float3 halfway_direction = normalize(light_direction + parameters.view_direction);

	float cos_light_normal = saturate(dot(light_direction, parameters.world_normal));
    float cos_halfway_light = saturate(dot(halfway_direction, light_direction));

    float distribution;
    if(enable_anisotropy)
    {
        distribution = DGGXAniso(
            halfway_direction,
            parameters.world_normal,
            parameters.anisotropic_tangent,
            parameters.anisotropic_binormal,
            parameters.roughness,
            parameters.anisotropy
        );
    }
    else
    {
        distribution = NdfGGX(halfway_direction, parameters.world_normal, parameters.roughness);
    }

    float visibility = VisSchlick(parameters.roughness, parameters.cos_view_normal, cos_light_normal);
    float3 fresnel = FresnelSchlick(parameters.fresnel_reflectance, cos_halfway_light);

    return light_color * cos_light_normal * saturate(fresnel * distribution * visibility) * shadow;
}


#endif