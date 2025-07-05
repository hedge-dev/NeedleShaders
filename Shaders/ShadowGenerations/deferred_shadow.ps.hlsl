#include "Include/Common.hlsl"

DefineFeature(shadow_as_pcf);
DefineFeature(enable_noisy_upsample);
DefineFeature(enable_ssao);

#include "Include/ConstantBuffer/World.hlsl"
#include "Include/ConstantBuffer/SHLightFieldProbes.hlsl"

#include "Include/Pixel/Lighting/Struct.hlsl"
#include "Include/Pixel/Deferred.hlsl"
#include "Include/Pixel/ShadowCascade.hlsl"

#include "Include/IOStructs.hlsl"
#include "Include/Texture.hlsl"

Texture2DArray<float4> WithSampler(s_ShadowMap);
SamplerComparisonState SamplerName(s_LocalShadowMap);
Texture3D<float4> WithSampler(s_VolShadow);
Texture2D<float4> WithSampler(s_SSAO);
Texture2D<float4> WithSampler(s_Hiz);

float4 u_dither_offsets[36];
int4 shadow_dither[16];

float3 ComputeParallaxIntersection(int level, float3 shadow_view_pos)
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

float SampleShadowDefault(float3 view_pos, float3 shadow_sample_pos, int level)
{
	float2 pos_ddx = ddx_coarse(view_pos.xy);
	float2 pos_ddy = ddy_coarse(view_pos.xy);

	pos_ddx *= shadow_cascade_scale[level].xy;
	pos_ddy *= shadow_cascade_scale[level].xy;

	float2 shadow = SampleTextureGrad(s_ShadowMap, float3(shadow_sample_pos.xy, level), pos_ddx, pos_ddy).xy;

	float t1 = max(0.0005, shadow.y - pow(shadow.x, 2));
	float t2 = shadow.y + pow(shadow_sample_pos.z - shadow.x, 2);
	float minimum = shadow.x >= shadow_sample_pos.z ? 1.0 : 0.0;

	return max(InvLerp(shadow_map_parameter[0].x, 1.0, t1 / t2), minimum);
}

float SampleShadow0(float3 shadow_sample_pos, int level)
{
	float transition_scale = dot(shadow_cascade_transition_scale, shadow_cascade_levels[level]);
	float shadow = SampleTextureLevel(s_ShadowMap, float3(shadow_sample_pos.xy, level), 0).x;
	return saturate((shadow - shadow_sample_pos.z) * transition_scale + shadow_map_parameter[0].x);
}

float SampleShadow1(float3 shadow_sample_pos, int level)
{
	float transition_scale = dot(shadow_cascade_transition_scale, shadow_cascade_levels[level]);

	float2 scaled = shadow_sample_pos.xy * shadow_map_size.xy - 0.5;
	float2 fraction = frac(scaled);
	float3 sample_pos = float3((floor(scaled) + 0.5 ) * shadow_map_size.zw, level);

	#define GatherShadow(ox, oy) saturate((TextureGather(s_ShadowMap, sample_pos, int2(ox, oy)) - shadow_sample_pos.z) * transition_scale + shadow_map_parameter[0].x);

	float4 nn = GatherShadow(-1, -1);
	float4 np = GatherShadow( 1, -1);
	float4 pn = GatherShadow(-1,  1);
	float4 pp = GatherShadow( 1,  1);

	#undef GatherShadow

	float4 t = float4(
		np.w + nn.z + np.z * fraction.x + nn.w * (1 - fraction.x),
		np.x + nn.y + np.y * fraction.x + nn.x * (1 - fraction.x),
		pp.w + pn.z + pp.z * fraction.x + pn.w * (1 - fraction.x),
		pp.x + pn.y + pp.y * fraction.x + pn.x * (1 - fraction.x)
	);

	float4 t2 = float4(
		fraction.y,
		1 - fraction.y,
		1,
		1
	);

	return min(1, dot(t, t2) / 9.0);
}

float SampleShadow2(float2 screen_position, float3 shadow_sample_pos, int level)
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

float SampleShadow3(float3 shadow_sample_pos, int level)
{
	float result = SampleTextureLevel(s_ShadowMap, float3(shadow_sample_pos.xy, level), 0).x;

	if(result >= shadow_sample_pos.z)
	{
		return 1.0;
	}

	return min(1, exp((result - shadow_sample_pos.z) * shadow_map_parameter[0].x));
}

float SampleShadowModes(float2 screen_position, float3 view_pos, float3 shadow_sample_pos, int level)
{
	if(shadow_sample_pos.x < 0.0 || shadow_sample_pos.x >= 1.0
		|| shadow_sample_pos.y < 0.0 || shadow_sample_pos.y >= 1.0
		|| shadow_sample_pos.z < 0.0 || shadow_sample_pos.z >= 1.0)
	{
		return 1.0;
	}

	int shadow_mode = 1;
	#ifndef shadow_as_pcf
		shadow_mode = GetShadowCascadeData().some_mode;
	#endif

	switch(shadow_mode)
	{
		case 0:
			return SampleShadow0(shadow_sample_pos, level);
		case 1:
			return SampleShadow1(shadow_sample_pos, level);
		case 2:
			return SampleShadow2(screen_position, shadow_sample_pos, level);
		case 3:
			return SampleShadow3(shadow_sample_pos, level);
		default:
			return SampleShadowDefault(view_pos, shadow_sample_pos, level);
	}
}

