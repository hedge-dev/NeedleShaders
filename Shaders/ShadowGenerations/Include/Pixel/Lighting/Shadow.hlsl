#ifndef SHADOW_LIGHTING_INCLUDED
#define SHADOW_LIGHTING_INCLUDED

#include "../../Common.hlsl"
#if !defined(shadow_as_pcf) && !defined(no_shadow_as_pcf)
	DefineFeature(shadow_as_pcf);
#endif

#include "../../ConstantBuffer/World.hlsl"
#include "../../Texture.hlsl"
#include "../../Math.hlsl"

#include "../ShadowCascade.hlsl"

#include "Struct.hlsl"

Texture2DArray<float4> WithSampler(s_ShadowMap);
TextureCubeArray<float4> WithSamplerComparison(s_LocalShadowMap);
Texture3D<float4> WithSampler(s_VolShadow);

float3 ComputeShadowParallaxIntersection(int level, float3 shadow_view_pos)
{
	if (shadow_parallax_correct_param[0].w > 0)
	{
		float sum_shadow = 0.0;
		float layers = 0.0;
		float3 parallax_pos = shadow_view_pos;

		for(int i = 0; i < 16; i++)
		{
			float3 shadow_cascade_pos = parallax_pos * shadow_cascade_scale[level].xyz + shadow_cascade_offset[level].xyz;
			float shadow = SampleTextureLevel(s_ShadowMap, float3(shadow_cascade_pos.xy, level), 0).x;

			if(shadow_cascade_pos.z < shadow)
			{
				sum_shadow += abs(shadow_cascade_pos.z - shadow);
				layers++;
			}

			parallax_pos += shadow_parallax_correct_param[level].xyz;
		}

		if(layers > 0)
		{
			shadow_view_pos += (sum_shadow / layers) * shadow_parallax_correct_param[level].xyz;
		}
	}

	return shadow_view_pos * shadow_cascade_scale[level].xyz + shadow_cascade_offset[level].xyz;
}

float SampleShadowVSM(float3 view_pos, float3 shadow_sample_pos, int level, float offset)
{
	float2 pos_ddx = ddx_coarse(view_pos.xy);
	float2 pos_ddy = ddy_coarse(view_pos.xy);

	pos_ddx *= shadow_cascade_scale[level].xy;
	pos_ddy *= shadow_cascade_scale[level].xy;

	float2 shadow = SampleTextureGrad(s_ShadowMap, float3(shadow_sample_pos.xy, level), pos_ddx, pos_ddy).xy;

	float minimum = shadow.x >= shadow_sample_pos.z ? 1.0 : 0.0;
	float t1 = max(0.0005, shadow.y - pow(shadow.x, 2));
	float t2 = t1 + pow(shadow_sample_pos.z - shadow.x, 2);
	return max(InvLerp(offset, 1.0, t1 / t2), minimum);
}

float SampleShadowPoint(float3 shadow_sample_pos, int level, float offset)
{
	float transition_scale = dot(shadow_cascade_transition_scale, shadow_cascade_levels[level]);
	float shadow = SampleTextureLevel(s_ShadowMap, float3(shadow_sample_pos.xy, level), 0).x;
	return saturate((shadow - shadow_sample_pos.z) * transition_scale + offset);
}

float SampleShadowPCF(float3 shadow_sample_pos, int level, float offset)
{
	float transition_scale = dot(shadow_cascade_transition_scale, shadow_cascade_levels[level]);

	float2 scaled = shadow_sample_pos.xy * shadow_map_size.xy - 0.5;
	float2 fraction = frac(scaled);
	float3 sample_pos = float3((floor(scaled) + 0.5 ) * shadow_map_size.zw, level);

	#define GatherShadow(ox, oy) saturate((TextureGather(s_ShadowMap, sample_pos, int2(ox, oy)) - shadow_sample_pos.z) * transition_scale + offset);

	float4 nn = GatherShadow(-1, -1);
	float4 pn = GatherShadow( 1, -1);
	float4 np = GatherShadow(-1,  1);
	float4 pp = GatherShadow( 1,  1);

	#undef GatherShadow

	float4x4 gather_matrix = float4x4(
		pp.xy, np.xy,
		pp.wz, np.wz,
		pn.xy, nn.xy,
		pn.wz, nn.wz
	);

	float4 horizontal = float4(1, fraction.x, 1 - fraction.x, 1);
	float4 vertical = float4(fraction.y, 1, 1, 1 - fraction.y);

	return min(1, dot(mul(gather_matrix, horizontal), vertical) / 9.0);
}

float SampleShadowPCSS(float2 screen_position, float3 shadow_sample_pos, int level)
{
	uint width, height, element_count, sample_count;
	s_ShadowMap.GetDimensions(0, width, height, element_count, sample_count);

	uint2 res = uint2(width, height);
	float level_fac = 16.0 / (level * 2.0 + 1.0);
	float2 level_res = level_fac / float2(width, height);

	float t = dot(u_screen_info.xy * screen_position, float2(0.0671105608,0.00538371503));
	t = frac(frac(t) * 52.9829178);

	float shadow_sum = 0.0;
	int shadow_count = 0.0;

	for(int i = 0; i < 8; i++)
	{
		float2 cos_sin;
		sincos(i * 2.4 + t, cos_sin.y, cos_sin.x);
		cos_sin *= sqrt(0.5 + i) * 0.353553 * level_res;

		uint2 load_pos = (uint2)((cos_sin + shadow_sample_pos.xy) * res);
		float shadow = s_ShadowMap.Load(uint4(load_pos, 0, level)).x;

		if(shadow < shadow_sample_pos.z)
		{
			shadow_count++;
			shadow_sum += 1.0 / shadow;
		}
	}

	if (shadow_count == 0)
	{
		return 1.0;
	}

	float2 t2 = 0.85 * level_res * min(1, 25 * abs((1.0 / shadow_sample_pos.z) - (shadow_sum / shadow_count)));

	float result = 0.0;

	for(int j = 0; j < 16; j++)
	{
		float2 cos_sin;
		sincos(j * 2.4 + t, cos_sin.y, cos_sin.x);
		cos_sin *= 0.25 * sqrt(0.5 + j);

		float2 sample_pos = cos_sin * t2 + shadow_sample_pos.xy;
		float comp = shadow_sample_pos.z - max(1, max(abs(cos_sin.x), abs(cos_sin.y)) * level_fac) * 0.000005;
		result += s_ShadowMap.SampleCmpLevelZero(SamplerName(s_LocalShadowMap), float3(sample_pos, level), comp).x;
	}

	return result / 16.0;
}

