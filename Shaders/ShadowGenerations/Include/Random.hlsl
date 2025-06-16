#ifndef RANDOM_INCLUDED
#define RANDOM_INCLUDED

float Random1From3Simple(float3 seed)
{
	return (43758.5469 * sin(dot(seed, float3(12.9898005,78.2330017,56.7869987))));
}

float Random1From3(float3 seed)
{
	float3 seed_floor = floor(seed);
	float3 seed_frac = frac(seed);

	float3 smoothed = (seed_frac * -2.0 + 3.0) * pow(seed_frac, 2);

	float4 lower = float4(
		Random1From3Simple(seed_floor + float3(0,0,0)),
		Random1From3Simple(seed_floor + float3(1,0,0)),
		Random1From3Simple(seed_floor + float3(0,1,0)),
		Random1From3Simple(seed_floor + float3(1,0,0))
	);

	float4 upper = float4(
		Random1From3Simple(seed_floor + float3(0,0,1)),
		Random1From3Simple(seed_floor + float3(1,0,1)),
		Random1From3Simple(seed_floor + float3(0,1,1)),
		Random1From3Simple(seed_floor + float3(1,1,1))
	);

	float4 result4 = lerp(lower, upper, smoothed.z);
	float2 result2 = lerp(result4.xy, result4.zw, smoothed.y);
	return lerp(result2.x, result2.y, smoothed.x);
}

#endif