float Something(float4 position, float2 screen_position)
{
	ShadowCascadeData data = GetShadowCascadeData();

	int level = GetShadowCascadeLevel(position);

	if(level >= data.cascade_count)
	{
		return data.shadow_base_factor;
	}

	float3 shadow_view_position = mul(position, shadow_view_matrix).xyz;
	float3 shadow_sample_position = ComputeParallaxIntersection(level, shadow_view_position);
	float shadow = SampleShadowModes(screen_position, shadow_view_position, shadow_sample_position, level);

	float level_step = 1.0 - ComputeShadowCascadeLevelStep(
		position,
		level,
		data.level_step_scale
	);

	int next_level = min(level + 1, data.cascade_count - 1);
	float next_shadow = 1.0;

	if(level != next_level && level_step <= 0.99999 && level_step > 0)
	{
		float3 next_shadow_position = ComputeParallaxIntersection(next_level, shadow_view_position);
		next_shadow = SampleShadowModes(screen_position, shadow_view_position, shadow_sample_position, level);
	}

	float result = lerp(shadow, next_shadow, level_step);

	float result_factor = ComputeShadowCascadeLevelStep(position, data.cascade_count - 1, data.level_end_scale);
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

bool SampleVolShadow(float3 position, int level, out float value)
{
	value = 1.0;

	if (level >= 4)
	{
		return false;
	}

	float3 offset = position - u_vol_shadow_param[level].xyz;
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

void ComputeVolShadow(float3 position, inout float value)
{
	if(!enable_ibl_plus_directional_specular)
	{
		return;
	}

	float camera_distance = length(position - u_cameraPosition.xyz);
	int shadow_level = CountTrue(u_vol_shadow_param[4] < camera_distance);

	float result;
	SampleVolShadow(position, shadow_level, result);

	int next_shadow_level = shadow_level + 1;
	float next_vol_shadow;
	if(SampleVolShadow(position, shadow_level, next_vol_shadow))
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

float ComputeShadow(LightingParameters parameters)
{
	float result = 1.0;

	if(parameters.shading_model.type == ShadingModelType_Clear)
	{
		return result;
	}

	if(parameters.occlusion_mode == OcclusionMode_AOGI && shlightfield_param.x > 0)
	{
		result = parameters.occlusion_value;
	}

	if(parameters.occlusion_sign <= 0 || result <= 0.0)
	{
		return result;
	}

	float factor = Something(parameters.world_position, parameters.screen_position);
	ComputeVolShadow(parameters.world_position.xyz, factor);

	result *= factor;
	return result;
}

float4 ComputeSSAO(LightingParameters parameters, float shadow)
{
	#ifndef enable_ssao
		return float4(1.0, 1.0, 1.0, shadow);
	#endif

	float4 result = 0.0;

	#ifndef enable_noisy_upsample
		result = SampleTexture(s_SSAO, parameters.screen_position);
	#else
		float t = SampleTexture(s_SSAO, parameters.screen_position).w;
		t += u_ssao_param.x;
		t = saturate(t);
		t = min(shadow, t); // r0.z

		uint t2 = parameters.pixel_position.y % 3;
		t2 *= -3;
		t2 -= parameters.pixel_position.x % 3;
		t2 <<= 2;
		t2 += 32;

		uint width, height, level_count;
		s_DepthBuffer.GetDimensions(0, width, height, level_count);

		uint2 res = uint2(width, height);
		float2 half_res = res * 0.5;
		float2 t3 = (parameters.pixel_position * half_res.y) / res.y;

		float sum = 0.0;

		for(int i = 0; i < 4; i++)
		{
			float3 dither_offset = u_dither_offsets[t2 + i].xyz;
			float2 sample_pos = min((dither_offset.xy + t3) / half_res, 0.99 / u_viewport_info.zw);
			float4 ssao = SampleTexture(s_SSAO, sample_pos);

			float hiz = SampleTextureLevel(s_Hiz, u_hiz_param.xy * sample_pos, 0).y;
			hiz = parameters.depth - hiz;
			hiz = 0.0001 + abs(hiz);
			hiz = dither_offset.z / hiz;

			float3 normal = SampleTexture(s_GBuffer1, sample_pos).xyz * 2 - 1;
			float fac = hiz * min(1, pow(dot(parameters.world_normal, normal), 4));

			sum += fac;
			result += ssao * fac;
		}

		result /= sum;
	#endif

	result.w = min(result.w, shadow);
	return result;
}

float4 main(BlitIn input) : SV_Target0
{
	uint2 pixel_position = (uint2)input.pixel_position.xy;
	DeferredData deferred_data = LoadDeferredData(pixel_position);

	LightingParameters parameters = InitLightingParameters();
	TransferSurfaceData(deferred_data.surface, parameters);
	TransferPixelData(pixel_position, input.screen_position.xy, deferred_data.depth, parameters);

	float shadow = ComputeShadow(parameters);
	float4 result = ComputeSSAO(parameters, shadow);

	return result;
}