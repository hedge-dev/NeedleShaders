#ifndef DITHERING_PIXEL_INCLUDED
#define DITHERING_PIXEL_INCLUDED

#include "../ConstantBuffer/World.hlsl"
#include "../ConstantBuffer/MaterialDynamic.hlsl"

Texture2D<float4> s_Dither;

#define SampleDither(pos) s_Dither.Load(int3(((int2)pos.xy) % 16, 0)).x

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

void ViewportTransparencyDiscardDithering(float2 position)
{
	float force_viewport_transparency = dot(u_current_viewport_mask, u_forcetrans_param);
    float dither = SampleDither(position) * 0.98 + 0.01;

    if(force_viewport_transparency - dither < 0)
    {
        discard;
    }
}

#endif