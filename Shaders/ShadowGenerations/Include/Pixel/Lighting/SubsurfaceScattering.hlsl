#ifndef SSS_LIGHTING_INCLUDED
#define SSS_LIGHTING_INCLUDED

#include "../../ConstantBuffer/World.hlsl"
#include "../../Common.hlsl"
#include "../../Texture.hlsl"

static const uint FEATURE_enable_ssss;
//DefineFeature(enable_ssss);

float4 ssss_param;
float4 ssss_colors[16];
float4 ssss_ambient_boost;

static groupshared int shared_variable;
RWTexture2D<float4> rw_Output1 : register(u1);
RWByteAddressBuffer rw_indirectSSSSDrawArguments : register(u2);
RWStructuredBuffer<int> rw_IndirectSSSSTiles : register(u3);


Texture2DArray<float4> WithSampler(s_Common_CDRF);

float3 GetCDRF(uint shading_mode, float light_factor, float light_factor_clamped, float ao_3, float3 blue_emission_thing)
{
	bool use_simple = true;

	#ifndef enable_ssss
		use_simple = shading_mode != 3;
	#endif

	if(use_simple)
	{
		return light_factor_clamped * ao_3;
	}

	float t = min(1.0, max(-1.0, saturate((1.0 + light_factor) * 0.5) * (1.0 - ao_3) + light_factor) * 0.5 + 0.5);
	return SampleTextureLevel(s_Common_CDRF,  float3(t, blue_emission_thing.xy), 0).xyz;
}

void ComputeSSSSTile(uint shading_mode, uint groupIndex, uint2 groupThreadId)
{
	#ifndef enable_ssss
		return;
	#endif

	if(groupIndex == 0)
	{
		shared_variable = 0;
	}
	GroupMemoryBarrierWithGroupSync();

	if(shading_mode == 3)
	{
		InterlockedOr(shared_variable, 1);
	}
	GroupMemoryBarrierWithGroupSync();

	if(shared_variable != 0 && groupIndex == 0)
	{
		uint ssss_thing = 0;
		rw_indirectSSSSDrawArguments.InterlockedAdd(0, 6, ssss_thing);
		rw_IndirectSSSSTiles[ssss_thing / 6] = (uint)(groupThreadId.y * 0x00010000 + groupThreadId.x);
	}
}

void ClearSSSOutput(uint2 pixel)
{
	#ifdef enable_ssss
		rw_Output1[pixel] = 0.0;
	#endif
}

void WriteSSSOutput(uint2 pixel, uint shading_mode, float3 normal, float3 albedo, float3 ambient_color, float3 oc_thing_7, float3 blue_emission_thing, inout float3 out_color)
{
	#ifndef enable_ssss
		out_color += oc_thing_7;

		if(shading_mode == 3)
		{
			out_color += ssss_ambient_boost.xyz * ambient_color.xyz * albedo;
		}
	#else

		float4 out_sss = 0.0;
		if(shading_mode == 3)
		{
			out_sss.w = trunc(blue_emission_thing.y) + clamp(0.5 * blue_emission_thing.x, 0.01, 0.49);
			float4 ssss_color = ssss_colors[((uint)out_sss.w) % 16];

			float3 t1 = u_lightColor.xyz * albedo.xyz * 0.31831 * ssss_color.xyz;
			float t2 = -pow((1.0 - ssss_color.w) * ssss_param.x * max(10, ssss_param.z), 2);

			float2 t_values[6] = {
				{ 225.421097, 0.233 },
				{ 29.807749, 0.1 },
				{ 7.714946, 0.118 },
				{ 2.544436, 0.113 },
				{ 0.724972, 0.358 },
				{ 0.194696, 0.078 },
			};

			float t3 = 0.0;
			for(int i = 0; i < 6; i++)
			{
				t3 += exp2(t_values[i].x * t2) * t_values[i].y;
			}

			float t4 = saturate(0.3 + dot(u_lightDirection.xyz, -normal));

			out_sss.xyz = ambient_color * ssss_ambient_boost.xyz * albedo
				+ t4 * t3 * t1 * blue_emission_thing.z
				+ oc_thing_7;
		}
		else
		{
			out_color += oc_thing_7;
		}

		rw_Output1[pixel] = out_sss;
	#endif
}

#endif