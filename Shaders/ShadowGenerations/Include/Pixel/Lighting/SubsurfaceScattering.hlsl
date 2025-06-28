#ifndef SSS_LIGHTING_INCLUDED
#define SSS_LIGHTING_INCLUDED

//#include "../../Common.hlsl"
//DefineFeature(enable_ssss);
static const uint FEATURE_enable_ssss;

#include "../../ConstantBuffer/World.hlsl"
#include "../../Texture.hlsl"

#include "Struct.hlsl"

float4 ssss_param;
float4 ssss_colors[16];
float4 ssss_ambient_boost;

static groupshared int shared_variable;
RWTexture2D<float4> rw_Output1 : register(u1);
RWByteAddressBuffer rw_indirectSSSSDrawArguments : register(u2);
RWStructuredBuffer<int> rw_IndirectSSSSTiles : register(u3);

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

void ComputeSSSSTile(uint shader_model, uint groupIndex, uint2 groupThreadId)
{
	#ifndef enable_ssss
		return;
	#endif

	if(groupIndex == 0)
	{
		shared_variable = 0;
	}
	GroupMemoryBarrierWithGroupSync();

	if(shader_model == 3)
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
	#ifndef enable_ssss
		return;
	#endif

	rw_Output1[pixel] = 0.0;
}

void WriteSSSOutput(uint2 pixel, uint shader_model, float3 normal, float3 albedo, float3 ambient_color, float3 diffuse_color, float3 sss_param, inout float3 out_color)
{
	float3 sss_color = diffuse_color;
	if(shader_model == ShaderModel_SSS)
	{
		sss_color += ssss_ambient_boost.xyz * ambient_color * albedo;
	}

	#ifndef enable_ssss
		out_color += sss_color;
	#else

		float sss_alpha = 0.0;
		if(shader_model == ShaderModel_SSS)
		{
			sss_alpha = trunc(sss_param.y) + clamp(0.5 * sss_param.x, 0.01, 0.49);
			float4 ssss_color = ssss_colors[((uint)sss_alpha) % 16];

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

			sss_color += t4 * t3 * t1 * sss_param.z;
		}
		else
		{
			out_color += sss_color;
			sss_color = 0.0;
		}

		rw_Output1[pixel] = float4(sss_color, sss_alpha);
	#endif
}

#endif