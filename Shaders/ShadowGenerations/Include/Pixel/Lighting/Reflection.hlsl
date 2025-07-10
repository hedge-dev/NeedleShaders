#ifndef REFLECTION_LIGHTING_INCLUDED
#define REFLECTION_LIGHTING_INCLUDED

#include "IBL.hlsl"
#include "IBLProbe.hlsl"
#include "ScreenSpaceReflections.hlsl"

float4 ComputeReflectionIBLOnly(LightingParameters parameters, bool specular)
{
	float ibl_occlusion;
	float4 ibl_probe = ComputeIBLProbeColor(parameters, ibl_occlusion);
	float4 ibl = ComputeSkyboxIBLColor(parameters, ibl_occlusion);

	float4 result = ibl * saturate(1.0 - ibl_probe.w);
	result.xyz += ibl_probe.xyz;

	if(specular)
	{
		ComputeApplyEnvironmentBRDF(
			parameters.approximate_env_brdf,
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
	float ibl_occlusion = ComputeIBLOcclusion(parameters);
	if(ibl_occlusion <= 0.00001)
	{
		return float4(0, 0, 0, 1);
	}

	float4 result = ComputeReflectionIBLOnly(parameters, specular);

	result.xyz *= ibl_occlusion;
	ComputeApplyScreenSpaceReflectionColor(parameters, result);

	return result;
}

#endif