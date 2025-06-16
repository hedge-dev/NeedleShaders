#ifndef AO_GI_SURFACE_INCLUDED
#define AO_GI_SURFACE_INCLUDED

#include "Common.hlsl"
#include "../Struct.hlsl"

void ApplyAOGI(inout SurfaceParameters parameters)
{
	float gi_ao = 0.0;

	if(IsAOGIEnabled())
	{
		gi_ao = saturate(SampleTextureLevelS(gi_texture, float3(parameters.gi_uv, 0.0), 0).x);
		parameters.ambient_occlusion *= gi_ao;
	}

	if(GetGIMode() == GIMode5)
	{
		parameters.ambient_occlusion = gi_ao;
	}
}

#endif