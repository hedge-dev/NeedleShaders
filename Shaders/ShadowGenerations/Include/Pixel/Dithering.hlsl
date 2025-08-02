#ifndef DITHERING_PIXEL_INCLUDED
#define DITHERING_PIXEL_INCLUDED

#include "../ConstantBuffer/World.hlsl"
#include "../ConstantBuffer/MaterialDynamic.hlsl"
#include "../Texture.hlsl"

Texture2D<float4> WithSampler(s_Dither);
Texture2D<float4> s_BlueNoise;

#define SampleDither(pos) (s_Dither.Load(int3(((uint2)pos.xy) % 16, 0)).x)

void DiscardDithering(float2 position, float opacity)
{
    float dither = abs(opacity) - min(0.996078432, SampleDither(position));

    if(opacity <= 0)
    {
        dither = -dither;
    }

    if(dither < 0)
    {
        discard;
    }
}

float ComputeBlueNoise(uint2 pixel_position)
{
    float3 dimensions;
    s_BlueNoise.GetDimensions(0, dimensions.x, dimensions.y, dimensions.z);

    float2 sample_pos = pixel_position + 0.5;

    float jitter = jitter_offset.x * jitter_offset.x + jitter_offset.y * jitter_offset.y;
    uint time = jitter != 0.0 ? asuint(g_time_param.w) : 0;

    uint2 time_bit = uint2(
        time & 1,
        (time >> 1) & 1
    );

    sample_pos += time_bit * dimensions.xy * 0.5;
    sample_pos *= u_viewport_info.zw / dimensions.xy;

    return s_BlueNoise.SampleLevel(SamplerName(s_Dither), sample_pos, 0).x;
}


#endif