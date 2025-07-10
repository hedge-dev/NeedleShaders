#ifndef MATH_INCLUDED
#define MATH_INCLUDED

static const float Pi = radians(180.0);
static const float Tau = radians(360.0);

// This is for the HLSL "ubfe" instruction:
// https://learn.microsoft.com/en-us/windows/win32/direct3dhlsl/ubfe--sm5---asm-
uint UnpackUIntBits(uint source, uint width, uint offset)
{
	uint result;

	if(width == 0)
	{
		result = 0;
	}
	else if(width + offset < 32)
	{
		result = source << (32 - (width + offset));
		result = result >> (32 - width);
	}
	else
	{
		result = source >> offset;
	}

	return result;
}

// This is for the HLSL "bfi" instruction:
// https://learn.microsoft.com/en-us/windows/win32/direct3dhlsl/bfi---sm5---asm-
uint SwapBits( uint a, uint b, uint input_width, uint output_offset)
{
	uint bitmask = (((1 << input_width)-1) << output_offset) & 0xffffffff;
	return ((a << output_offset) & bitmask) | (b & ~bitmask);
}

#define PlaceBits(a, input_width, output_offset) SwapBits(a, 0, input_width, output_offset)

uint CountTrue(bool4 cond)
{
	return dot(1.0.xxxx, cond ? 1.0.xxxx : 0.0.xxxx);
}

float InvLerp(float minimum, float maximum, float value)
{
	return (value - minimum) / (maximum - minimum);
}

float Remap(float from_min, float from_max, float to_min, float to_max, float value)
{
	return lerp(to_min, to_max, InvLerp(from_min, from_max, value));
}

#endif