#ifndef FOG_LIGHTING_INCLUDED
#define FOG_LIGHTING_INCLUDED

#include "../../ConstantBuffer/World.hlsl"
#include "../../Texture.hlsl"
#include "IBL.hlsl"
#include "Struct.hlsl"

float3 ComputeFogColor(float3 view_direction)
{
	float3 fog_color = u_fog_param_0.xyz * u_fog_param_0.w;

	if (u_fog_param_2.x <= 0.001)
	{
		return fog_color;
	}

	float3 ibl_color = SampleTextureLevel(
		s_IBL,
		view_direction * float3(-1,-1,1),
		6 * sqrt(saturate(u_fog_param_2.y))
	).xyz;

	return lerp(
		fog_color,
		ibl_color,
		u_fog_param_2.x
	);
}

float ComputeFogFactor(float4 world_position)
{
	float4 view_depth = mul(world_position, view_matrix).z;

	float t1 = -u_fog_param_1.x - view_depth.z;
	float t2 =  u_fog_param_1.y - u_fog_param_1.x;

	float t3 = u_enable_fog_d
		? saturate(min(u_fog_param_1.z * t2, t1) / t2)
		: 0.0;

	float t4 =   saturate((    -view_depth.z - u_fog_param_3.z) / (u_fog_param_3.w - u_fog_param_3.z))
		* (1.0 - saturate(( world_position.y - u_fog_param_3.x) / (u_fog_param_3.y - u_fog_param_3.x)))
		* u_fog_param_1.w;

	return u_enable_fog_h
		? lerp(t3, 1.0, t4)
		: t3;
}

struct FogValues
{
	float fog_factor;
	float3 fog_color;
};

FogValues ComputeFogValues(LightingParameters parameters)
{
	FogValues result;

	result.fog_color = ComputeFogColor(parameters.view_direction);
	result.fog_factor = ComputeFogFactor(parameters.world_position);

	return result;
}

#endif