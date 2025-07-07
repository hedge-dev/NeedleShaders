#define IS_COMPUTE_SHADER

// Statically enabled features
#define enable_local_light_shadow
#define enable_para_corr

// This gets included by nature of the library and needs to be removed
#define no_shadow_as_pcf

#include "Include/Pixel/Deferred.hlsl"
#include "Include/Pixel/Lighting/CompositeDeferred.hlsl"

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
	DeferredData deferred_data = LoadDeferredData(input.dispatchThreadId.xy);

	LightingParameters parameters = LightingParametersFromDeferred(
		deferred_data.surface,
		input.dispatchThreadId.xy,
		PixelToScreen(input.dispatchThreadId.xy),
		deferred_data.depth
	);

	ComputeSSSSTile(parameters.shading_model.type, input.groupIndex, input.groupId.xy);

	if(parameters.shading_model.type == ShadingModelType_Clear
		|| (float)input.dispatchThreadId.x >= u_viewport_info.x
		|| (float)input.dispatchThreadId.y >= u_viewport_info.y)
	{
		rw_Output0[input.dispatchThreadId.xy] = clear_color;
		WriteSSSSOutput(input.dispatchThreadId.xy, 0.0);
		return;
	}

	float4 ssss_color;
	float ssss_mask;
	rw_Output0[input.dispatchThreadId.xy] = CompositeDeferredLighting(parameters, ssss_color, ssss_mask);
	WriteSSSSOutput(input.dispatchThreadId.xy, ssss_color);
}