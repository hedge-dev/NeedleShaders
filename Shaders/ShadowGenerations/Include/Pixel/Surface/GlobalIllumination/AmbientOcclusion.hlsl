#ifndef AO_GI_SURFACE_INCLUDED
#define AO_GI_SURFACE_INCLUDED

#include "Common.hlsl"
#include "../Struct.hlsl"

void ApplyAOGI(inout SurfaceParameters parameters)
{
	float gi_ao = 0.0;

	// So this is not 1:1 accurate with the original shader logic, but the original logic makes no sense.
	// The SGGI check only occurs in the forward rendering permuts, and not in the deferred rendering permuts???
	// I'd rather fix that than try to implement the error lol
	// ~Justin113D

	if(!UsingSGGI() && IsAOGIEnabled())
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