#ifndef MATH_INCLUDED
#define MATH_INCLUDED


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

#endif