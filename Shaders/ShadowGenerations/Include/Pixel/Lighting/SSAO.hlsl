#ifndef SSAO_LIGHTING_INCLUDED
#define SSAO_LIGHTING_INCLUDED

#include "../../Common.hlsl"

#if !defined(enable_noisy_upsample) && !defined(no_enable_noisy_upsample)
	DefineFeature(enable_noisy_upsample);
#endif

#if !defined(enable_ssao) && !defined(no_enable_ssao)
	DefineFeature(enable_ssao);
#endif

#include "../../Texture.hlsl"
#include "../Deferred.hlsl"
#include "Struct.hlsl"

Texture2D<float4> WithSampler(s_SSAO);
Texture2D<float4> WithSampler(s_Hiz);

float4 u_dither_offsets[36];
int4 shadow_dither[16];

float4 ComputeUpsampledSSAO(LightingParameters parameters, float shadow)
{
	float t = SampleTexture(s_SSAO, parameters.screen_position).w;
	t += u_ssao_param.x;
	t = saturate(t);
	t = min(shadow, t);

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
	float4 result = 0.0;

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

	return result;
}

float4 ComputeSSAO(LightingParameters parameters, float shadow)
{
	float4 result = 0.0;

	#ifndef enable_ssao
		return float4(1.0, 1.0, 1.0, shadow);
	#endif

	#ifndef enable_noisy_upsample
		result = SampleTexture(s_SSAO, parameters.screen_position);
	#else
		result = ComputeUpsampledSSAO(parameters, shadow);
	#endif

	result.w = min(result.w, shadow);

	return result;
}

#endif