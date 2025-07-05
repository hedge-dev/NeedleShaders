#include "Include/ConstantBuffer/SHLightFieldProbes.hlsl"

#include "Include/Pixel/Lighting/Shadow.hlsl"
#include "Include/Pixel/Lighting/SSAO.hlsl"
#include "Include/Pixel/Deferred.hlsl"

#include "Include/IOStructs.hlsl"

float ComputeShadow(LightingParameters parameters)
{
	float result = 1.0;

	if(parameters.shading_model.type == ShadingModelType_Clear)
	{
		return result;
	}

	if(parameters.occlusion_mode == OcclusionMode_AOGI && shlightfield_param.x > 0)
	{
		result = parameters.occlusion_value;
	}

	if(parameters.occlusion_sign <= 0 || result <= 0.0)
	{
		return result;
	}

	float factor = ComputeShadowValue(parameters.world_position, parameters.screen_position);
	ComputeVolShadowValue(parameters.world_position.xyz, factor);

	result *= factor;
	return result;
}

float4 main(BlitIn input) : SV_Target0
{
    uint2 pixel_position = (uint2)input.pixel_position.xy;
    DeferredData deferred_data = LoadDeferredData(pixel_position);

    LightingParameters parameters = InitLightingParameters();
    TransferSurfaceData(deferred_data.surface, parameters);
    TransferPixelData(pixel_position, input.screen_position.xy, deferred_data.depth, parameters);

	float shadow = ComputeShadow(parameters);
	float4 result = ComputeSSAO(parameters, shadow);

	return result;
}