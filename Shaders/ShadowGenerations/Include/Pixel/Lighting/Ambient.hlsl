#ifndef AMBIENT_LIGHTING_INCLUDED
#define AMBIENT_LIGHTING_INCLUDED

#include "../../Texture.hlsl"

Texture3D<float4> WithSampler(s_SHLightField0);
Texture3D<float4> WithSampler(s_SHLightField1);
Texture3D<float4> WithSampler(s_SHLightField2);

float3 ComputeAmbientColor(uint shading_mode, uint ao_mode)
{
	if(shading_mode == 0 || ao_mode != 0)
	{
		return 0.0;
	}

	// TODO
	return 0.0;
}

#endif