#ifndef COLOR_CONVERSION_INCLUDED
#define COLOR_CONVERSION_INCLUDED

#define LinearToSrgb(lin) exp2(2.2 * log2(abs(lin)))

// Color conversion functions below sourced from https://www.chilliant.com/rgb2hsv.html
// They are 1:1 what Sonic team used

static const float Epsilon = 1e-10;

float3 RGBtoHVC(in float3 rgb)
{
	// Based on work by Sam Hocevar and Emil Persson
	float4 p = (rgb.g < rgb.b) ? float4(rgb.bg, -1.0, 2.0/3.0) : float4(rgb.gb, 0.0, -1.0/3.0);
	float4 q = (rgb.r < p.x) ? float4(p.xyw, rgb.r) : float4(rgb.r, p.yzx);
	float c = q.x - min(q.w, q.y);
	float h = abs((q.w - q.y) / (6 * c + Epsilon) + q.z);
	return float3(h, c, q.x);
}

float3 RGBtoHSV(float3 rgb)
{
	float3 hcv = RGBtoHVC(rgb);
	float S = hcv.y / (hcv.z + Epsilon);
	return float3(hcv.x, S, hcv.z);
}

float3 HueToRGB(float hue)
{
	float r = abs(hue * 6 - 3) - 1;
	float g = 2 - abs(hue * 6 - 2);
	float b = 2 - abs(hue * 6 - 4);
	return saturate(float3(r,g,b));
}

float3 HSVtoRGB(float3 hsv)
{
	float3 rgb = HueToRGB(hsv.x);
	return ((rgb - 1) * hsv.y + 1) * hsv.z;
}

#endif