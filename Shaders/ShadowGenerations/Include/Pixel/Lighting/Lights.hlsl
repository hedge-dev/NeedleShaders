#ifndef LIGHTS_LIGHTING_INCLUDED
#define LIGHTS_LIGHTING_INCLUDED

#include "../../ConstantBuffer/World.hlsl"
#include "../../ConstantBuffer/LocalLightContextData.hlsl"

#include "../../Math.hlsl"
#include "../../Texture.hlsl"

#include "Struct.hlsl"
#include "SubsurfaceScattering.hlsl"


Buffer<uint> s_LocalLightIndexData;
TextureCubeArray<float4> WithSamplerComparison(s_LocalShadowMap);

static const float2 light_something[5] = {
	{ 0.0, 0.0 },
	{ 1.0, 1.0 },
	{ 1.0, -1.0 },
	{ -1.0, 1.0 },
	{ -1.0, -1.0 }
};

void GetLightColors(LightingParameters parameters, out float3 result_1, out float3 result_2)
{
	result_1 = 0.0; // r21
	result_2 = 0.0; // r22

	uint light_count = g_local_light_count.x;
	if(light_count == 0)
	{
		return;
	}

	// WIP
	/*float4 r14, r1, r8, r10, r18, r12, r13, r23, r24, r16, r17, r25, r29, r26, r28, r27, r11;
	int4 bitmask;

	r14.xy = (int2)u_tile_info.zw;
	r14.xy = (int2)r14.xy + int2(15,15);
	r14.xy = (uint2)r14.xy >> int2(4,4);
	r14.xy = (int2)parameters.tile_position < (int2)r14.xy;
	r1.x = r14.y ? r14.x : 0;
	r14.xy = (uint2)u_tile_info.xy;
	r8.z = mad((int)r1.z, (int)r14.x, (int)r1.y);
	r8.z = (int)r8.z * 3;
	r10.y = s_LocalLightIndexData[r8.z].x;
	r10.y = asint(r10.y) & 0x0000ffff;
	r18.x = min(64, (uint)r10.y);
	r8.z = (uint)r8.z << 6;
	r18.y = (int)r8.z + (int)r14.y;
	r14.xy = asint(r1.xx) & asint(r18.xy);
	r1.x = 1 << parameters.flags_unk1;
	r18.y = 1;

	for(int i = 0; i < (uint)r14.x; i++)
	{
		r10.y = i + (int)r14.y;
		r10.y = s_LocalLightIndexData[r10.y].x;
		bitmask.y = ((~(-1 << 16)) << 2) & 0xffffffff;  r10.y = (((uint)r10.y << 2) & bitmask.y) | ((uint)0 & ~bitmask.y);
		r11.w = asint(r1.x) & asint(g_local_light_data[r10.y/4]._m33);
		r12.y = UnpackUIntBits((uint)g_local_light_data[r10.y/4]._m33, 3, 16);
		r12.y = (int)r12.y + -1;
		r13.w = (int)r12.y >= 0;
		r14.z = 0.01 < abs(g_local_light_shadow_param[r12.y].w);
		r13.w = r13.w ? r14.z : 0;

		if (r13.w == 0) {
			r13.w = 1;
		} else {
			r14.z = g_local_light_shadow_param[r12.y].w < 0;
			r23.xyz = -g_local_light_shadow_param[r12.y].xyz + parameters.world_position.xyz;
			r14.w = dot(r23.xyz, r23.xyz);
			r18.x = sqrt(r14.w);
			if (r14.z != 0) {
				r14.z = (uint)r12.y << 2;
				r24.xyzw = g_local_light_shadow_matrix[r14.z/4]._m10_m11_m12_m13 * parameters.world_position.yyyy;
				r24.xyzw = parameters.world_position.xxxx * g_local_light_shadow_matrix[r14.z/4]._m00_m01_m02_m03 + r24.xyzw;
				r24.xyzw = parameters.world_position.zzzz * g_local_light_shadow_matrix[r14.z/4]._m20_m21_m22_m23 + r24.xyzw;
				r24.xyzw = g_local_light_shadow_matrix[r14.z/4]._m30_m31_m32_m33 + r24.xyzw;
				r24.xyz = r24.zxy / r24.www;
				r18.zw = float2(1,-1) * r24.zy;
				r14.z = dot(r18.yzw, r18.yzw);
				r14.z = rsqrt(r14.z);
				r24.yzw = r18.xzw * r14.zzz;
				r23.xyz = r24.yzw * r18.yxx;
				r14.zw = r23.yz;
			} else {
				r16.w = (uint)r12.y << 2;
				r17.w = max(abs(r23.y), abs(r23.z));
				r17.w = max(abs(r23.x), r17.w);
				r18.zw = g_local_light_shadow_matrix[r16.w/4]._m22_m23 * -r17.ww + g_local_light_shadow_matrix[r16.w/4]._m32_m33;
				r24.x = r18.z / r18.w;
				r14.zw = r23.yz;
			}
			r25.w = (int)r12.y;
			r16.w = -0.00100000005 + r24.x;
			r17.w = 0;

			for(int j = 0; j < 5; j++)
			{
				r23.zw = light_something[j].xy * float2(0.002,0.002);
				sincos(r23.z, r24.x, r26.x);
				sincos(r23.w, r27.x, r28.x);
				r29.xz = sin(-r23.zw);
				r29.y = r26.x;
				r25.y = dot(r29.yx, r14.zw);
				r29.w = r24.x;
				r23.y = dot(r29.wy, r14.zw);
				r29.x = r28.x;
				r29.y = r27.x;
				r25.x = dot(r29.xy, r23.xy);
				r25.z = dot(r29.zx, r23.xy);
				r18.w = SampleTextureCmpLevelZero(s_LocalShadowMap, r25.xyzw, r16.w).x;
				r17.w = r18.w + r17.w;
			}

			r14.z = -1 + r18.x;
			r14.z = saturate(-2.50000024 * r14.z);
			r14.w = r14.z * -2 + 3;
			r14.z = r14.z * r14.z;
			r14.z = r14.w * r14.z;
			r14.z = r17.w * 0.200000003 + r14.z;
			r14.z = min(1, r14.z);
			r14.z = -1 + r14.z;
			r13.w = abs(g_local_light_shadow_param[r12.y].w) * r14.z + 1;
		}
		if (r11.w != 0) {
			r18.xzw = g_local_light_data[r10.y/4]._m10_m11_m12 - parameters.world_position.xyz;
			r11.w = dot(r18.xzw, r18.xzw);
			r12.y = g_local_light_data[r10.y/4]._m13 < r11.w;
			r14.z = g_local_light_data[r10.y/4]._m00 + g_local_light_data[r10.y/4]._m01;
			r14.z = g_local_light_data[r10.y/4]._m02 + r14.z;
			r14.z = abs(r14.z) < 9.99999997e-007;
			r12.y = (int)r12.y | (int)r14.z;
			if (r12.y == 0) {
				r12.y = 256 & asint(g_local_light_data[r10.y/4]._m33);
				r14.z = rsqrt(r11.w);
				r23.xyz = r18.xzw * r14.zzz;
				r14.w = dot(g_local_light_data[r10.y/4]._m20_m21_m22, -r23.xyz);
				r14.w = -g_local_light_data[r10.y/4]._m30 + r14.w;
				r14.w = saturate(g_local_light_data[r10.y/4]._m31 * r14.w);
				r14.w = r14.w * r14.w;
				r16.w = r14.w >= 9.99999997e-007;
				r16.w = r12.y ? r16.w : -1;
				if (r16.w != 0) {
					r24.xy = int2(16,32) & asint(g_local_light_data[r10.y/4]._m33_m33);
					r16.w = r11.w / g_local_light_data[r10.y/4]._m13;
					r16.w = -r16.w * r16.w + 1;
					r16.w = max(0, r16.w);
					r16.w = r16.w * r16.w;
					r25.xyz = g_local_light_data[r10.y/4]._m00_m01_m02 * float3(0.0795774683,0.0795774683,0.0795774683);
					r10.y = r12.y ? r14.w : 1;
					r11.w = max(1, r11.w);
					r11.w = rcp(r11.w);
					r12.y = dot(parameters.world_normal, r23.xyz);
					r26.xyz = saturate(r12.yyy);
					r18.xzw = r18.xzw * r14.zzz + normalize(u_cameraPosition.xyz - parameters.world_position.xyz);
					r14.z = dot(r18.xzw, r18.xzw);
					r14.z = rsqrt(r14.z);
					r18.xzw = r18.xzw * r14.zzz;
					r14.z = saturate(dot(r18.xzw, r23.xyz));
					r14.z = 1 + -r14.z;
					r14.w = r14.z * r14.z;
					r14.w = r14.w * r14.w;
					r14.z = r14.z * r14.w;
					r23.xyz = r17.xyz * r14.zzz + parameters.fresnel_reflectance;
					r11.w = r11.w * r16.w;
					r10.y = r11.w * r10.y;

					if (r24.y != 0)
					{
						r11.w = r13.w * r10.y;
						r14.z = saturate(dot(parameters.world_normal, r18.xzw));
						r14.w = -r14.z * r14.z + 1;
						r14.z = r14.z * parameters.roughness;
						r14.z = r14.z * r14.z + r14.w;
						r14.z = parameters.roughness / r14.z;
						r14.z = r14.z * r14.z;
						r14.z = 0.318309873 * r14.z;
						r14.w = r26.z * r8.x + r8.y;
						r14.w = r14.w * r11.y;
						r14.w = 0.25 / r14.w;
						r14.z = r14.z * r14.w;
						r18.xzw = saturate(r14.zzz * r23.xyz);
						r18.xzw = r18.xzw * r26.xyz;
						r18.xzw = r18.xzw * r25.xyz;
						result_2 += r11.www * r18.xzw;
					}

					if (r24.x != 0)
					{
						r10.y = r13.w * r10.y;

						#ifndef enable_ssss
							if (parameters.shading_mode == 3)
							{
								r11.w = max(-1, r12.y);
								r11.w = r11.w * 0.5 + 0.5;
								r12.x = min(1, r11.w);
								r26.xyz = SampleTextureLevel(s_Common_CDRF, r12.xzw, 0).xyz;
							}
						#endif

						r18.xzw = r26.xyz * r25.xyz;
						r11.w = 1 + -r23.x;
						r11.w = r11.w * (1.0 - parameters.ambient_occlusion);
						r18.xzw = r18.xzw * r11.www;
						result_1 += r10.yyy * r18.xzw;
					}
				}
			}
		}
	}*/
}

#endif