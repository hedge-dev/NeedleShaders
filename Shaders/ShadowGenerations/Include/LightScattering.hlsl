#ifndef RAY_MIE_SCATTERING_INCLUDED
#define RAY_MIE_SCATTERING_INCLUDED

#include "ConstantBuffer/World.hlsl"
#include "Math.hlsl"

struct LightScatteringColors
{
	float3 factor;
	float3 base;
};

LightScatteringColors ComputeLightScatteringColors(float view_distance, float3 view_dir)
{
	//////////////////////////////////////////////////
	// Precomputing rayleigh and mie values

	float3 ray = g_LightScattering_Ray_Mie_Ray2_Mie2.xyz;
	float3 ray2 = ray * 3.0 / (Pi * 16.0);
	float mie = g_LightScattering_Ray_Mie_Ray2_Mie2.w;
	float mie2 = mie / (Pi * 4.0);


	LightScatteringColors result;

	//////////////////////////////////////////////////
	// Factor color

	view_distance -= g_LightScatteringFarNearScale.y;
	view_distance *= g_LightScatteringFarNearScale.x;
	view_distance = saturate(view_distance);
	view_distance *= g_LightScatteringFarNearScale.z;

	result.factor = exp((ray + mie) * -view_distance);

	//////////////////////////////////////////////////
	// Base color

	float light_dot = dot(u_lightDirection.xyz, view_dir);

	float t1 = light_dot;
	t1 *= g_LightScattering_ConstG_FogDensity.z;
	t1 += g_LightScattering_ConstG_FogDensity.y;
	t1 = exp2(1.5 * log2(0.000001 + abs(t1)));
	t1 = g_LightScattering_ConstG_FogDensity.x / t1;

	float3 t2 = pow(light_dot, 2) + 1.0;
	t2 *= ray2;
	t2 += t1 * mie2;
	t2 /= ray + mie;

	result.base = g_LightScatteringColor.xyz;
	result.base *= g_LightScatteringFarNearScale.w;
	result.base *= 1.0 - result.factor;
	result.base *= t2;


	return result;
}

#endif