float SampleShadowESM(float3 shadow_sample_pos, int level, float offset)
{
	float result = SampleTextureLevel(s_ShadowMap, float3(shadow_sample_pos.xy, level), 0).x;

	if(result >= shadow_sample_pos.z)
	{
		return 1.0;
	}

	return min(1, exp((result - shadow_sample_pos.z) * offset));
}

float SampleShadow(float2 screen_position, float3 view_pos, float3 shadow_sample_pos, int level)
{
	if(shadow_sample_pos.x < 0.0 || shadow_sample_pos.x >= 1.0
		|| shadow_sample_pos.y < 0.0 || shadow_sample_pos.y >= 1.0
		|| shadow_sample_pos.z < 0.0 || shadow_sample_pos.z >= 1.0)
	{
		return 1.0;
	}

	ShadowMapData data = GetShadowMapData();

	int filter_mode = ShadowFilterMode_PCF;
	#ifndef shadow_as_pcf
		filter_mode = data.shadow_filter_mode;
	#endif

	switch(filter_mode)
	{
		case ShadowFilterMode_Point:
			return SampleShadowPoint(shadow_sample_pos, level, data.shadow_offset);
		case ShadowFilterMode_PCF:
			return SampleShadowPCF(shadow_sample_pos, level, data.shadow_offset);
		case ShadowFilterMode_PCSS:
			return SampleShadowPCSS(screen_position, shadow_sample_pos, level);
		case ShadowFilterMode_ESM:
			return SampleShadowESM(shadow_sample_pos, level, data.shadow_offset);
		default:
			return SampleShadowVSM(view_pos, shadow_sample_pos, level, data.shadow_offset);
	}
}

float ComputeShadowValue(float3 shadow_position, float shadow_depth, float2 screen_position)
{
	ShadowMapData data = GetShadowMapData();

	int level = GetShadowCascadeLevel(shadow_depth);

	if(level >= data.cascade_count)
	{
		return data.shadow_base_factor;
	}

	float3 sample_position = ComputeShadowParallaxIntersection(level, shadow_position);
	float shadow = SampleShadow(screen_position, shadow_position, sample_position, level);

	float level_step = 1.0 - ComputeShadowCascadeLevelStep(shadow_depth, level, data.level_step_scale);
	int next_level = min(level + 1, data.cascade_count - 1);
	float next_shadow = 1.0;

	if(level != next_level && level_step <= 0.99999 && level_step > 0)
	{
		float3 next_sample_position = ComputeShadowParallaxIntersection(next_level, shadow_position);
		next_shadow = SampleShadow(screen_position, shadow_position, next_sample_position, level);
	}

	float result = lerp(shadow, next_shadow, level_step);

	float result_factor = ComputeShadowCascadeLevelStep(shadow_depth, data.cascade_count - 1, data.level_end_scale);
	result = lerp(
		data.shadow_base_factor,
		result,
		result_factor
	);

	result = lerp(
		result,
		data.shadow_base_factor,
		data.shadow_base_factor_2
	);

	return result;
}

//////////////////////////////////////////////////

bool SampleVolShadowValue(float3 world_position, int level, out float value)
{
	value = 1.0;

	if (level >= 4)
	{
		return false;
	}

	float3 offset = world_position - u_vol_shadow_param[level].xyz;
	offset *= u_vol_shadow_param[level].w;

	float3 oabs = abs(offset);
	if(oabs.x >= 0.48 || oabs.y >= 0.48 || oabs.z >= 0.48)
	{
		return false;
	}

	float3 sample_pos = float3(
		offset.x + 0.5,
		offset.y + 0.5,
		(offset.z + 0.5 + level) * 0.25
	);

	value = SampleTextureLevel(s_VolShadow, sample_pos, 0).x;
	return true;
}

void ComputeVolShadowValue(float3 world_position, inout float value)
{
	if(!enable_vol_shadow)
	{
		return;
	}

	float camera_distance = length(world_position - u_cameraPosition.xyz);
	int shadow_level = CountTrue(u_vol_shadow_param[4] < camera_distance);

	float result;
	SampleVolShadowValue(world_position, shadow_level, result);

	int next_shadow_level = shadow_level + 1;
	float next_vol_shadow;
	if(SampleVolShadowValue(world_position, shadow_level, next_vol_shadow))
	{
		float limit = dot(u_vol_shadow_param[4], shadow_cascade_levels[shadow_level]);
		result = lerp(result, next_vol_shadow, smoothstep(limit * 0.5, limit, camera_distance));
	}

	if (next_shadow_level >= 4)
	{
		float limit = dot(u_vol_shadow_param[4], shadow_cascade_levels[3]);
		result = lerp(result, 1.0, smoothstep(limit * 0.8, limit, camera_distance));
	}

	value = min(value, result);
}

#endif