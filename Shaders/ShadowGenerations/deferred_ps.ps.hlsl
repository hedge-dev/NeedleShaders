// This gets included by nature of the library and needs to be removed
#define no_shadow_as_pcf

#include "Include/IOStructs.hlsl"
#include "Include/Pixel/Deferred.hlsl"
#include "Include/Pixel/Lighting/Composite.hlsl"

struct DeferredOut
{
	float4 color : SV_Target0;

	#ifdef enable_ssss
		float4 ssss_color : SV_Target1;
		float ssss_mask : SV_Depth;
	#endif
};


DeferredOut main(BlitIn input)
{
	uint2 pixel_position = (uint2)input.pixel_position.xy;
	DeferredData deferred_data = LoadDeferredData(pixel_position);

	LightingParameters parameters = LightingParametersFromDeferred(
		deferred_data.surface,
		pixel_position,
		input.screen_position.xy,
		deferred_data.depth
	);

	DeferredOut result;

	if(parameters.shading_model.type == ShadingModelType_Clear)
	{
		result.color = clear_color;

		#ifdef enable_ssss
			result.ssss_color = 0.0;
			result.ssss_mask = 0.0;
		#endif

		return result;
	}

	float4 ssss_color;
	float ssss_mask;
	result.color = CompositeLighting(parameters, ssss_color, ssss_mask);

	#ifdef enable_ssss
		result.ssss_color = ssss_color;
		result.ssss_mask = ssss_mask;
	#endif

	return result;
}