#ifndef SG_GI_SURFACE_INCLUDED
#define SG_GI_SURFACE_INCLUDED

#include "../../../ConstantBuffer/World.hlsl"
#include "../../../Common.hlsl"

#include "Common.hlsl"

TextureInput(s_EnvBRDF)

void GetSphericalGaussianGI(float2 gi_uv, float3 world_position, out float3 result1, out float3 result2)
{
	uint gi_mode = GetGIMode();

	if(gi_mode == GIMode1 || gi_mode == GIMode3)
	{
		result1 = 0.0;
		result2 = 0.0;
		return;
	}

	// TODO
	result1 = 0.0;
	result2 = 0.0;
}


#endif