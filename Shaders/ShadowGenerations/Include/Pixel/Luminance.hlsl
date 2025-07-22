#ifndef LUMINANCE_PIXEL_INCLUDED
#define LUMINANCE_PIXEL_INCLUDED

#include "../Texture.hlsl"

Texture2D<float4> WithSampler(s_Luminance);

float GetLuminance()
{
	return SampleTextureLevel(s_Luminance, float2(0.75, 0.5), 0).x;
}

#endif