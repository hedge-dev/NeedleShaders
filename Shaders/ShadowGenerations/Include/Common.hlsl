#ifndef COMMON_INCLUDED
#define COMMON_INCLUDED

#define TextureInput(name) \
	SamplerState name##_sampler; \
	Texture2D<float4> name##_NedSmpignorenametexture;

#define TextureArrayInput(name) \
	SamplerState name##_sampler; \
	Texture2DArray<float4> name;

#define SampleTexture(name, uv) name##_NedSmpignorenametexture.Sample(name##_sampler, uv)
#define SampleTextureLevel(name, uv, level) name.SampleLevel(name##_sampler, uv, level)
#define SampleTextureBiased(name, uv, bias) name##_NedSmpignorenametexture.SampleBias(name##_sampler, uv, bias)

#ifdef WORLD_CONSTANTBUFFER_INCLUDED
	#define SampleTextureBiasedGl(name, uv) SampleTextureBiased(name, uv, global_mip_bias.x)
#endif

#ifdef MATERIAL_IMMUTABLE_CONSTANTBUFFER_INCLUDED

	float2 GetIndexedUV(float4 uv01, float4 uv23, float4 index)
	{
		return
			uv01.xy * index.x
			+ uv01.zw * index.y
			+ uv23.xy * index.z
			+ uv23.zw * index.w;
	}

	float2 GetAnimatedUV(float2 uv, float4 matrix1, float4 matrix2)
	{
		float4 translated = uv.xxyy * matrix1;
		return translated.xy + translated.zw + matrix2.xy;
	}

	#define IndexedUV(uv01, uv23, name) GetIndexedUV(uv01, uv23, TexcoordIndex_##name)
	#define AnimatedUV(uv, name) GetAnimatedUV(uv, TexcoordMtx_##name[0], TexcoordMtx_##name[1])

#endif

#if defined(MATERIAL_IMMUTABLE_CONSTANTBUFFER_INCLUDED) && defined(is_use_tex_srt_anim)
	#define TexUV(uv, name) AnimatedUV(uv, name)
#else
	#define TexUV(uv, name) uv
#endif

#endif