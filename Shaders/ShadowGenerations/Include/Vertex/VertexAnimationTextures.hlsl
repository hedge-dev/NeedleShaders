#ifndef VAT_VERTEX_INCLUDED
#define VAT_VERTEX_INCLUDED

#include "../Common.hlsl"

#if !defined(is_vat_enabled) && !defined(no_is_vat_enabled)
	DefineFeature(is_vat_enabled);
#endif

#ifdef is_vat_enabled

	#include "../ConstantBuffer/MaterialDynamic.hlsl"

	#include "../Texture.hlsl"
	#include "../IOStructs.hlsl"

	Texture2D<float4> WithSampler(s_VertexAnimationTexture_0);
	Texture2D<float4> WithSampler(s_VertexAnimationTexture_1);

	void ComputeVAT1Values(float2 vat_uv, inout float3 position, out float3 normal)
	{
		float3 vat0 = SampleTextureLevel(s_VertexAnimationTexture_0, vat_uv, 0).xyz;
		float3 vat1 = SampleTextureLevel(s_VertexAnimationTexture_1, vat_uv, 0).xyz;

		position += lerp(u_vat_param.y, u_vat_param.z, vat0.xzy) * 0.1;
		normal = vat1.xzy * 2.0 - 1.0;
	}

	void ComputeVAT2Values(float2 vat_uv, float3 color, inout float3 position, inout float3 normal)
	{
		static const float3 vat_pos_fix = float3(-1, 1, 1);
		static const float4 vat_nrm_fix = float4(1, -1, -1, 1);

		float3 color_pos = lerp(u_vat_param2.z, u_vat_param2.w, color) * vat_pos_fix;
		float3 color_offset = position - color_pos;

		float3 vat0 = SampleTextureLevel(s_VertexAnimationTexture_0, vat_uv, 0).xyz;
		float4 vat1 = SampleTextureLevel(s_VertexAnimationTexture_1, vat_uv, 0);

		float3 vat_position = lerp(u_vat_param2.x, u_vat_param2.y, vat0) * vat_pos_fix;
		float4 vat_normal = (vat1 * 2.0 - 1.0) * vat_nrm_fix;

		#define ABF(a, b, f) (cross(a, cross(a,b) + f * b) * 2 + b)

		position = ABF(vat_normal.xyz, color_offset, vat_normal.w) + vat_position;
		normal = ABF(vat_normal.xyz, normal, vat_normal.w);

		#undef ABF
	}

	void ComputeVertexAnimation(
		float vat_offset,
		float3 color,
		inout float3 position,
		inout float3 normal,
		inout float3 previous_position)
	{
		float4 vat_uv = float4(
			vat_offset, u_vat_param.x,
			vat_offset, u_vat_param.x - u_vat_param.w * g_time_param.x
		);

		float3 prev_normal_discard;

		if(u_vat_type.x > 0)
		{
			ComputeVAT2Values(vat_uv.xy, color, position, normal);
			ComputeVAT2Values(vat_uv.zw, color, previous_position, prev_normal_discard);
		}
		else
		{
			ComputeVAT1Values(vat_uv.xy, position, normal);
			ComputeVAT1Values(vat_uv.zw, previous_position, prev_normal_discard);
		}
	}

#endif

#endif