#ifndef TYPED_OCCLUSION_PIXEL_INCLUDED
#define TYPED_OCCLUSION_PIXEL_INCLUDED

static const uint OcclusionType_AOLightField = 0;
static const uint OcclusionType_ShadowGI = 1;
static const uint OcclusionType_AOGI = 2;
static const uint OcclusionType_SGGI = 3;

struct TypedOcclusion
{
	float value;
	uint mode;
	bool sign;
};

TypedOcclusion DecodeTypedOcclusion(float value)
{
	TypedOcclusion result;

	result.sign = value < -value;
	result.mode = (uint)trunc(abs(value) / 10.0);
	result.value = abs(value) - result.mode * 10;

	return result;
}

float EncodTypedOcclusion(TypedOcclusion occlusion)
{
	return (occlusion.mode * 10 + occlusion.value) * (occlusion.sign ? -1 : 1);
}

#endif