#ifndef DEBUG_PIXEL_INCLUDED
#define DEBUG_PIXEL_INCLUDED

#include "ConstantBuffer/World.hlsl"

Texture2D<float4> s_DebugFont;

//////////////////////////////////////////////////
// First debug modes

#define DefineDebugView(num, name) static const int DebugView_##name = num

DefineDebugView( 1, DirDiffuse);
DefineDebugView( 2, DirSpecular);
DefineDebugView( 3, AmbDiffuse);
DefineDebugView( 4, AmbSpecular);
DefineDebugView( 5, OnlyIbl);
DefineDebugView( 6, OnlyIblSurfNormal);
DefineDebugView( 7, Shadow);
DefineDebugView( 8, WhiteAlbedo);
DefineDebugView( 9, WhiteAlbedoNoAo);
DefineDebugView(10, User0);
DefineDebugView(11, User1);
DefineDebugView(12, User2);
DefineDebugView(13, User3);
DefineDebugView(14, Albedo);
DefineDebugView(15, AlbedoCheckOutlier);
DefineDebugView(16, Opacity);
DefineDebugView(17, Normal);
DefineDebugView(18, Roughness);
DefineDebugView(19, Ambient);
DefineDebugView(20, Cavity);
DefineDebugView(21, Reflectance);
DefineDebugView(22, Metallic);
DefineDebugView(23, LocalLight);
DefineDebugView(24, ScatteringFex);
DefineDebugView(25, ScatteringLin);
DefineDebugView(26, SSAO);
DefineDebugView(27, RLR);
DefineDebugView(28, IblDiffuse);
DefineDebugView(29, IblSpecular);
DefineDebugView(30, EnvBRDF);
DefineDebugView(31, WorldPosition);
DefineDebugView(32, ShadingModelId);
DefineDebugView(33, IblCapture);
DefineDebugView(34, IblSkyTerrain);
DefineDebugView(35, WriteDepthToAlpha);
DefineDebugView(36, Smoothness);
DefineDebugView(37, OcclusionCapsule);
DefineDebugView(38, Probe);
DefineDebugView(39, CharacterMask);
DefineDebugView(40, Distance);
DefineDebugView(41, ShadingModel);
DefineDebugView(42, ShadingKind);
DefineDebugView(43, AmbDiffuseLf);
DefineDebugView(44, SggiOnly);

//////////////////////////////////////////////////
// Second debug modes

static const int Debug2Mode_1 = 1;
static const int Debug2Mode_2 = 2;
static const int Debug2Mode_3 = 3;

//////////////////////////////////////////////////
// Methods

int GetDebugView()
{
	return (int)round(g_debug_option.x);
}

int GetDebug2Mode()
{
	return (int)round(g_debug_option.y);
}

float3 ComputeUIntDebugColor(float3 base_color, uint integer)
{
	if(integer == 0)
	{
		return base_color;
	}

	float t = 4 * (1 - min(integer * 0.05, 1));
	int color_index = (int)trunc(t);
	t -= color_index;

	const float3 lut[5] = {
		float3(1,0,0),
		float3(1,1,0),
		float3(0,1,0),
		float3(0,1,1),
		float3(0,0,1),
	};

	float3 color = lerp(
		lut[color_index],
		lut[min(4, color_index + 1)],
		t
	);

	return lerp(base_color, color, 0.4);
}

float3 DebugTile_UInt4(uint2 pixel_position, uint4 number, float3 background)
{
	uint2 debug_position = pixel_position & 0xF;
	if(debug_position.x == 0 || debug_position.y == 0)
	{
		return background;
	}

	int dif = (int)debug_position.x - (int)debug_position.y;

	uint debug_number;
	if(dif < -8)
	{
		debug_number = number.x;
	}
	else if(dif < 0)
	{
		debug_number = number.y;
	}
	else if(dif < 8)
	{
		debug_number = number.z;
	}
	else
	{
		debug_number = number.w;
	}

	return ComputeUIntDebugColor(background, debug_number);
}

float3 DebugTile_UInt3(uint2 pixel_position, uint3 number, float3 background)
{
	return DebugTile_UInt4(pixel_position, number.xxyz, background);
}

float3 DebugTile_UInt2(uint2 pixel_position, uint2 number, float3 background)
{
	return DebugTile_UInt4(pixel_position, number.xxxy, background);
}

float3 DebugTile_UInt1(uint2 pixel_position, uint number, float3 background)
{
	return DebugTile_UInt4(pixel_position, number, background);
}


float3 DebugTile_NumText(uint2 pixel_position, uint number, float3 background)
{
	float3 result = background;

	bool had_digit = false;
	float decimal_position = 0.01;
	uint2 font_offset = pixel_position & ~0xF;

	for(int i = 0; i < 3; i++)
	{
		uint digit = (uint)trunc(number * decimal_position);

		had_digit = had_digit || digit != 0;
        if (i == 2 || had_digit)
		{
			uint2 t5 = pixel_position - font_offset;
			if (t5.x < 8 && t5.y < 8) {
				int3 sample_pos = int3(t5.x + digit * 7, t5.y + 207, 0);
				float font = s_DebugFont.Load(sample_pos).w;
				result = lerp(result, (1.0 - background), font);
          	}
        }

        font_offset += 5;
        decimal_position *= 10;
	}

	return result;
}

#endif