#ifndef AO_GI_SURFACE_INCLUDED
#define AO_GI_SURFACE_INCLUDED

#include "Common.hlsl"

void ApplyAOGI(inout float ambient_occlusion, float2 gi_uv)
{
	uint gi_mode = GetGIMode();
	float gi_ao = 0.0;

	if(IsAOGIEnabled())
	{
		gi_ao = saturate(SampleTextureLevel(gi_texture, float3(gi_uv, 0.0), 0).x);
		ambient_occlusion *= gi_ao;
	}

	if(gi_mode == GIMode5)
	{
		ambient_occlusion = gi_ao;
	}
}

#endif