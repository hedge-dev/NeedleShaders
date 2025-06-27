#ifndef AMBIENT_LIGHTING_INCLUDED
#define AMBIENT_LIGHTING_INCLUDED

#include "../../Texture.hlsl"
#include "../../Debug.hlsl"

#include "Struct.hlsl"

Texture3D<float4> WithSampler(s_SHLightField0);
Texture3D<float4> WithSampler(s_SHLightField1);
Texture3D<float4> WithSampler(s_SHLightField2);

float3 ComputeAmbientColor(LightingParameters parameters, float lf_ambient_occlusion)
{
	switch(GetDebugMode())
	{
		case DebugMode_43:
			return lf_ambient_occlusion;
		case DebugMode_44:
			return 0.0;
	}

	if(parameters.shader_model == ShaderModel_1 || parameters.occlusion_mode != 0)
	{
		return 0.0;
	}

	// TODO
	return 0.0;
}

float GetAmbientOcclusion(LightingParameters parameters)
{
	if(parameters.shader_model == ShaderModel_1)
	{
		return 0.0;
	}

	int debug_mode = GetDebugMode();
	if(debug_mode == DebugMode_3
		|| debug_mode == DebugMode_19
		|| debug_mode == DebugMode_43
		|| debug_mode == DebugMode_44)
	{
		return 0.0;
	}

	float result = parameters.ambient_occlusion;

	switch(GetDebug2Mode())
	{
		case Debug2Mode_1:
			result = 1.0 - min(1, parameters.occlusion_mode);
			break;
		case Debug2Mode_2:
			result = 1.0;
			break;
		case Debug2Mode_3:
			result = 1.0 - min(1, parameters.occlusion_mode) * saturate(u_sggi_param[0].y * (parameters.roughness - u_sggi_param[0].x));
			break;
	}

	if(parameters.occlusion_mode == 1)
	{
		result = lerp(result, 1.0, parameters.metallic);
	}

	return result;
}


#endif