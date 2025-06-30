#ifndef SSS_LIGHTING_INCLUDED
#define SSS_LIGHTING_INCLUDED

#include "../../Common.hlsl"
DefineFeature(enable_ssss);

#include "../../Texture.hlsl"
#include "../../Math.hlsl"
#include "Struct.hlsl"

//////////////////////////////////////////////////
// CDRF subsurface scattering

Texture2DArray<float4> WithSampler(s_Common_CDRF);

void SampleCDRF(LightingParameters parameters, float3 light_direction, float shadow, inout float3 result)
{
	#ifdef enable_ssss
		return;
	#endif

	float cos = dot(light_direction, parameters.world_normal);

	float t = saturate(cos * 0.5 + 0.5);
	      t = cos - t * (1.0 - shadow);
	      t = saturate(t * 0.5 + 0.5);

	result = SampleTextureLevel(s_Common_CDRF, float3(t, parameters.sss_param.xy), 0).xyz;
}

//////////////////////////////////////////////////
// Screen space subsurface scattering

float4 ssss_param;
float4 ssss_colors[16];
float4 ssss_ambient_boost;

static groupshared int shared_variable;
RWTexture2D<float4> rw_Output1 : register(u1);
RWByteAddressBuffer rw_indirectSSSSDrawArguments : register(u2);
RWStructuredBuffer<int> rw_IndirectSSSSTiles : register(u3);

void ComputeSSSSTile(uint shading_model, uint groupIndex, uint2 groupThreadId)
{
	#ifndef enable_ssss
		return;
	#endif

	if(groupIndex == 0)
	{
		shared_variable = 0;
	}
	GroupMemoryBarrierWithGroupSync();

	if(shading_model == ShadingModelID_SSS)
	{
		InterlockedOr(shared_variable, 1);
	}
	GroupMemoryBarrierWithGroupSync();

	if(shared_variable != 0 && groupIndex == 0)
	{
		uint index = 0;
		rw_indirectSSSSDrawArguments.InterlockedAdd(0, 6, index);
		rw_IndirectSSSSTiles[index / 6] = (uint)(groupThreadId.y * 0x00010000 + groupThreadId.x);
	}
}

void ComputeSSSOutput(LightingParameters parameters, float3 ambient_color, float3 light_color, inout float3 out_direct, out float4 ssss_output)
{
	ssss_output = 0.0;

	if(parameters.shading_model_id != ShadingModelID_SSS)
	{
		return;
	}

	out_direct += ssss_ambient_boost.xyz * ambient_color * parameters.albedo;

	#ifndef enable_ssss
		return;
	#endif

	ssss_output.w = trunc(parameters.sss_param.y) + clamp(0.5 * parameters.sss_param.x, 0.01, 0.49);
	float4 ssss_color = ssss_colors[((uint)ssss_output.w) % 16];

	float3 t1 = (light_color * parameters.albedo * ssss_color.xyz) / Pi;
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

	float t4 = saturate(0.3 + dot(u_lightDirection.xyz, -parameters.world_normal));

	ssss_output.xyz = out_direct + t4 * t3 * t1 * parameters.sss_param.z;
	out_direct = 0.0;
}

void WriteSSSSOutput(uint2 pixel, float4 value)
{
	#ifndef enable_ssss
		return;
	#endif

	rw_Output1[pixel] = value;
}

#endif