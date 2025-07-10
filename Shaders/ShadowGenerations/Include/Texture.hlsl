#ifndef TEXTURE_INCLUDED
#define TEXTURE_INCLUDED

#include "ConstantBuffer/World.hlsl"

#define SamplerName(name) name##_sampler
#define WithSampler(name) name; SamplerState SamplerName(name)
#define WithSamplerComparison(name) name; SamplerComparisonState SamplerName(name)

#define SampleTexture(name, uv) name.Sample(SamplerName(name), uv)
#define SampleTextureLevel(name, uv, level) name.SampleLevel(SamplerName(name), uv, level)
#define SampleTextureBiased(name, uv, bias) name.SampleBias(SamplerName(name), uv, bias)
#define SampleTextureBiasedGl(name, uv) SampleTextureBiased(name, uv, global_mip_bias.x)
#define SampleTextureCmpLevelZero(name, location, compare_value) name.SampleCmpLevelZero(SamplerName(name), location, compare_value)
#define SampleTextureGrad(name, uv, ddx, ddy) name.SampleGrad(SamplerName(name), uv, ddx, ddy)
#define TextureGather(name, uv, offset) name.Gather(SamplerName(name), uv, offset)

float2 ComputeIndexedUV(float4 uv01, float4 uv23, float4 index)
{
	return
		uv01.xy * index.x
		+ uv01.zw * index.y
		+ uv23.xy * index.z
		+ uv23.zw * index.w;
}

float2 ComputeAnimatedUV(float2 uv, float4 matrix1, float4 matrix2)
{
	float4 translated = uv.xxyy * matrix1;
	return translated.xy + translated.zw + matrix2.xy;
}

#define IndexedUV(uv01, uv23, name) ComputeIndexedUV(uv01, uv23, TexcoordIndex_##name)
#define AnimatedUV(uv, name) ComputeAnimatedUV(uv, TexcoordMtx_##name[0], TexcoordMtx_##name[1])

#if defined(is_use_tex_srt_anim)
	#define TexUV(uv, name) AnimatedUV(uv, name)
#else
	#define TexUV(uv, name) uv
#endif

#endif