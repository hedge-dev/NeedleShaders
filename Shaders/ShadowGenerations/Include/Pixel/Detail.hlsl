#ifndef DETAIL_PIXEL_INCLUDED
#define DETAIL_PIXEL_INCLUDED

#include "../ConstantBuffer/World.hlsl"
#include "../Math.hlsl"
#include "Normals.hlsl"

float ComputeDetailDistance(float3 world_position, float distance_center, float distance_range)
{
	float dist = distance(u_cameraPosition.xyz, world_position);
	float dist_min = distance_center - distance_range;
	float dist_max = distance_center + distance_range;

	return saturate(max(0, dist - dist_min) / max(0, dist_max - dist_min));
}

float ComputeDetailDistance(float3 world_position)
{
	return ComputeDetailDistance(world_position, u_detail_param.x, u_detail_param.y);
}

float BlendDetail(float main, float detail)
{
	return main < 0.5
		? detail * main * 2
		: 1 - (1 - detail) * ((1 - main) * 2);
}

float BlendDetail(float main, float detail, float detail_distance)
{
	return lerp(
		BlendDetail(main, detail),
		main,
		detail_distance
	);
}

float3 BlendDetail(float3 main, float3 detail)
{
	return main < 0.5
		? detail * main * 2
		: 1 - (1 - detail) * ((1 - main) * 2);
}

float3 BlendDetail(float3 main, float3 detail, float detail_distance)
{
	return lerp(
		BlendDetail(main, detail),
		main,
		detail_distance
	);
}

float3 BlendNormalMapDetail(float2 main, float2 detail, float detail_distance, NormalDirections directions)
{
	float3 denormal = DenormalizeNormalMap(main);
	float3 denormal_detail = DenormalizeNormalMap(detail);

	float3 denormal_blended = lerp(
		BlendNormals(denormal, denormal_detail),
		denormal,
		detail_distance
	);

	return TransformNormal(denormal_blended, directions);
}

#endif