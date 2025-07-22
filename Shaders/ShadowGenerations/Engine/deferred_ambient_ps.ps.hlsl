#include "../Include/ConstantBuffer/World.hlsl"
#include "../Include/ConstantBuffer/LightFieldClipmap.hlsl"

#include "../Include/Texture.hlsl"
#include "../Include/Transform.hlsl"

Texture2D<float4> WithSampler(s_DepthBuffer);
Texture2D<float4> WithSampler(s_CopyGBuffer1);

Texture3D<float4> WithSampler(s_LightField0);
Texture3D<float4> WithSampler(s_LightField1);
Texture3D<float4> WithSampler(s_LightField2);
Texture3D<float4> WithSampler(s_LightField3);
Texture3D<float4> WithSampler(s_LightField4);
Texture3D<float4> WithSampler(s_LightField5);
Texture3D<float4> WithSampler(s_LightField6);
Texture3D<float4> WithSampler(s_LightField7);
Texture3D<float4> WithSampler(s_LightField8);
Texture3D<float4> WithSampler(s_LightField9);
Texture3D<float4> WithSampler(s_LightField10);
Texture3D<float4> WithSampler(s_LightField11);

void ComputeProbeSample(uint index, float4 position, float3 normal, Texture3D<float4> lf_texture, SamplerState lf_sampler, inout float remainder, inout float buffer[6])
{
	uint light_field_count = (uint)floor(0.5 + u_lf_param.x);
	if(remainder <= 0.0 || index >= light_field_count)
	{
		return;
	}

	float4x4 lf_matrix = u_inv_obb[index];
	float3 lf_position = mul(position, lf_matrix).xyz;

	// getting the furthest distance to the light fields edges
	float3 t = abs(lf_position);
	float distance = max(max(t.x, t.y), t.z) * 2;

	// if the point is outside the light field,
	// then we can skip it
	if(distance >= 1.0)
	{
		return;
	}

	// getting the sampling influence; The point at which the influence
	// starts falling (fading out) is controlled with u_lf_param.z
	float distance_falloff_start = saturate(1.0 - u_lf_param.z);
    float factor = saturate(1.0 - (distance - distance_falloff_start) / (1.0 - max(0.01, distance_falloff_start)));

	// Note: There was originally an if check here that checks if factor is above 0,
	// but it can only be 0 when distance is >= 1.0, which we rule out before already

	float3 lf_normal = normalize(mul(normal, (float3x3)lf_matrix));
	float3 probe_resolution = u_probe_resolution[index].xyz;

	// Note: Adding 0.5 to shift the position from range (-0.5, 0.5) to (0, 1)

	float3 sample_pos = saturate(lf_position + 0.5) + (lf_normal * u_lf_param.y / probe_resolution);

	// The sampling position is clamped to half a pixel of the tile bounds
	// to ensure that we stay within out tile, and don't accidentally sample
	// from a neighbouring tile

	sample_pos = clamp(
		sample_pos,
		0.5 / probe_resolution,
		1.0 - (0.5 / probe_resolution)
	);

	float3 tile_width = float3(1.0 / 9.0, 0.0, 0.0);
	sample_pos.x *= tile_width.x;

	factor = min(factor, remainder);

	for(int i = 0; i < 6; i++)
	{
		buffer[i] += factor * lf_texture.SampleLevel(lf_sampler, sample_pos, 0.0).x;
		sample_pos += tile_width;
	}

	remainder = max(0, remainder - factor);
}

float4 main(
	float4 vertex_position : SV_POSITION0,
	float2 uv : TEXCOORD0) : SV_Target0
{
	float3 normal = normalize(SampleTexture(s_CopyGBuffer1, uv).xyz * 2.0 - 1.0);
	float depth = SampleTexture(s_DepthBuffer, uv).x;
	float4 position = ScreenDepthToWorldPosition(uv, depth);

	float buffer[6] = {0, 0, 0, 0, 0, 0};
	float remainder = 1.0;

	#define Compute(index) ComputeProbeSample(index, position, normal, s_LightField##index, SamplerName(s_LightField##index), remainder, buffer)

	Compute(0);
	Compute(1);
	Compute(2);
	Compute(3);
	Compute(4);
	Compute(5);
	Compute(6);
	Compute(7);
	Compute(8);
	Compute(9);
	Compute(10);
	Compute(11);

	if(remainder > 0)
	{
		for(int i = 0; i < 6; i++)
		{
			buffer[i] += remainder;
		}
	}

	// if u_lf_param.w is set, make AO from the "bottom"/floor be dark
	if(u_lf_param.w > 0.0)
	{
		buffer[3] = 0.0;
	}

	float3 combined_buffer = lerp(
		float3(buffer[1], buffer[3], buffer[5]),
		float3(buffer[0], buffer[2], buffer[4]),
		normal * 0.5 + 0.5
	);

	float output = max(0.0001, saturate(dot(combined_buffer, normal * normal)));

	return float4(0, 0, 0, output);
}