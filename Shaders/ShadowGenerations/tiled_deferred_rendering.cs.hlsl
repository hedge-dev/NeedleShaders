#define IS_COMPUTE_SHADER

// Statically enabled features
#define enable_local_light_shadow
#define enable_para_corr

#include "Include/Pixel/Lighting/Composite.hlsl"

Texture2D<float4> s_DepthBuffer;
Texture2D<float4> s_GBuffer0;
Texture2D<float4> s_GBuffer1;
Texture2D<float4> s_GBuffer2;
Texture2D<float4> s_GBuffer3;

RWTexture2D<float4> rw_Output0 : register(u0);
RWTexture2D<float4> rw_Output1 : register(u1);

struct ThreadInfo {
	uint3 groupId : SV_GroupID;
    uint3 groupThreadId : SV_GroupThreadID;
    uint3 dispatchThreadId : SV_DispatchThreadID;
    uint groupIndex : SV_GroupIndex;
};

void WriteSSSSOutput(uint2 pixel, float4 value)
{
	#ifndef enable_ssss
		return;
	#endif

	rw_Output1[pixel] = value;
}

[numthreads(8, 8, 1)]
void main(ThreadInfo input)
{
	SurfaceData deferred_data = InitSurfaceData();

	uint3 buffer_uv = int3(input.dispatchThreadId.xy, 0);
	deferred_data.albedo = s_GBuffer0.Load(buffer_uv);
	deferred_data.normal = s_GBuffer1.Load(buffer_uv).xyz;
	deferred_data.emission = s_GBuffer2.Load(buffer_uv);
	deferred_data.prm = s_GBuffer3.Load(buffer_uv);

	LightingParameters parameters = InitLightingParameters();
	TransferSurfaceData(deferred_data, parameters);

	ComputeSSSSTile(parameters.shading_model.type, input.groupIndex, input.groupId.xy);

	if(parameters.shading_model.type == ShadingModelType_Clear
		|| (float)input.dispatchThreadId.x >= u_viewport_info.x
		|| (float)input.dispatchThreadId.y >= u_viewport_info.y)
	{
		rw_Output0[input.dispatchThreadId.xy] = clear_color;
		WriteSSSSOutput(input.dispatchThreadId.xy, 0.0);
		return;
	}

	float depth = s_DepthBuffer.Load(buffer_uv).x;
	TransferPixelData(input.dispatchThreadId.xy, depth, parameters);

	float4 ssss_color;
	float ssss_mask;
	rw_Output0[input.dispatchThreadId.xy] = CompositeLighting(parameters, ssss_color, ssss_mask);
	WriteSSSSOutput(input.dispatchThreadId.xy, ssss_color);
}