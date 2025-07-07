#ifndef REFLECTION_LIGHTING_INCLUDED
#define REFLECTION_LIGHTING_INCLUDED

#include "IBL.hlsl"
#include "IBLProbe.hlsl"
#include "ScreenSpaceReflections.hlsl"

float4 ComputeReflectionIBLOnly(LightingParameters parameters, bool specular)
{
	float4 result = ComputeSkyboxIBLColor(parameters);
	ComputeApplyIBLProbeColor(parameters, result);

	if(specular)
	{
		ComputeApplyEnvironmentBRDF(
			parameters.shading_model.type,
			parameters.cos_view_normal,
			parameters.roughness,
			parameters.fresnel_reflectance,
			result.xyz
		);
	}

	return result;
}

float4 ComputeReflection(LightingParameters parameters, bool specular)
{
	float ibl_occlusion = ComputeIBLOcclusion(parameters, parameters.cavity);
	if(ibl_occlusion <= 0.00001)
	{
		return float4(0, 0, 0, 1);
	}

	float4 result = ComputeReflectionIBLOnly(parameters, specular);

	result.xyz *= ibl_occlusion;
	ComputeApplyScreenSpaceReflectionColor(parameters, result);
	result.xyz *= parameters.cavity;

	return result;
}

#endif