#ifndef SHADING_MODEL_PIXEL_INCLUDED
#define SHADING_MODEL_PIXEL_INCLUDED

#include "../ConstantBuffer/MaterialDynamic.hlsl"

// TODO figure out what these do
// Notes:
// 2 = Approximate Environment BRDF

static const uint ShadingModelType_Clear = 0;
static const uint ShadingModelType_1 = 1;
static const uint ShadingModelType_2 = 2;
static const uint ShadingModelType_SSS = 3;
static const uint ShadingModelType_AnisotropicReflection = 4;
static const uint ShadingModelType_5 = 5;
static const uint ShadingModelType_6 = 6;
static const uint ShadingModelType_7 = 7;

static const uint ShadingModelKind_0 = 0;
static const uint ShadingModelKind_Character = 1;
static const uint ShadingModelKind_2 = 2;
static const uint ShadingModelKind_3 = 3;

// idk where else to put these, so they go here right now
static const uint OcclusionMode_AOLightField = 0;
static const uint OcclusionMode_ShadowGI = 1;
static const uint OcclusionMode_SGGI = 2;
static const uint OcclusionMode_AOGI = 3;

struct ShadingModel
{
	uint type;
	bool unknown;
	uint kind;
};

ShadingModel ShadingModelFromFlags(uint flags)
{
	ShadingModel result;

	result.type = flags & 0x7;
	result.unknown = (flags & 0x8) != 0;
	result.kind = (flags >> 4) & 0x3;

	return result;
}

ShadingModel ShadingModelFromCB(uint type)
{
	return ShadingModelFromFlags(asuint(u_shading_model_flag.x) | type);
}

uint ShadingModelToFlags(ShadingModel model)
{
	return
		model.type
		| (model.unknown ? 0x8 : 0)
		| (model.kind << 4);
}

#endif